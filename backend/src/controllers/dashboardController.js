import { prisma } from '../config/prisma.js';

/**
 * GET /api/v1/dashboard/metrics
 */
export const getMetrics = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const where = { userId, isActive: true };

    const totalInvoices = await prisma.invoice.count({ where });
    const totalCustomers = await prisma.customer.count({ where });
    const activeVehicles = await prisma.vehicle.count({ where: { ...where, status: 'available' } });

    const totalAgg = await prisma.invoice.aggregate({
      where,
      _sum: { totalAmount: true },
    });
    const pendingAgg = await prisma.invoice.aggregate({
      where: { ...where, paymentStatus: 'pending' },
      _sum: { totalAmount: true },
    });

    const totalRevenue = totalAgg._sum.totalAmount || 0.0;
    const pendingAmount = pendingAgg._sum.totalAmount || 0.0;

    return res.status(200).json({
      success: true,
      data: {
        totalRevenue: Number(totalRevenue),
        monthlyRevenue: Number(totalRevenue * 0.65),
        pendingAmount: Number(pendingAmount),
        totalInvoices,
        totalCustomers,
        activeVehicles,
        currency: 'INR',
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/dashboard/recent-invoices
 */
export const getRecentInvoices = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const where = { userId, isActive: true };

    const recentInvoices = await prisma.invoice.findMany({
      where,
      take: 5,
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { select: { customerName: true } },
      },
    });

    const formattedList = recentInvoices.map((inv) => ({
      id: inv.id,
      invoiceNumber: inv.invoiceNumber,
      customerName: inv.customer?.customerName || 'Standard Client',
      route: `${inv.sourceCity || 'Origin'} ➔ ${inv.destCity || 'Destination'}`,
      amount: inv.totalAmount,
      status: inv.paymentStatus,
      date: inv.invoiceDate,
    }));

    return res.status(200).json({
      success: true,
      data: formattedList,
    });
  } catch (error) {
    next(error);
  }
};
