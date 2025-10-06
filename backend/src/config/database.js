// backend/src/config/database.js
const { Sequelize } = require('sequelize');
const logger = require('../utils/logger');

const sequelize = new Sequelize(
  process.env.DB_NAME || 'senseirm',
  process.env.DB_USER || 'root',
  process.env.DB_PASS || '',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: (msg) => logger.debug(msg),
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      underscored: true
    }
  }
);

// Testar conexão
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    logger.info('✅ Conexão com o banco de dados estabelecida com sucesso.');
    return true;
  } catch (error) {
    logger.error('❌ Erro ao conectar com o banco de dados:', error);
    return false;
  }
};

module.exports = { sequelize, testConnection };