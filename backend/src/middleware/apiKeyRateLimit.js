import rateLimit from 'express-rate-limit';

// Must run after apiKeyAuth: limits are per API key, not per IP.
const apiKeyRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // Limit each API key to 60 requests per window
  keyGenerator: req => req.apiKey.id,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests for this API key, please try again after a minute',
  },
});

export default apiKeyRateLimit;
export { apiKeyRateLimit };
