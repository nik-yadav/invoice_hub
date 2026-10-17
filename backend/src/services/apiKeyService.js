import crypto from 'crypto';

const KEY_PREFIX = 'ih_';

// Keys are 32 random bytes, so a fast SHA-256 hash is enough (no bcrypt needed)
// and lets us look keys up directly by the unique keyHash column.
const generateApiKey = () => KEY_PREFIX + crypto.randomBytes(32).toString('base64url');

const hashApiKey = key => crypto.createHash('sha256').update(key).digest('hex');

export {
  KEY_PREFIX,
  generateApiKey,
  hashApiKey,
};
