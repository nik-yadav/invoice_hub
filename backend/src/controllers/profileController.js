const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/profile
 * Get authenticated user's business profile
 */
exports.getProfile = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    let profile = null;

    if (userId) {
      profile = await prisma.profile.findFirst({ where: { userId, isActive: true } });
    }

    if (!profile) {
      // Create fresh profile dynamically from user token/data
      profile = await prisma.profile.create({
        data: {
          userId,
          fullName: req.user?.fullName || '',
          companyName: req.user?.companyName || '',
          email: req.user?.email || '',
          phone: '',
          gstin: '',
          address: '',
          transportLicense: '',
          subscriptionPlan: 'Standard Plan',
          isActive: true,
        },
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        full_name: profile.fullName || req.user?.fullName || '',
        company_name: profile.companyName || req.user?.companyName || '',
        email: profile.email || req.user?.email || '',
        phone: profile.phone || '',
        gstin: profile.gstin || '',
        address: profile.address || '',
        transport_license: profile.transportLicense || '',
        subscription_plan: profile.subscriptionPlan || 'Standard Plan',
        enable_post_office_selection: profile.enablePostOfficeSelection || false,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/profile
 * Update authenticated user's business profile
 */
exports.updateProfile = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    let profile = userId ? await prisma.profile.findFirst({ where: { userId, isActive: true } }) : null;

    const {
      full_name,
      company_name,
      email,
      phone,
      gstin,
      address,
      transport_license,
      subscription_plan,
      enable_post_office_selection,
    } = req.body;

    const payload = {
      fullName: full_name,
      companyName: company_name,
      email,
      phone,
      gstin,
      address,
      transportLicense: transport_license,
      subscriptionPlan: subscription_plan,
      enablePostOfficeSelection: enable_post_office_selection,
    };

    Object.keys(payload).forEach((key) => payload[key] === undefined && delete payload[key]);

    if (!profile) {
      profile = await prisma.profile.create({
        data: { userId, isActive: true, ...payload },
      });
    } else {
      profile = await prisma.profile.update({
        where: { id: profile.id },
        data: payload,
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        full_name: profile.fullName,
        company_name: profile.companyName,
        email: profile.email,
        phone: profile.phone,
        gstin: profile.gstin,
        address: profile.address,
        transport_license: profile.transportLicense,
        subscription_plan: profile.subscriptionPlan,
        enable_post_office_selection: profile.enablePostOfficeSelection,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/profile
 * Soft delete authenticated user's business profile
 */
exports.deleteProfile = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const profile = await prisma.profile.findFirst({ where: { userId, isActive: true } });
    if (!profile) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }

    await prisma.profile.update({
      where: { id: profile.id },
      data: { isActive: false },
    });

    return res.status(200).json({ success: true, message: 'Profile deleted successfully' });
  } catch (error) {
    next(error);
  }
};
