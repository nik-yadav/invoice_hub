const nodemailer = require('nodemailer');
const resendService = require('./resendService');

const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = parseInt(process.env.SMTP_PORT || '587', 10);
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const SMTP_FROM = process.env.SMTP_FROM || 'no-reply@transportinvoicepro.com';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001/api/v1';

let transporter = null;
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
}

// Log active mail service provider
if (resendService.isConfigured()) {
  console.log(`✅ Mail service configured using Resend API.`);
} else if (transporter) {
  console.log('✅ Mail service configured using Nodemailer SMTP Transporter.');
} else {
  console.log('ℹ️ Mail credentials missing. Mail service running in DEVELOPER LOG mode.');
}

/**
 * Sends an email using Resend (priority), Nodemailer SMTP (fallback), or Developer Log (default).
 * 
 * @param {Object} options
 * @param {string|string[]} options.to - Recipient email(s)
 * @param {string} options.subject - Email subject
 * @param {string} options.html - HTML content
 * @param {string} [options.text] - Plain text content
 * @returns {Promise<boolean>}
 */
async function sendEmail({ to, subject, html, text }) {
  const recipients = Array.isArray(to) ? to : [to];

  // 1. Resend Service (Priority)
  if (resendService.isConfigured()) {
    try {
      await resendService.sendEmail({ to, subject, html, text });
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email via Resend to ${recipients.join(', ')}. Error:`, error.message);
      throw new Error(`Email delivery failed: ${error.message}`);
    }
  }

  // 2. Nodemailer SMTP Transporter
  if (transporter) {
    try {
      await transporter.sendMail({
        from: SMTP_FROM,
        to: recipients.join(', '),
        subject,
        text,
        html,
      });
      console.log(`✉️ Email successfully sent via SMTP to: ${recipients.join(', ')}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email via SMTP to ${recipients.join(', ')}. Error:`, error.message);
      throw new Error(`Email delivery failed: ${error.message}`);
    }
  }

  // 3. Fallback: Development Log mode
  console.log('\n=================== DEVELOPMENT EMAIL LOG ===================');
  console.log(`TO:      ${recipients.join(', ')}`);
  console.log(`SUBJECT: ${subject}`);
  if (text) {
    console.log(`BODY:\n${text}`);
  }
  console.log('=============================================================\n');
  return true;
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

  return sendEmail({
    to: toEmail,
    subject,
    html: htmlContent,
    text: textContent,
  });
}

/**
 * Sends a password reset email.
 * 
 * @param {string} toEmail - Recipient email
 * @param {string} resetUrl - Password reset URL
 * @returns {Promise<boolean>}
 */
async function sendPasswordResetEmail(toEmail, resetUrl) {
  const subject = 'Reset your password - Transport Invoice Pro 🔒';
  const textContent = `You requested a password reset for your Transport Invoice Pro account.\n\nPlease click the link below to set a new password:\n\n${resetUrl}\n\nThis link will expire in 1 hour.\n\nIf you did not request this, you can safely ignore this email.`;
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
      <h2 style="color: #007bff; text-align: center;">Reset Your Password</h2>
      <p>Hello,</p>
      <p>We received a request to reset your password for your <strong>Transport Invoice Pro</strong> account. Click the button below to choose a new password:</p>
      <div style="text-align: center; margin: 30px 0;">
        <a href="${resetUrl}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; font-weight: bold; display: inline-block;">Reset Password</a>
      </div>
      <p style="color: #6c757d; font-size: 14px;">If the button above does not work, copy and paste this URL into your browser:</p>
      <p style="font-size: 14px; word-break: break-all;"><a href="${resetUrl}">${resetUrl}</a></p>
      <hr style="border: 0; border-top: 1px solid #e0e0e0; margin: 20px 0;" />
      <p style="color: #999; font-size: 12px; text-align: center;">This link will expire in 1 hour.<br>If you did not request a password reset, please ignore this email.</p>
    </div>
  `;

  return sendEmail({
    to: toEmail,
    subject,
    html: htmlContent,
    text: textContent,
  });
}

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendPasswordResetEmail,
};
