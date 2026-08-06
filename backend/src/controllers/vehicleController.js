const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/vehicles
 */
exports.getAllVehicles = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const { status } = req.query;
    const where = userId ? { OR: [{ userId }, { userId: null }] } : {};

    if (status) {
      where.status = status.toLowerCase();
    }

    const vehicles = await prisma.vehicle.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    return res.status(200).json({ success: true, count: vehicles.length, data: vehicles });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/vehicles/:id
 */
exports.getVehicleById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const vehicle = await prisma.vehicle.findUnique({ where: { id } });

    if (!vehicle) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    return res.status(200).json({ success: true, data: vehicle });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/vehicles
 */
exports.createVehicle = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const {
      vehicleNumber,
      type,
      capacity,
      driverName,
      driverPhone,
      insuranceNumber,
      fitnessExpiry,
      status,
    } = req.body;

    if (!vehicleNumber) {
      return res.status(400).json({ success: false, message: 'Vehicle number is required' });
    }

    const vehicle = await prisma.vehicle.create({
      data: {
        userId,
        vehicleNumber,
        type: type || 'Open Truck',
        capacity: Number(capacity) || 0.0,
        driverName: driverName || '',
        driverPhone: driverPhone || '',
        insuranceNumber: insuranceNumber || '',
        fitnessExpiry: fitnessExpiry || null,
        status: status || 'available',
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Vehicle created successfully',
      data: vehicle,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/vehicles/:id
 */
exports.updateVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.vehicle.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    const vehicle = await prisma.vehicle.update({
      where: { id },
      data: req.body,
    });

    return res.status(200).json({
      success: true,
      message: 'Vehicle updated successfully',
      data: vehicle,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/v1/vehicles/:id/status
 */
exports.updateVehicleStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ success: false, message: 'Status is required' });
    }

    const existing = await prisma.vehicle.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    const vehicle = await prisma.vehicle.update({
      where: { id },
      data: { status: status.toLowerCase() },
    });

    return res.status(200).json({
      success: true,
      message: 'Vehicle status updated',
      data: vehicle,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/vehicles/:id
 */
exports.deleteVehicle = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.vehicle.findUnique({ where: { id } });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Vehicle not found' });
    }

    await prisma.vehicle.delete({ where: { id } });

    return res.status(200).json({ success: true, message: 'Vehicle deleted successfully' });
  } catch (error) {
    next(error);
  }
};
