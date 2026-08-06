const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Invoice = sequelize.define('Invoice', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  invoiceNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  invoiceDate: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  tripDate: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  firmId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  customerId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  vehicleId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  sourcePin: DataTypes.STRING,
  sourceCity: DataTypes.STRING,
  sourceDistrict: DataTypes.STRING,
  sourceState: DataTypes.STRING,
  sourceAddress: DataTypes.TEXT,
  destinationPin: DataTypes.STRING,
  destCity: DataTypes.STRING,
  destDistrict: DataTypes.STRING,
  destState: DataTypes.STRING,
  destAddress: DataTypes.TEXT,
  materialDescription: DataTypes.TEXT,
  weight: DataTypes.FLOAT,
  transportationCharge: {
    type: DataTypes.FLOAT,
    defaultValue: 0.0,
  },
  customPartiesFields: {
    type: DataTypes.JSON,
    defaultValue: {},
  },
  customChargesFields: {
    type: DataTypes.JSON,
    defaultValue: {},
  },
  totalAmount: {
    type: DataTypes.FLOAT,
    defaultValue: 0.0,
  },
  paymentMethod: {
    type: DataTypes.ENUM('cash', 'upi', 'bank', 'credit'),
    defaultValue: 'cash',
  },
  paymentStatus: {
    type: DataTypes.ENUM('paid', 'pending', 'partial'),
    defaultValue: 'pending',
  },
  remarks: DataTypes.TEXT,
}, {
  timestamps: true,
});

module.exports = Invoice;
