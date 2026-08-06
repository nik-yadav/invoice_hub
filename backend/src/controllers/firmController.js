const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/firms
 */
exports.getAllFirms = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const where = userId ? { OR: [{ userId }, { userId: null }] } : {};

    const firms = await prisma.firm.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return res.status(200).json({ success: true, count: firms.length, data: firms });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/firms/:id
 */
exports.getFirmById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const firm = await prisma.firm.findUnique({ where: { id } });

    if (!firm) {
      return res.status(404).json({ success: false, message: 'Firm not found' });
    }

    return res.status(200).json({ success: true, data: firm });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/firms
 */
exports.createFirm = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const {
      businessName,
      business_name,
      ownerName,
      owner_name,
      phone,
      email,
      gstin,
      pan,
      address,
      city,
      state,
      pin,
      logoPath,
      logo_path,
      signaturePath,
      signature_path,
      isDefault,
      is_default,
    } = req.body;

    const bName = businessName || business_name;
    if (!bName) {
      return res.status(400).json({ success: false, message: 'Business name is required' });
    }

    const defaultFlag = Boolean(isDefault !== undefined ? isDefault : is_default);

    if (defaultFlag) {
      await prisma.firm.updateMany({
        where: userId ? { userId } : {},
        data: { isDefault: false },
      });
    }

    const firm = await prisma.firm.create({
      data: {
        userId,
        businessName: bName,
        ownerName: ownerName || owner_name || '',
        phone: phone || '',
        email: email || '',
        gstin: gstin || '',
        pan: pan || '',
        address: address || '',
        city: city || '',
        state: state || '',
        pin: pin || '',
        logoPath: logoPath || logo_path || null,
        signaturePath: signaturePath || signature_path || null,
        isDefault: defaultFlag,
      },
    });

    return res.status(201).json({ success: true, message: 'Firm created successfully', data: firm });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/firms/:id
 */
exports.updateFirm = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.firm.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Firm not found' });
    }

    const firm = await prisma.firm.update({
      where: { id },
      data: req.body,
    });

    return res.status(200).json({ success: true, message: 'Firm updated successfully', data: firm });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/firms/:id/set-default
 */
exports.setDefaultFirm = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;
    const existing = await prisma.firm.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Firm not found' });
    }

    await prisma.firm.updateMany({
      where: userId ? { userId } : {},
      data: { isDefault: false },
    });
    const firm = await prisma.firm.update({
      where: { id },
      data: { isDefault: true },
    });

    return res.status(200).json({
      success: true,
      message: 'Default firm updated successfully',
      data: firm,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/firms/:id
 */
exports.deleteFirm = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.firm.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Firm not found' });
    }

    await prisma.firm.delete({ where: { id } });

    return res.status(200).json({ success: true, message: 'Firm deleted successfully' });
  } catch (error) {
    next(error);
  }
};
