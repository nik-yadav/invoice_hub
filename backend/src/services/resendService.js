const RESEND_API_KEY = process.env.RESEND_API_KEY;
const RESEND_FROM = process.env.RESEND_FROM || 'Transport Invoice Pro <onboarding@resend.dev>';
const RESEND_API_URL = 'https://api.resend.com/emails';

let resendClient = null;
if (RESEND_API_KEY) {
  try {
    const { Resend } = require('resend');
    resendClient = new Resend(RESEND_API_KEY);
  } catch (_) {
    // If resend npm package is not installed, fallback to native fetch
  }
}

/**
 * Checks whether Resend is configured with a valid API key.
 * @returns {boolean}
 */
function isConfigured() {
  return Boolean(RESEND_API_KEY && RESEND_API_KEY.trim().length > 0);
}

/**
 * Sends an email using the Resend API.
 * Uses the official 'resend' SDK if installed, or Node's native fetch.
 * 
 * @param {Object} options
 * @param {string|string[]} options.to - Recipient email address(es)
 * @param {string} options.subject - Email subject
 * @param {string} options.html - HTML email content
 * @param {string} [options.text] - Optional plain text email content
 * @param {string} [options.from] - Optional sender (defaults to RESEND_FROM)
 * @param {string} [options.replyTo] - Optional reply-to email address
 * @param {Array<Object>} [options.attachments] - Optional attachments [{ filename, content }]
 * @returns {Promise<{ id: string }>}
 */
async function sendEmail({ to, subject, html, text, from = RESEND_FROM, replyTo, attachments }) {
  if (!isConfigured()) {
    throw new Error('Resend is not configured. Please set RESEND_API_KEY in your environment variables.');
  }

  const recipients = Array.isArray(to) ? to : [to];

  // 1. If official SDK is installed
  if (resendClient) {
    const payload = {
      from,
      to: recipients,
      subject,
      html,
    };
    if (text) payload.text = text;
    if (replyTo) payload.reply_to = replyTo;
    if (attachments) payload.attachments = attachments;

    const { data, error } = await resendClient.emails.send(payload);
    if (error) {
      console.error(`❌ Resend SDK send error to [${recipients.join(', ')}]:`, error);
      throw new Error(error.message || 'Resend SDK failed to send email');
    }

    console.log(`✉️ [Resend SDK] Email sent to: ${recipients.join(', ')} (ID: ${data?.id})`);
    return data;
  }

  // 2. Native fetch (Node 18+) with 10s timeout
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);

  try {
    const body = {
      from,
      to: recipients,
      subject,
      html,
    };
    if (text) body.text = text;
    if (replyTo) body.reply_to = replyTo;
    if (attachments) body.attachments = attachments;

    const response = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY.trim()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    const result = await response.json();

    if (!response.ok) {
      const errorMsg = result?.message || `HTTP ${response.status} ${response.statusText}`;
      console.error(`❌ Resend API HTTP error to [${recipients.join(', ')}]:`, errorMsg);
      throw new Error(`Resend API Error: ${errorMsg}`);
    }

    console.log(`✉️ [Resend API] Email sent to: ${recipients.join(', ')} (ID: ${result?.id})`);
    return result;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Resend API request timed out after 10 seconds.');
    }
    throw error;
  }
}
module.exports = {
  isConfigured,
  sendEmail,
};
