// src/utils/firebase.ts
import admin from "firebase-admin";
// import path from "path";
import logger from "@/utils/logger";

// Initialize Firebase Admin SDK
// You need to download service account JSON from Firebase Console
// Project Settings -> Service Accounts -> Generate New Private Key
// const serviceAccountPath = path.join(__dirname, "../serviceAccountKey.json");

let firebaseInitialized = false;

export const initializeFirebase = () => {
  if (firebaseInitialized) return;

  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: (process.env.FIREBASE_PRIVATE_KEY ?? "").replace(
          /\\n/g,
          "\n",
        ),
      }),
    });
    firebaseInitialized = true;
    logger.info("Firebase Admin SDK initialized successfully");
  } catch (error) {
    logger.error(`Firebase Admin SDK initialization error: ${error}`);
  }
};

// Send notification to a single device
export const sendNotificationToDevice = async (
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>,
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
    console.log(
      `[Firebase] Notification sent successfully to ${fcmToken.substring(
        0,
        10,
      )}...:`,
      response,
    );
    return true;
  } catch (error) {
    console.error(
      `[Firebase] Error sending notification to ${fcmToken.substring(
        0,
        10,
      )}...:`,
      error,
    );
    return false;
  }
};

// Send notification to multiple devices
export const sendNotificationToDevices = async (
  fcmTokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
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
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(
      `Notifications sent: ${response.successCount} success, ${response.failureCount} failed`,
    );

    return {
      success: response.successCount,
      failure: response.failureCount,
    };
  } catch (error) {
    logger.error(`Error sending multicast notification: ${error}`);
    return { success: 0, failure: fcmTokens.length };
  }
};

// Send SOS emergency notification with loud alarm sound
export const sendSosNotification = async (
  fcmTokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>,
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
          channelId: "sos_emergency_channel",
          priority: "max",
          sound: "sos_alarm",
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            badge: 1,
            sound: "sos_alarm.aiff",
            "content-available": 1,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(
      `SOS Notifications sent: ${response.successCount} success, ${response.failureCount} failed`,
    );

    return {
      success: response.successCount,
      failure: response.failureCount,
    };
  } catch (error) {
    logger.error(`Error sending SOS notification: ${error}`);
    return { success: 0, failure: fcmTokens.length };
  }
};

// Send notification to a topic (e.g., all users of a college)
export const sendNotificationToTopic = async (
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>,
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
    logger.info(`Topic notification sent: ${JSON.stringify(response)}`);
    return true;
  } catch (error) {
    logger.error(`Error sending topic notification: ${error}`);
    return false;
  }
};

/**
 * Send a data-only (silent) notification to multiple devices.
 * Used for dismissing local notifications or marking as read across devices.
 */
export const sendDataOnlyNotificationToDevices = async (
  fcmTokens: string[],
  data: Record<string, string>,
): Promise<{ success: number; failure: number }> => {
  try {
    const message: admin.messaging.MulticastMessage = {
      tokens: fcmTokens,
      data: data,
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Silent notifications sent: ${response.successCount} success`);
    return { success: response.successCount, failure: response.failureCount };
  } catch (error) {
    logger.error(`Error sending silent multicast notification: ${error}`);
    return { success: 0, failure: fcmTokens.length };
  }
};

/**
 * Send a data-only (silent) notification to a topic.
 * Used for dismissing voice broadcasts across all students.
 */
export const sendDataOnlyNotificationToTopic = async (
  topic: string,
  data: Record<string, string>,
): Promise<boolean> => {
  try {
    const message: admin.messaging.Message = {
      topic,
      data: data,
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    logger.info(`Silent topic notification sent: ${JSON.stringify(response)}`);
    return true;
  } catch (error) {
    logger.error(`Error sending silent topic notification: ${error}`);
    return false;
  }
};

export default admin;
