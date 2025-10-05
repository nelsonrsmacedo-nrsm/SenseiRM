// backend/src/models/Campaign.js
const { DataTypes } = require('sequelize');
const { sequelize } = require('../../config/database');

const Campaign = sequelize.define('Campaign', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  type: {
    type: DataTypes.ENUM('email', 'whatsapp'),
    allowNull: false
  },
  subject: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('draft', 'scheduled', 'sending', 'sent', 'cancelled'),
    defaultValue: 'draft'
  },
  scheduledAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'scheduled_at'
  },
  sentAt: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'sent_at'
  },
  recipientCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'recipient_count'
  },
  successCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'success_count'
  },
  failCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'fail_count'
  },
  createdBy: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'created_by'
  }
}, {
  tableName: 'campaigns'
});

module.exports = Campaign;