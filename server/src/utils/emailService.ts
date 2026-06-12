import { google } from "googleapis";
import dotenv from "dotenv";

dotenv.config();

const createGmailService = async () => {
  try {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.REDIRECT_URI ||
        "https://developers.google.com/oauthplayground",
    );

    oauth2Client.setCredentials({
      refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
    });

    return google.gmail({ version: "v1", auth: oauth2Client });
  } catch (error) {
    console.error("Error creating Gmail service:", error);
    throw error;
  }
};

export const sendEmail = async (
  email: string,
  subject: string,
  text: string,
  html?: string,
) => {
  try {
    const gmail = await createGmailService();

    // Construct the email body in RFC 2822 format
    const utf8Subject = `=?utf-8?B?${Buffer.from(subject).toString("base64")}?=`;
    const messageParts = [
      `From: "Upasthit App" <${process.env.EMAIL_USER}>`,
      `To: <${email}>`,
      `Reply-To: <${process.env.EMAIL_USER}>`,
      `Message-ID: <${Date.now()}.${Math.random().toString(36).substring(2)}@gmail.com>`,
      `Date: ${new Date().toUTCString()}`,
      `Content-Type: text/html; charset=utf-8`,
      `MIME-Version: 1.0`,
      `Subject: ${utf8Subject}`,
      "",
      html || text,
    ];
    const message = messageParts.join("\n");

    // The Gmail API expects the message to be base64url encoded
    const encodedMessage = Buffer.from(message)
      .toString("base64")
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

    await gmail.users.messages.send({
      userId: "me",
      requestBody: {
        raw: encodedMessage,
      },
    });

    console.log(`Email sent via Gmail API to ${email}`);
  } catch (error) {
    console.error("Gmail API error:", error);
    throw new Error("Email sending failed");
  }
};
