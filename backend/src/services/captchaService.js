const ENABLE_CAPTCHA = process.env.ENABLE_CAPTCHA === 'true';
const CAPTCHA_SECRET_KEY = process.env.CAPTCHA_SECRET_KEY;
const CAPTCHA_VERIFY_URL = process.env.CAPTCHA_VERIFY_URL || 'https://www.google.com/recaptcha/api/siteverify';

/**
 * Verifies the CAPTCHA token (reCAPTCHA or hCaptcha) with the provider's API.
 * Fails open if the verification API is down or times out.
 * 
 * @param {string} token - The CAPTCHA token from the frontend client
 * @param {string} ipAddress - Client's IP address
 * @returns {Promise<boolean>} - True if verified successfully or service is down (fails open).
 */
async function verifyCaptcha(token, ipAddress) {
  if (!ENABLE_CAPTCHA) {
    return true;
  }
  
  if (!token) {
    console.warn('⚠️ CAPTCHA validation enabled but no token was provided in the request.');
    return false;
  }
  
  if (!CAPTCHA_SECRET_KEY) {
    console.error('❌ CAPTCHA verification enabled but CAPTCHA_SECRET_KEY is missing from environment variables. Failing open.');
    return true;
  }
  
  try {
    const params = new URLSearchParams();
    params.append('secret', CAPTCHA_SECRET_KEY);
    params.append('response', token);
    if (ipAddress) {
      params.append('remoteip', ipAddress);
    }
    
    // Set a timeout of 5 seconds to prevent hanging requests
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), 5000);
    
    const response = await fetch(CAPTCHA_VERIFY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
      signal: controller.signal
    });
    
    clearTimeout(id);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const result = await response.json();
    
    if (result.success) {
      return true;
    } else {
      console.warn('⚠️ CAPTCHA verification failed. Result:', result);
      return false;
    }
  } catch (error) {
    // Fail-open if the captcha verification endpoint is down or times out
    console.error(`❌ CAPTCHA verification service error (${error.message}). Failing open to avoid blocking users.`);
    return true;
  }
}

module.exports = {
  verifyCaptcha
};
