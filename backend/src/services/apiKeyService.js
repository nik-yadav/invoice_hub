import crypto from 'crypto';

const KEY_PREFIX = process.env.KEY_PREFIX;

const generateApiKey = () => KEY_PREFIX + crypto.randomBytes(32).toString('base64url');

const hashApiKey = key => crypto.createHash('sha256').update(key).digest('hex');

export {
  KEY_PREFIX,
  generateApiKey,
  hashApiKey,
};
