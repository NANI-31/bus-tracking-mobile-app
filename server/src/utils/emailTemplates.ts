export const getOtpEmailTemplate = (userName: string, otp: string) => {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your OTP Code</title>
  <style>
    /* Gmail specific reset */
    body {
      margin: 0;
      padding: 0;
      font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      background-color: #f4f6f8;
    }
    .wrapper {
      width: 100%;
      background-color: #f4f6f8;
      padding: 20px 0;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    }
    .header {
      background-color: #1a73e8; /* App Primary Color */
      padding: 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      color: #ffffff;
      font-size: 24px;
      font-weight: 700;
    }
    .content {
      padding: 32px 24px;
      text-align: center;
      color: #333333;
    }
    .greeting {
      font-size: 18px;
      margin-bottom: 16px;
      color: #202124;
    }
    .message {
      font-size: 15px;
      line-height: 1.5;
      color: #5f6368;
      margin-bottom: 24px;
    }
    .otp-box {
      background-color: #e8f0fe;
      border-radius: 8px;
      padding: 16px 32px;
      display: inline-block;
      margin: 0 auto 24px auto;
      border: 1px solid #d2e3fc;
    }
    .otp-code {
      font-size: 32px;
      font-weight: bold;
      color: #1a73e8;
      letter-spacing: 5px;
    }
    .validity {
      font-size: 13px;
      color: #5f6368;
      margin-bottom: 8px;
    }
    .security-note {
      font-size: 13px;
      color: #ea4335;
      font-weight: 500;
      margin-top: 16px;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 20px;
      text-align: center;
      border-top: 1px solid #eeeeee;
    }
    .footer-text {
      font-size: 12px;
      color: #9aa0a6;
      line-height: 1.4;
    }
    .footer-link {
      color: #1a73e8;
      text-decoration: none;
    }
    /* Dark Mode Support (Gmail App) */
    @media (prefers-color-scheme: dark) {
      body, .wrapper { background-color: #202124 !important; }
      .container { background-color: #2d2e31 !important; color: #e8eaed !important; }
      .otp-box { background-color: #303134 !important; border-color: #5f6368 !important; }
      .otp-code { color: #8ab4f8 !important; }
      .greeting, .message { color: #e8eaed !important; }
      .validity { color: #9aa0a6 !important; }
      .footer { background-color: #202124 !important; border-top-color: #3c4043 !important; }
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <!-- Header -->
      <div class="header">
        <h1>Upasthit</h1> <!-- App Name -->
      </div>
      
      <!-- Content -->
      <div class="content">
        <div class="greeting">Hi ${userName},</div>
        <div class="message">
          Use the One Time Password (OTP) below to verify your identity.
        </div>
        
        <div class="otp-box">
          <div class="otp-code">${otp}</div>
        </div>
        
        <div class="validity">
          This code is valid for 10 minutes.
        </div>
        
        <div class="security-note">
          Do not share this code with anyone.
        </div>
      </div>
      
      <!-- Footer -->
      <div class="footer">
        <div class="footer-text">
          If you didn't request this email, please ignore it.<br>
          &copy; ${new Date().getFullYear()} Upasthit. All rights reserved.<br>
          <a href="#" class="footer-link">Support Center</a>
        </div>
      </div>
    </div>
  </div>
</body>
</html>
  `;
};
