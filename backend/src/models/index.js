let sequelize = require('../config/database');
const { switchToSqlite } = require('../config/database');
const User = require('./User');
const Profile = require('./Profile');
const Firm = require('./Firm');
const Customer = require('./Customer');
const Vehicle = require('./Vehicle');
const Invoice = require('./Invoice');

// Define Model Associations
User.hasOne(Profile, { foreignKey: 'userId', as: 'profile' });
Profile.belongsTo(User, { foreignKey: 'userId', as: 'user' });

Firm.hasMany(Invoice, { foreignKey: 'firmId', as: 'invoices' });
Invoice.belongsTo(Firm, { foreignKey: 'firmId', as: 'firm' });

Customer.hasMany(Invoice, { foreignKey: 'customerId', as: 'invoices' });
Invoice.belongsTo(Customer, { foreignKey: 'customerId', as: 'customer' });

Vehicle.hasMany(Invoice, { foreignKey: 'vehicleId', as: 'invoices' });
Invoice.belongsTo(Vehicle, { foreignKey: 'vehicleId', as: 'vehicle' });

// Function to sync DB and seed initial sample data
const initDb = async () => {
  try {
    try {
      await sequelize.authenticate();
      console.log('✅ Sequelize DB connection established successfully.');
    } catch (authErr) {
      console.warn(`⚠️ PostgreSQL connection attempt failed (${authErr.message}). Switching to SQLite storage.`);
      sequelize = switchToSqlite();
      await sequelize.authenticate();
      console.log('✅ SQLite database initialized successfully.');
    }

    await sequelize.sync({ alter: true });
    console.log('✅ Database models synchronized.');

    // Seed default firm if empty
    const firmCount = await Firm.count();
    if (firmCount === 0) {
      await Firm.bulkCreate([
        {
          id: '11111111-1111-1111-1111-111111111111',
          businessName: 'Apex Transport & Cargo',
          ownerName: 'Rajesh Sharma',
          phone: '+91 98765 43210',
          email: 'contact@apextransport.com',
          gstin: '27AAAAA0000A1Z5',
          pan: 'ABCDE1234F',
          address: '102 Logistics Park, Nigdi',
          city: 'Pune',
          state: 'Maharashtra',
          pin: '411044',
          isDefault: true,
        },
        {
          id: '22222222-2222-2222-2222-222222222222',
          businessName: 'Speedway Logistics',
          ownerName: 'Vikram Singh',
          phone: '+91 98111 22334',
          email: 'info@speedwaylogistics.com',
          gstin: '27BBBBB1111B2Z6',
          pan: 'FGHIJ5678K',
          address: '45 Transport Nagar',
          city: 'Mumbai',
          state: 'Maharashtra',
          pin: '400001',
          isDefault: false,
        },
      ]);
    }

    // Seed default customer if empty
    const custCount = await Customer.count();
    if (custCount === 0) {
      await Customer.bulkCreate([
        {
          id: '33333333-3333-3333-3333-333333333333',
          customerName: 'Mahindra Logistics Ltd',
          phone: '+91 98220 12345',
          gstin: '27AABCM1234A1Z1',
          address: 'Plot 12, Chakan Industrial Area',
          city: 'Pune',
          state: 'Maharashtra',
          pin: '410501',
        },
        {
          id: '44444444-4444-4444-4444-444444444444',
          customerName: 'Tata Motors Supplies',
          phone: '+91 97654 98765',
          gstin: '27AAACT9999K1Z8',
          address: 'Pimpri Industrial Zone',
          city: 'Pune',
          state: 'Maharashtra',
          pin: '411018',
        },
      ]);
    }

    // Seed default vehicle if empty
    const vehCount = await Vehicle.count();
    if (vehCount === 0) {
      await Vehicle.bulkCreate([
        {
          id: '55555555-5555-5555-5555-555555555555',
          vehicleNumber: 'MH-12-PQ-4567',
          type: 'Open Truck',
          capacity: 14.5,
          driverName: 'Ramesh Kumar',
          driverPhone: '+91 98900 11223',
          insuranceNumber: 'INS-99887766',
          fitnessExpiry: '2027-12-31',
          status: 'available',
        },
        {
          id: '66666666-6666-6666-6666-666666666666',
          vehicleNumber: 'MH-14-AB-9876',
          type: 'Container 32ft',
          capacity: 22.0,
          driverName: 'Suresh Patil',
          driverPhone: '+91 97600 44556',
          insuranceNumber: 'INS-55443322',
          fitnessExpiry: '2026-11-15',
          status: 'busy',
        },
      ]);
    }
  } catch (error) {
    console.error('❌ Unable to sync database:', error.message);
  }
};

module.exports = {
  sequelize,
  User,
  Profile,
  Firm,
  Customer,
  Vehicle,
  Invoice,
  initDb,
};
