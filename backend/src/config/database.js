const { Sequelize } = require('sequelize');
require('dotenv').config();

const createSequelizeInstance = (useSqliteFallback = false) => {
  const dbUrl = process.env.DB_URL;
  const isPlaceholderHost = dbUrl && (dbUrl.includes('vbprsmfretgcwfjcomux') || dbUrl.includes('password'));

  if (!useSqliteFallback && dbUrl && dbUrl.startsWith('postgres') && !isPlaceholderHost) {
    return new Sequelize(dbUrl, {
      dialect: 'postgres',
      logging: false,
      dialectOptions: {
        ssl: {
          require: true,
          rejectUnauthorized: false,
        },
      },
    });
  }

  // SQLite storage fallback
  return new Sequelize({
    dialect: 'sqlite',
    storage: './database.sqlite',
    logging: false,
  });
};

let sequelize = createSequelizeInstance();

const switchToSqlite = () => {
  sequelize = createSequelizeInstance(true);
  return sequelize;
};

module.exports = sequelize;
module.exports.switchToSqlite = switchToSqlite;
module.exports.createSequelizeInstance = createSequelizeInstance;
