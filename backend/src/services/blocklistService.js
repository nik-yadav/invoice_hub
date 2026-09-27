const fs = require('fs').promises;
const path = require('path');

const CACHE_FILE_PATH = path.join(__dirname, 'disposable_domains_cache.json');
const BLOCKLIST_URL = 'https://raw.githubusercontent.com/disposable-email-domains/disposable-email-domains/master/disposable_email_blocklist.conf';

// Initial fallback set of common disposable email domains
const INITIAL_DISPOSABLE_DOMAINS = [
  'mailinator.com',
  'guerrillamail.com',
  '10minutemail.com',
  'tempmail.com',
  'temp-mail.org',
  'yopmail.com',
  'sharklasers.com',
  'guerrillamailblock.com',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamail.biz',
  'dispostable.com',
  'getairmail.com',
  'throwawaymail.com',
  'maildrop.cc',
  'mailnesia.com',
  'mailcatch.com',
  'burnchecker.com',
  'trbvm.com',
  'duck.com' // often used as email forwarding / mask
];

const disposableDomains = new Set(INITIAL_DISPOSABLE_DOMAINS);
let updateIntervalId = null;

/**
 * Initializes the blocklist by loading from local cache file if exists,
 * otherwise starts with the initial fallback set. Then kicks off an async remote refresh.
 */
async function initBlocklist() {
  try {
    // 1. Try loading cached domains from disk
    const data = await fs.readFile(CACHE_FILE_PATH, 'utf8');
    const cachedDomains = JSON.parse(data);
    if (Array.isArray(cachedDomains)) {
      disposableDomains.clear();
      cachedDomains.forEach(domain => disposableDomains.add(domain.trim().toLowerCase()));
      console.log(`ℹ️ Loaded ${disposableDomains.size} disposable domains from local cache file.`);
    }
  } catch (error) {
    if (error.code !== 'ENOENT') {
      console.error('⚠️ Error reading disposable domains cache file:', error.message);
    }
    // If file doesn't exist, we just rely on INITIAL_DISPOSABLE_DOMAINS which is already in the set
  }

  // 2. Perform async update from remote list
  // Run in background so startup isn't blocked
  refreshBlocklist().catch(err => {
    console.error('⚠️ Initial remote blocklist refresh failed:', err.message);
  });

  // 3. Start weekly scheduler (7 days in milliseconds)
  const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
  if (!updateIntervalId) {
    updateIntervalId = setInterval(() => {
      console.log('⏰ Running weekly disposable email domains blocklist update...');
      refreshBlocklist().catch(err => {
        console.error('⚠️ Scheduled remote blocklist refresh failed:', err.message);
      });
    }, SEVEN_DAYS_MS);
  }
}

/**
 * Fetches the latest blocklist from GitHub and saves it locally.
 */
async function refreshBlocklist() {
  try {
    console.log(`🌐 Fetching latest disposable email domains from: ${BLOCKLIST_URL}`);
    
    const response = await fetch(BLOCKLIST_URL);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const text = await response.text();
    const domains = text
      .split('\n')
      .map(line => line.trim())
      .filter(line => line && !line.startsWith('#') && !line.startsWith('//'));

    if (domains.length > 0) {
      disposableDomains.clear();
      domains.forEach(d => disposableDomains.add(d.toLowerCase()));
      
      // Save updated list to cache file
      await fs.writeFile(CACHE_FILE_PATH, JSON.stringify(Array.from(disposableDomains), null, 2), 'utf8');
      console.log(`✅ Disposable domains blocklist updated successfully. Total domains: ${disposableDomains.size}`);
    }
  } catch (error) {
    console.warn(`⚠️ Failed to update disposable domains list remotely (${error.message}). Using current in-memory list.`);
  }
}

/**
 * Checks if a domain is in the disposable blocklist.
 * 
 * @param {string} domain - Domain name to check (e.g. 'mailinator.com')
 * @returns {boolean} - True if domain is blocklisted.
 */
function isDisposable(domain) {
  if (!domain) return false;
  const normalizedDomain = domain.trim().toLowerCase();
  return disposableDomains.has(normalizedDomain);
}

module.exports = {
  initBlocklist,
  refreshBlocklist,
  isDisposable,
  disposableDomains
};
