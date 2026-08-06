const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Firm = sequelize.define('Firm', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  businessName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  ownerName: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  gstin: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  pan: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  city: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  state: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  pin: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  logoPath: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  signaturePath: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  isDefault: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  timestamps: true,
});

module.exports = Firm;
