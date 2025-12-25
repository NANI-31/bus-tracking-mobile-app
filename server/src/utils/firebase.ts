// src/utils/firebase.ts
import admin from "firebase-admin";
import path from "path";

// Initialize Firebase Admin SDK
// You need to download service account JSON from Firebase Console
// Project Settings -> Service Accounts -> Generate New Private Key
const serviceAccountPath = path.join(__dirname, "../serviceAccountKey.json");

let firebaseInitialized = false;

export const initializeFirebase = () => {
  if (firebaseInitialized) return;

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccountPath),
    });
    firebaseInitialized = true;
    console.log("Firebase Admin SDK initialized successfully");
  } catch (error) {
    console.error("Firebase Admin SDK initialization error:", error);
  }
};

// Send notification to a single device
export const sendNotificationToDevice = async (
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> => {
  try {
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            badge: 1,
            sound: "default",
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("Notification sent successfully:", response);
    return true;
  } catch (error) {
    console.error("Error sending notification:", error);
    return false;
  }
};

// Send notification to multiple devices
export const sendNotificationToDevices = async (
  fcmTokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: number; failure: number }> => {
  try {
    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(
      `Notifications sent: ${response.successCount} success, ${response.failureCount} failed`
    );

    return {
      success: response.successCount,
      failure: response.failureCount,
    };
  } catch (error) {
    console.error("Error sending multicast notification:", error);
    return { success: 0, failure: fcmTokens.length };
  }
};

// Send notification to a topic (e.g., all users of a college)
export const sendNotificationToTopic = async (
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> => {
  try {
    const message: admin.messaging.Message = {
      topic,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: "high",
      },
    };

    const response = await admin.messaging().send(message);
    console.log("Topic notification sent:", response);
    return true;
  } catch (error) {
    console.error("Error sending topic notification:", error);
    return false;
  }
};

export default admin;
