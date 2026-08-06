const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Profile = sequelize.define('Profile', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  fullName: {
    type: DataTypes.STRING,
    defaultValue: 'Rajesh Sharma',
  },
  companyName: {
    type: DataTypes.STRING,
    defaultValue: 'Sharma Freight & Logistics',
  },
  email: {
    type: DataTypes.STRING,
    defaultValue: 'rajesh@sharmalogistics.com',
  },
  phone: {
    type: DataTypes.STRING,
    defaultValue: '+91 98765 43210',
  },
  gstin: {
    type: DataTypes.STRING,
    defaultValue: '27AAAAA0000A1Z5',
  },
  address: {
    type: DataTypes.TEXT,
    defaultValue: 'Plot 42, Transport Nagar, Nigdi, Pune, MH - 411044',
  },
  transportLicense: {
    type: DataTypes.STRING,
    defaultValue: 'MH-TR-2024-88910',
  },
  subscriptionPlan: {
    type: DataTypes.STRING,
    defaultValue: 'Enterprise Pro',
  },
}, {
  timestamps: true,
});

module.exports = Profile;
