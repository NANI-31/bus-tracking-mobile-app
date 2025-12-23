import nodemailer from "nodemailer";
import { google } from "googleapis";
import dotenv from "dotenv";

dotenv.config();

const createTransporter = async () => {
  try {
    const oauth2Client = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.REDIRECT_URI ||
        "https://developers.google.com/oauthplayground"
    );

    oauth2Client.setCredentials({
      refresh_token: process.env.GOOGLE_REFRESH_TOKEN,
    });

    const accessTokenData = await oauth2Client.getAccessToken();
    const accessToken = accessTokenData;

    if (!accessToken) {
      throw new Error("Failed to Retrieve Access Token");
    }

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        type: "OAuth2",
        user: process.env.EMAIL_USER,
        clientId: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        refreshToken: process.env.GOOGLE_REFRESH_TOKEN,
        accessToken: accessToken,
      },
    } as any);

    return transporter;
  } catch (error) {
    console.error("Error creating transporter:", error);
    throw error;
  }
};

export const sendEmail = async (
  email: string,
  subject: string,
  text: string,
  html?: string // Add optional html parameter
) => {
  try {
    const emailTransporter = await createTransporter();
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject,
      text,
      html, // Add html to mail options
    };
    await emailTransporter.sendMail(mailOptions);
    console.log(`Email sent to ${email}`);
  } catch (error) {
    console.log("Email error:", error);
    throw new Error("Email sending failed");
  }
};
