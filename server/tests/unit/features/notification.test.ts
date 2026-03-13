import { Request, Response } from "express";
import Notification from "@/models/Notification.model";
import User from "@/models/User.model";
import { sendNotification, getUserNotifications, markNotificationAsRead } from "@/controllers/features/notification.controller";
import { s3Service } from "@/services/s3.service";
import * as firebase from "@/utils/firebase";

// Mock dependencies
jest.mock("@/models/Notification.model");
jest.mock("@/models/User.model");
jest.mock("@/services/s3.service", () => ({
  s3Service: {
    generatePresignedUrl: jest.fn().mockResolvedValue("https://presigned-url.com"),
    deleteFile: jest.fn().mockResolvedValue(true),
  },
}));
jest.mock("@/utils/firebase", () => ({
  sendNotificationToDevice: jest.fn().mockResolvedValue(undefined),
  sendDataOnlyNotificationToDevices: jest.fn().mockResolvedValue(undefined),
  sendDataOnlyNotificationToTopic: jest.fn().mockResolvedValue(undefined),
}));
jest.mock("@/utils/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
}));

describe("Feature Controller - Notification", () => {
  let mockReq: any;
  let mockRes: any;
  let jsonMock: jest.Mock;
  let statusMock: jest.Mock;

  beforeEach(() => {
    jsonMock = jest.fn();
    statusMock = jest.fn().mockReturnValue({ json: jsonMock });
    mockReq = {
      body: {},
      params: {},
      query: {},
      user: { id: "user123", role: "student", collegeId: "college123" },
      app: {
        get: jest.fn().mockReturnValue({
          to: jest.fn().mockReturnValue({ emit: jest.fn() }),
        }),
      },
    };
    mockRes = {
      json: jsonMock,
      status: statusMock,
    };
    jest.clearAllMocks();
  });

  describe("sendNotification", () => {
    it("should create a notification and send FCM", async () => {
      mockReq.body = { receiverId: "receiver123", title: "Test", message: "Hello" };
      const savedNotif = { _id: "notif123", ...mockReq.body };
      
      (Notification as any).mockImplementation(() => ({
        ...mockReq.body,
        save: jest.fn().mockResolvedValue(savedNotif),
      }));
      (User.findById as jest.Mock).mockResolvedValue({ fcmToken: "token123" });

      await sendNotification(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(201);
      expect(firebase.sendNotificationToDevice).toHaveBeenCalled();
    });
  });

  describe("getUserNotifications", () => {
    it("should return notifications with presigned URLs for voice messages", async () => {
      mockReq.params.userId = "user123";
      const rawNotifs = [
        {
          toObject: () => ({
            _id: "notif1",
            type: "VOICE_NOTIFICATION",
            data: { voiceKey: "path/to/audio.mp3" }
          })
        }
      ];
      (Notification.find as jest.Mock).mockReturnValue({
        sort: jest.fn().mockResolvedValue(rawNotifs),
      });

      await getUserNotifications(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(jsonMock).toHaveBeenCalledWith(expect.arrayContaining([expect.objectContaining({ audioUrl: "https://presigned-url.com" })]));
    });
  });

  describe("markNotificationAsRead", () => {
    it("should update notification and emit sync event", async () => {
      mockReq.params.id = "notif123";
      const updatedNotif = { _id: "notif123", isRead: true, receiverId: "user123" };
      (Notification.findByIdAndUpdate as jest.Mock).mockResolvedValue(updatedNotif);
      (User.findById as jest.Mock).mockResolvedValue({ fcmToken: "token123" });

      await markNotificationAsRead(mockReq, mockRes);

      expect(statusMock).toHaveBeenCalledWith(200);
      expect(firebase.sendDataOnlyNotificationToDevices).toHaveBeenCalledWith(["token123"], expect.objectContaining({ action: "dismiss" }));
    });
  });
});
