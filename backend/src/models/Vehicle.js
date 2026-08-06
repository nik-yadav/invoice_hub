const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Vehicle = sequelize.define('Vehicle', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  vehicleNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  type: {
    type: DataTypes.STRING,
    defaultValue: 'Open Truck',
  },
  capacity: {
    type: DataTypes.FLOAT,
    defaultValue: 0.0,
  },
  driverName: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  driverPhone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  insuranceNumber: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  fitnessExpiry: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('available', 'busy', 'maintenance'),
    defaultValue: 'available',
  },
}, {
  timestamps: true,
});

module.exports = Vehicle;
