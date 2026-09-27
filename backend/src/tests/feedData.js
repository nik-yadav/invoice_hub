const { prisma } = require('../config/prisma');
const feedJsonData = require('./feedData.json');

async function run() {
  console.log('🌱 Starting database feed...');

  try {
    // 1. Users (Parent)
    for (const u of feedJsonData.users) {
      await prisma.user.upsert({
        where: { id: u.id },
        update: {},
        create: {
          ...u,
          createdAt: u.createdAt ? new Date(u.createdAt) : undefined,
          updatedAt: u.updatedAt ? new Date(u.updatedAt) : undefined,
          tokenExpiresAt: u.tokenExpiresAt ? new Date(u.tokenExpiresAt) : null,
        }
      });
    }

    // 2. Profiles, Sessions, Firms, Customers, Vehicles (Depend on User)
    for (const p of feedJsonData.profiles) {
      await prisma.profile.upsert({
        where: { id: p.id },
        update: {},
        create: {
          ...p,
          createdAt: p.createdAt ? new Date(p.createdAt) : undefined,
          updatedAt: p.updatedAt ? new Date(p.updatedAt) : undefined,
        }
      });
    }

    for (const f of feedJsonData.firms) {
      await prisma.firm.upsert({
        where: { id: f.id },
        update: {},
        create: {
          ...f,
          createdAt: f.createdAt ? new Date(f.createdAt) : undefined,
          updatedAt: f.updatedAt ? new Date(f.updatedAt) : undefined,
        }
      });
    }

    for (const c of feedJsonData.customers) {
      await prisma.customer.upsert({
        where: { id: c.id },
        update: {},
        create: {
          ...c,
          createdAt: c.createdAt ? new Date(c.createdAt) : undefined,
          updatedAt: c.updatedAt ? new Date(c.updatedAt) : undefined,
        }
      });
    }

    for (const v of feedJsonData.vehicles) {
      await prisma.vehicle.upsert({
        where: { id: v.id },
        update: {},
        create: {
          ...v,
          createdAt: v.createdAt ? new Date(v.createdAt) : undefined,
          updatedAt: v.updatedAt ? new Date(v.updatedAt) : undefined,
        }
      });
    }

    // 3. Invoices (Depend on User, Firm, Customer, Vehicle)
    for (const inv of feedJsonData.invoices) {
      await prisma.invoice.upsert({
        where: { id: inv.id },
        update: {},
        create: {
          ...inv,
          invoiceDate: inv.invoiceDate ? new Date(inv.invoiceDate) : undefined,
          tripDate: inv.tripDate ? new Date(inv.tripDate) : undefined,
          createdAt: inv.createdAt ? new Date(inv.createdAt) : undefined,
          updatedAt: inv.updatedAt ? new Date(inv.updatedAt) : undefined,
        }
      });
    }

    // 4. Blocked Signups
    for (const b of feedJsonData.blockedSignups) {
      await prisma.blockedSignup.upsert({
        where: { id: b.id },
        update: {},
        create: {
          ...b,
          createdAt: b.createdAt ? new Date(b.createdAt) : undefined,
        }
      });
    }

    console.log('✅ All feed data successfully inserted with existing IDs intact!');
  } catch (error) {
    console.error('❌ Error feeding data:', error);
  }
}

module.exports = run;
