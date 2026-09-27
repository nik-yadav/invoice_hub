const nodemailer = require('nodemailer');

const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '587', 10);
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const SMTP_FROM = process.env.SMTP_FROM || 'no-reply@transportinvoicepro.com';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001/api/v1';

let transporter = null;

// Initialize Nodemailer transporter if config is present
if (SMTP_HOST && SMTP_USER && SMTP_PASS) {
  transporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: SMTP_PORT === 465, // Use SSL/TLS for port 465
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS,
    },
  });
  console.log('✅ Nodemailer SMTP Transporter configured.');
} else {
  console.log('ℹ️ SMTP credentials missing. Mail service running in DEVELOPER LOG mode.');
}

/**
 * Sends a signup verification email.
 * 
 * @param {string} toEmail - Recipient email
 * @param {string} token - Verification token
 * @returns {Promise<boolean>} - True if sent or logged successfully
 */
async function sendVerificationEmail(toEmail, token) {
  const verifyUrl = `${API_BASE_URL}/auth/verify?token=${token}`;
  
  const subject = 'Verify your email address - Transport Invoice Pro 🚚';
  const textContent = `Welcome to Transport Invoice Pro!\n\nPlease verify your email address by clicking the link below:\n\n${verifyUrl}\n\nThis link will expire in 24 hours.\n\nIf you did not create this account, please ignore this email.`;
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
      <h2 style="color: #007bff; text-align: center;">Verify Your Email Address</h2>
      <p>Welcome to <strong>Transport Invoice Pro</strong>!</p>
      <p>Thank you for signing up. Please click the button below to verify your email address and activate your account:</p>
      <div style="text-align: center; margin: 30px 0;">
        <a href="${verifyUrl}" style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">Verify Email Address</a>
      </div>
      <p style="color: #6c757d; font-size: 14px;">If the button above does not work, copy and paste this URL into your browser:</p>
      <p style="font-size: 14px; word-break: break-all;"><a href="${verifyUrl}">${verifyUrl}</a></p>
      <hr style="border: 0; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
      <p style="color: #999; font-size: 12px; text-align: center;">This link will expire in 24 hours.<br>If you did not request this email, please ignore it.</p>
    </div>
  `;

  if (transporter) {
    try {
      await transporter.sendMail({
        from: SMTP_FROM,
        to: toEmail,
        subject: subject,
        text: textContent,
        html: htmlContent,
      });
      console.log(`✉️ Verification email successfully sent to: ${toEmail}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send verification email to: ${toEmail}. Error:`, error.message);
      throw new Error('Verification email could not be sent. Please try again later.');
    }
  } else {
    // Development mode fallback
    console.log('\n=================== DEVELOPMENT EMAIL LOG ===================');
    console.log(`TO:      ${toEmail}`);
    console.log(`SUBJECT: ${subject}`);
    console.log(`LINK:    ${verifyUrl}`);
    console.log('=============================================================\n');
    return true;
  }
}

module.exports = {
  sendVerificationEmail
};
