const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/invoices
 */
exports.getAllInvoices = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const { status, customerId, firmId, search } = req.query;
    const where = userId ? { OR: [{ userId }, { userId: null }] } : {};

    if (status) {
      where.paymentStatus = status.toLowerCase();
    }
    if (customerId) {
      where.customerId = customerId;
    }
    if (firmId) {
      where.firmId = firmId;
    }
    if (search) {
      where.AND = [
        where,
        {
          OR: [
            { invoiceNumber: { contains: search } },
            { sourceCity: { contains: search } },
            { destCity: { contains: search } },
            { materialDescription: { contains: search } },
          ],
        },
      ];
    }

    const invoices = await prisma.invoice.findMany({
      where,
      include: {
        firm: { select: { id: true, businessName: true, gstin: true } },
        customer: { select: { id: true, customerName: true, phone: true } },
        vehicle: { select: { id: true, vehicleNumber: true, type: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const parsedInvoices = invoices.map((i) => ({
      ...i,
      customPartiesFields: typeof i.customPartiesFields === 'string' ? JSON.parse(i.customPartiesFields || '{}') : i.customPartiesFields,
      customChargesFields: typeof i.customChargesFields === 'string' ? JSON.parse(i.customChargesFields || '{}') : i.customChargesFields,
    }));

    return res.status(200).json({ success: true, count: parsedInvoices.length, data: parsedInvoices });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/invoices/:id
 */
exports.getInvoiceById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const invoice = await prisma.invoice.findUnique({
      where: { id },
      include: {
        firm: true,
        customer: true,
        vehicle: true,
      },
    });

    if (!invoice) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    const parsed = {
      ...invoice,
      customPartiesFields: typeof invoice.customPartiesFields === 'string' ? JSON.parse(invoice.customPartiesFields || '{}') : invoice.customPartiesFields,
      customChargesFields: typeof invoice.customChargesFields === 'string' ? JSON.parse(invoice.customChargesFields || '{}') : invoice.customChargesFields,
    };

    return res.status(200).json({ success: true, data: parsed });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/invoices
 */
exports.createInvoice = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const {
      invoiceNumber,
      invoiceDate,
      tripDate,
      firmId,
      customerId,
      vehicleId,
      sourcePin,
      sourceCity,
      sourceDistrict,
      sourceState,
      sourceAddress,
      destinationPin,
      destCity,
      destDistrict,
      destState,
      destAddress,
      materialDescription,
      weight,
      transportationCharge,
      customPartiesFields,
      customChargesFields,
      totalAmount,
      paymentMethod,
      paymentStatus,
      remarks,
    } = req.body;

    const generatedNumber = invoiceNumber || `INV-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const invoice = await prisma.invoice.create({
      data: {
        userId,
        invoiceNumber: generatedNumber,
        invoiceDate: invoiceDate ? new Date(invoiceDate) : new Date(),
        tripDate: tripDate ? new Date(tripDate) : new Date(),
        firmId: firmId || null,
        customerId: customerId || null,
        vehicleId: vehicleId || null,
        sourcePin: sourcePin || '',
        sourceCity: sourceCity || '',
        sourceDistrict: sourceDistrict || '',
        sourceState: sourceState || '',
        sourceAddress: sourceAddress || '',
        destinationPin: destinationPin || '',
        destCity: destCity || '',
        destDistrict: destDistrict || '',
        destState: destState || '',
        destAddress: destAddress || '',
        materialDescription: materialDescription || '',
        weight: Number(weight) || 0.0,
        transportationCharge: Number(transportationCharge) || 0.0,
        customPartiesFields: JSON.stringify(customPartiesFields || {}),
        customChargesFields: JSON.stringify(customChargesFields || {}),
        totalAmount: Number(totalAmount) || Number(transportationCharge) || 0.0,
        paymentMethod: paymentMethod || 'cash',
        paymentStatus: paymentStatus || 'pending',
        remarks: remarks || '',
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Invoice created successfully',
      data: {
        ...invoice,
        customPartiesFields: JSON.parse(invoice.customPartiesFields || '{}'),
        customChargesFields: JSON.parse(invoice.customChargesFields || '{}'),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/invoices/:id
 */
exports.updateInvoice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.invoice.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    const payload = { ...req.body };
    if (payload.customPartiesFields && typeof payload.customPartiesFields === 'object') {
      payload.customPartiesFields = JSON.stringify(payload.customPartiesFields);
    }
    if (payload.customChargesFields && typeof payload.customChargesFields === 'object') {
      payload.customChargesFields = JSON.stringify(payload.customChargesFields);
    }

    const invoice = await prisma.invoice.update({
      where: { id },
      data: payload,
    });

    return res.status(200).json({
      success: true,
      message: 'Invoice updated successfully',
      data: {
        ...invoice,
        customPartiesFields: JSON.parse(invoice.customPartiesFields || '{}'),
        customChargesFields: JSON.parse(invoice.customChargesFields || '{}'),
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/invoices/:id
 */
exports.deleteInvoice = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.invoice.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    await prisma.invoice.delete({ where: { id } });

    return res.status(200).json({ success: true, message: 'Invoice deleted successfully' });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/invoices/:id/summary
 */
exports.getInvoiceSummary = async (req, res, next) => {
  try {
    const { id } = req.params;
    const invoice = await prisma.invoice.findUnique({ where: { id } });

    if (!invoice) {
      return res.status(404).json({ success: false, message: 'Invoice not found' });
    }

    return res.status(200).json({
      success: true,
      summary: {
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        route: `${invoice.sourceCity || 'Origin'} ➔ ${invoice.destCity || 'Destination'}`,
        totalAmount: invoice.totalAmount,
        paymentStatus: invoice.paymentStatus,
        paymentMethod: invoice.paymentMethod,
        date: invoice.invoiceDate,
      },
    });
  } catch (error) {
    next(error);
  }
};
