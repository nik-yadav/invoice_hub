const dns = require('dns').promises;

// Pre-cached popular public email domains to avoid unnecessary DNS calls
const POPULAR_DOMAINS = new Set([
  'gmail.com',
  'yahoo.com',
  'hotmail.com',
  'outlook.com',
  'live.com',
  'icloud.com',
  'aol.com',
  'zoho.com',
  'proton.me',
  'protonmail.com',
  'mail.com',
  'gmx.com',
  'yandex.com'
]);

// In-memory cache for MX query results
// Format: Key = domain, Value = { hasMx: boolean, expiresAt: number }
const mxCache = new Map();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Checks if a domain has valid MX records.
 * Falls back to true (fail-open) on temporary system/network DNS errors.
 * 
 * @param {string} domain - Domain name to check (e.g. 'gmail.com')
 * @returns {Promise<boolean>} - True if domain is valid or check fails open, False if domain explicitly lacks MX records.
 */
async function checkMxRecords(domain) {
  if (!domain) return false;
  
  const normalizedDomain = domain.trim().toLowerCase();
  
  // 1. Skip lookup for popular, known-good domains
  if (POPULAR_DOMAINS.has(normalizedDomain)) {
    return true;
  }
  
  // 2. Check in-memory cache
  const cached = mxCache.get(normalizedDomain);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.hasMx;
  }
  
  try {
    const addresses = await dns.resolveMx(normalizedDomain);
    
    const hasMx = Array.isArray(addresses) && addresses.length > 0;
    
    // Cache result
    mxCache.set(normalizedDomain, {
      hasMx,
      expiresAt: Date.now() + CACHE_TTL_MS
    });
    
    return hasMx;
  } catch (error) {
    // DNS error codes:
    // ENOTFOUND - Domain not found (invalid domain)
    // ENODATA - Domain exists but has no MX records
    if (error.code === 'ENOTFOUND' || error.code === 'ENODATA') {
      mxCache.set(normalizedDomain, {
        hasMx: false,
        expiresAt: Date.now() + CACHE_TTL_MS
      });
      return false;
    }
    
    // Fail-open on temporary DNS server errors (e.g. SERVFAIL, ETIMEOUT, EREFUSED)
    console.warn(`DNS MX lookup error for domain "${normalizedDomain}" (Code: ${error.code || error.message}). Fails open.`);
    return true;
  }
}

module.exports = {
  checkMxRecords,
  mxCache
};
