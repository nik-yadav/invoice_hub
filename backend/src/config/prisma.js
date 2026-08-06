const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const initPrismaDb = async () => {
  try {
    await prisma.$connect();
    console.log('✅ Prisma ORM database connection established.');
  } catch (error) {
    console.warn('⚠️ Prisma initialization notice:', error.message);
  }
};

module.exports = {
  prisma,
  initPrismaDb,
};
