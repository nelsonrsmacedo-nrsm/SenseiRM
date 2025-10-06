// backend/src/models/SystemSettings.js
const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const SystemSettings = sequelize.define('SystemSettings', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  companyLogo: {
    type: DataTypes.STRING(500),
    allowNull: true,
    field: 'company_logo'
  },
  companySlogan: {
    type: DataTypes.STRING(500),
    allowNull: true,
    field: 'company_slogan'
  },
  primaryColor: {
    type: DataTypes.STRING(7),
    defaultValue: '#3B82F6',
    field: 'primary_color'
  },
  secondaryColor: {
    type: DataTypes.STRING(7),
    defaultValue: '#1E40AF',
    field: 'secondary_color'
  },
  developerLogo: {
    type: DataTypes.STRING(500),
    allowNull: true,
    field: 'developer_logo'
  },
  developerWebsite: {
    type: DataTypes.STRING(255),
    allowNull: true,
    field: 'developer_website'
  },
  developerEmail: {
    type: DataTypes.STRING(255),
    allowNull: true,
    field: 'developer_email'
  },
  developerPhone: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: 'developer_phone'
  },
  licenseType: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: 'license_type'
  },
  licenseExpiry: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'license_expiry'
  }
}, {
  tableName: 'system_settings'
});

module.exports = SystemSettings;