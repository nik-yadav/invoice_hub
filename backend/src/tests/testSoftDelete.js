const { prisma } = require('../config/prisma');
const firmController = require('../controllers/firmController');
const customerController = require('../controllers/customerController');
const vehicleController = require('../controllers/vehicleController');
const invoiceController = require('../controllers/invoiceController');
const authController = require('../controllers/authController');

// Mock response object helper
const mockResponse = () => {
  const res = {};
  res.status = code => {
    res.statusCode = code;
    return res;
  };
  res.json = data => {
    res.jsonData = data;
    return res;
  };
  return res;
};

const mockNext = err => {
  if (err) console.error('Next middleware called with error:', err);
};

async function runSoftDeleteTests() {
  console.log('🧪 Starting Soft-Delete and Legacy Verification Test Suite...\n');
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

  // 1. Test Firm Soft Delete
  console.log('--- Testing Firm Soft Delete ---');
  let firmUpdatedWith = null;
  const originalFirmFindFirst = prisma.firm.findFirst;
  const originalFirmUpdate = prisma.firm.update;

  prisma.firm.findFirst = async ({ where }) => {
    if (where.id === 'firm-123' && where.isActive === true) {
      return { id: 'firm-123', businessName: 'Test Firm', isActive: true };
    }
    return null;
  };
  prisma.firm.update = async ({ where, data }) => {
    firmUpdatedWith = { where, data };
    return { id: where.id, ...data };
  };

  const reqFirmDelete = { params: { id: 'firm-123' } };
  const resFirmDelete = mockResponse();
  await firmController.deleteFirm(reqFirmDelete, resFirmDelete, mockNext);

  assert(resFirmDelete.statusCode === 200, 'Delete firm returns 200 OK');
  assert(firmUpdatedWith && firmUpdatedWith.data.isActive === false, 'Firm soft delete sets isActive: false');

  // Test already soft-deleted firm returns 404
  const reqFirmDeleteAgain = { params: { id: 'firm-nonexistent' } };
  const resFirmDeleteAgain = mockResponse();
  await firmController.deleteFirm(reqFirmDeleteAgain, resFirmDeleteAgain, mockNext);
  assert(resFirmDeleteAgain.statusCode === 404, 'Soft-deleted / nonexistent firm delete returns 404');

  // 2. Test Customer Soft Delete
  console.log('\n--- Testing Customer Soft Delete ---');
  let customerUpdatedWith = null;
  const originalCustomerFindFirst = prisma.customer.findFirst;
  const originalCustomerUpdate = prisma.customer.update;

  prisma.customer.findFirst = async ({ where }) => {
    if (where.id === 'cust-123' && where.isActive === true) {
      return { id: 'cust-123', customerName: 'Test Customer', isActive: true };
    }
    return null;
  };
  prisma.customer.update = async ({ where, data }) => {
    customerUpdatedWith = { where, data };
    return { id: where.id, ...data };
  };

  const reqCustDelete = { params: { id: 'cust-123' } };
  const resCustDelete = mockResponse();
  await customerController.deleteCustomer(reqCustDelete, resCustDelete, mockNext);

  assert(resCustDelete.statusCode === 200, 'Delete customer returns 200 OK');
  assert(customerUpdatedWith && customerUpdatedWith.data.isActive === false, 'Customer soft delete sets isActive: false');

  // 3. Test Vehicle Soft Delete
  console.log('\n--- Testing Vehicle Soft Delete ---');
  let vehicleUpdatedWith = null;
  const originalVehicleFindFirst = prisma.vehicle.findFirst;
  const originalVehicleUpdate = prisma.vehicle.update;

  prisma.vehicle.findFirst = async ({ where }) => {
    if (where.id === 'veh-123' && where.isActive === true) {
      return { id: 'veh-123', vehicleNumber: 'MH12AB1234', isActive: true };
    }
    return null;
  };
  prisma.vehicle.update = async ({ where, data }) => {
    vehicleUpdatedWith = { where, data };
    return { id: where.id, ...data };
  };

  const reqVehDelete = { params: { id: 'veh-123' } };
  const resVehDelete = mockResponse();
  await vehicleController.deleteVehicle(reqVehDelete, resVehDelete, mockNext);

  assert(resVehDelete.statusCode === 200, 'Delete vehicle returns 200 OK');
  assert(vehicleUpdatedWith && vehicleUpdatedWith.data.isActive === false, 'Vehicle soft delete sets isActive: false');

  // 4. Test Invoice Soft Delete
  console.log('\n--- Testing Invoice Soft Delete ---');
  let invoiceUpdatedWith = null;
  const originalInvoiceFindFirst = prisma.invoice.findFirst;
  const originalInvoiceUpdate = prisma.invoice.update;

  prisma.invoice.findFirst = async ({ where }) => {
    if (where.id === 'inv-123' && where.isActive === true) {
      return { id: 'inv-123', invoiceNumber: 'INV-001', isActive: true };
    }
    return null;
  };
  prisma.invoice.update = async ({ where, data }) => {
    invoiceUpdatedWith = { where, data };
    return { id: where.id, ...data };
  };

  const reqInvDelete = { params: { id: 'inv-123' } };
  const resInvDelete = mockResponse();
  await invoiceController.deleteInvoice(reqInvDelete, resInvDelete, mockNext);

  assert(resInvDelete.statusCode === 200, 'Delete invoice returns 200 OK');
  assert(invoiceUpdatedWith && invoiceUpdatedWith.data.isActive === false, 'Invoice soft delete sets isActive: false');

  // 5. Test Inactive User Login Block
  console.log('\n--- Testing Inactive User Login Block ---');
  const originalUserFindUnique = prisma.user.findUnique;
  prisma.user.findUnique = async () => {
    return {
      id: 'inactive-user-id',
      email: 'inactive@example.com',
      password: 'password',
      isVerified: true,
      isActive: false,
    };
  };

  const reqInactiveLogin = {
    body: { email: 'inactive@example.com', password: 'password' },
    ip: '127.0.0.1',
  };
  const resInactiveLogin = mockResponse();
  await authController.login(reqInactiveLogin, resInactiveLogin, mockNext);

  assert(resInactiveLogin.statusCode === 403, 'Inactive user login returns 403 Forbidden');
  assert(resInactiveLogin.jsonData.message.includes('deactivated'), 'Inactive user login informs account is deactivated');

  // 6. Test Legacy User Auto-Verification on Login
  console.log('\n--- Testing Legacy User Auto-Verification on Login ---');
  let legacyUserVerified = false;
  const originalUserUpdate = prisma.user.update;
  const bcrypt = require('bcryptjs');
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash('password123', salt);

  prisma.user.findUnique = async () => {
    return {
      id: 'legacy-user-id',
      email: 'legacy@example.com',
      password: hashedPassword,
      isVerified: false,
      verificationToken: null, // Legacy user from before verification
      isActive: true,
    };
  };
  prisma.user.update = async ({ where, data }) => {
    if (where.id === 'legacy-user-id' && data.isVerified === true) {
      legacyUserVerified = true;
    }
    return { id: where.id, ...data };
  };
  prisma.session.create = async () => ({ id: 'session-123' });

  const reqLegacyLogin = {
    body: { email: 'legacy@example.com', password: 'password123' },
    headers: { 'user-agent': 'test-agent' },
    ip: '127.0.0.1',
  };
  const resLegacyLogin = mockResponse();
  await authController.login(reqLegacyLogin, resLegacyLogin, mockNext);

  assert(legacyUserVerified === true, 'Legacy user without verification token was auto-verified');
  assert(resLegacyLogin.statusCode === 200, 'Legacy user login succeeded with 200 OK');

  // Clean up mocks
  prisma.firm.findFirst = originalFirmFindFirst;
  prisma.firm.update = originalFirmUpdate;
  prisma.customer.findFirst = originalCustomerFindFirst;
  prisma.customer.update = originalCustomerUpdate;
  prisma.vehicle.findFirst = originalVehicleFindFirst;
  prisma.vehicle.update = originalVehicleUpdate;
  prisma.invoice.findFirst = originalInvoiceFindFirst;
  prisma.invoice.update = originalInvoiceUpdate;
  prisma.user.findUnique = originalUserFindUnique;
  prisma.user.update = originalUserUpdate;

  console.log('\n==========================================');
  console.log(`🏁 TEST RESULTS: ${passedCount} passed, ${failedCount} failed.`);
  console.log('==========================================');

  if (failedCount > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runSoftDeleteTests().catch(err => {
    console.error('Test runner failure:', err);
    process.exit(1);
  });
}

module.exports = { runSoftDeleteTests };
