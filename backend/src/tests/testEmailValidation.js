const dnsService = require('../services/dnsService');
const blocklistService = require('../services/blocklistService');
const captchaService = require('../services/captchaService');
const authController = require('../controllers/authController');
const { prisma } = require('../config/prisma');

// Mock response object helper
const mockResponse = () => {
  const res = {};
  res.status = jestStatus => {
    res.statusCode = jestStatus;
    return res;
  };
  res.json = data => {
    res.jsonData = data;
    return res;
  };
  res.send = html => {
    res.htmlData = html;
    return res;
  };
  return res;
};

// Mock next middleware
const mockNext = err => {
  if (err) console.error('Next middleware called with error:', err);
};

async function runTests() {
  console.log('🧪 Starting Signup Validation & Bot Prevention Test Suite...\n');
  let passedCount = 0;
  let failedCount = 0;

  const assert = (condition, message) => {
    if (condition) {
      console.log(`✅ PASS: ${message}`);
      passedCount++;
    } else {
      console.error(`❌ FAIL: ${message}`);
      failedCount++;
    }
  };

  // ==========================================
  // Test 1: Blocklist Service
  // ==========================================
  console.log('--- Testing blocklistService ---');
  // Check static list matches
  assert(blocklistService.isDisposable('mailinator.com') === true, 'mailinator.com identified as disposable');
  assert(blocklistService.isDisposable('10minutemail.com') === true, '10minutemail.com identified as disposable');
  assert(blocklistService.isDisposable('gmail.com') === false, 'gmail.com NOT identified as disposable');
  assert(blocklistService.isDisposable('my-company.co.in') === false, 'custom corporate domain NOT identified as disposable');

  // ==========================================
  // Test 2: DNS MX Record Lookup Service
  // ==========================================
  console.log('\n--- Testing dnsService (MX Lookups) ---');
  // Popular domains bypass lookup
  const isGmailOk = await dnsService.checkMxRecords('gmail.com');
  assert(isGmailOk === true, 'gmail.com checks out immediately (bypass/popular domain)');

  // In-memory cache hit test
  dnsService.mxCache.set('testcache-exist.com', { hasMx: true, expiresAt: Date.now() + 10000 });
  const isCachedOk = await dnsService.checkMxRecords('testcache-exist.com');
  assert(isCachedOk === true, 'testcache-exist.com resolves to true from cache');

  dnsService.mxCache.set('testcache-missing.com', { hasMx: false, expiresAt: Date.now() + 10000 });
  const isCachedFail = await dnsService.checkMxRecords('testcache-missing.com');
  assert(isCachedFail === false, 'testcache-missing.com resolves to false from cache');

  // ==========================================
  // Test 3: Bot Honeypot Check (Controller Integration)
  // ==========================================
  console.log('\n--- Testing Bot Honeypot Registration ---');
  
  // We'll mock the Prisma blockedSignup.create to prevent DB write during test if DB isn't running
  const originalBlockedSignupCreate = prisma.blockedSignup.create;
  let blockedSignupCalled = false;
  let blockedSignupReason = '';
  prisma.blockedSignup.create = async ({ data }) => {
    blockedSignupCalled = true;
    blockedSignupReason = data.reason;
    return { id: 'mock-id' };
  };

  const reqHoneypot = {
    body: {
      email: 'spambot@gmail.com',
      password: 'somepassword123',
      username: 'iamabot', // Honeypot field filled
    },
    ip: '127.0.0.1',
  };
  const resHoneypot = mockResponse();

  await authController.register(reqHoneypot, resHoneypot, mockNext);

  assert(resHoneypot.statusCode === 201, 'Honeypot register request returns 201 status code (to fool bots)');
  assert(resHoneypot.jsonData.success === true, 'Honeypot register request returns success true (to fool bots)');
  assert(blockedSignupCalled === true, 'BlockedSignup log was created for honeypot check');
  assert(blockedSignupReason === 'Honeypot filled (bot)', 'BlockedSignup log reason is "Honeypot filled (bot)"');

  // ==========================================
  // Test 4: Malformed Email Address Check
  // ==========================================
  console.log('\n--- Testing Malformed Email Input ---');
  
  const reqMalformed = {
    body: {
      email: 'not-an-email-address',
      password: 'password123',
    },
    ip: '127.0.0.1',
  };
  const resMalformed = mockResponse();

  await authController.register(reqMalformed, resMalformed, mockNext);

  assert(resMalformed.statusCode === 400, 'Malformed email returns 400 Bad Request');
  assert(resMalformed.jsonData.success === false, 'Malformed email returns success false');
  assert(resMalformed.jsonData.message.includes('valid email address format'), 'Returns correct format validation error message');

  // ==========================================
  // Test 5: Disposable Domain Rejection
  // ==========================================
  console.log('\n--- Testing Disposable Email Domain Rejection ---');
  
  blockedSignupCalled = false;
  blockedSignupReason = '';
  
  const reqDisposable = {
    body: {
      email: 'user123@guerrillamail.com',
      password: 'password123',
    },
    ip: '127.0.0.1',
  };
  const resDisposable = mockResponse();

  await authController.register(reqDisposable, resDisposable, mockNext);

  assert(resDisposable.statusCode === 400, 'Disposable email returns 400 Bad Request');
  assert(resDisposable.jsonData.success === false, 'Disposable email returns success false');
  assert(resDisposable.jsonData.message.includes('disposable/temporary'), 'Returns disposable domain error message');
  assert(blockedSignupCalled === true, 'BlockedSignup log was created for disposable email check');
  assert(blockedSignupReason === 'Disposable email domain', 'BlockedSignup log reason is "Disposable email domain"');

  // ==========================================
  // Test 6: Nonexistent Domain MX Check Rejection
  // ==========================================
  console.log('\n--- Testing Nonexistent Domain Rejection ---');
  
  blockedSignupCalled = false;
  blockedSignupReason = '';
  
  // Mock DNS resolve to return no MX records
  const originalCheckMxRecords = dnsService.checkMxRecords;
  dnsService.checkMxRecords = async () => false;

  const reqNonexistent = {
    body: {
      email: 'user123@thisdomaindoesnotexistatall.org',
      password: 'password123',
    },
    ip: '127.0.0.1',
  };
  const resNonexistent = mockResponse();

  await authController.register(reqNonexistent, resNonexistent, mockNext);

  assert(resNonexistent.statusCode === 400, 'Nonexistent domain returns 400 Bad Request');
  assert(resNonexistent.jsonData.success === false, 'Nonexistent domain returns success false');
  assert(resNonexistent.jsonData.message.includes('domain provided does not exist'), 'Returns MX record error message');
  assert(blockedSignupCalled === true, 'BlockedSignup log was created for MX check');
  assert(blockedSignupReason === 'No valid MX records found', 'BlockedSignup log reason is "No valid MX records found"');

  // Restore MX records method
  dnsService.checkMxRecords = originalCheckMxRecords;

  // ==========================================
  // Test 7: Unverified Login Block
  // ==========================================
  console.log('\n--- Testing Login Block for Unverified Users ---');

  const originalUserFindUnique = prisma.user.findUnique;
  prisma.user.findUnique = async () => {
    return {
      id: 'mock-user-id',
      email: 'unverified@gmail.com',
      password: 'hashed-password',
      isVerified: false,
      verificationToken: 'some-token',
      isActive: true,
    };
  };

  const reqLogin = {
    body: {
      email: 'unverified@gmail.com',
      password: 'password123',
    },
    ip: '127.0.0.1',
  };
  const resLogin = mockResponse();

  await authController.login(reqLogin, resLogin, mockNext);

  assert(resLogin.statusCode === 403, 'Unverified user login returns 403 Forbidden');
  assert(resLogin.jsonData.success === false, 'Unverified user login returns success false');
  assert(resLogin.jsonData.message.includes('verify your email address'), 'Returns email verification warning');

  // Restore prisma mock
  prisma.user.findUnique = originalUserFindUnique;
  prisma.blockedSignup.create = originalBlockedSignupCreate;

  console.log('\n==========================================');
  console.log(`🏁 TEST RESULTS: ${passedCount} passed, ${failedCount} failed.`);
  console.log('==========================================');
  
  if (failedCount > 0) {
    process.exit(1);
  }
}

// Check if run directly
if (require.main === module) {
  // Mock checkMxRecords and fetch if they need network bypass for local offline tests
  runTests().catch(err => {
    console.error('Fatal test runner error:', err);
    process.exit(1);
  });
}

module.exports = { runTests };
