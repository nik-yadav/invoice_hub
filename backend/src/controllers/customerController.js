const { prisma } = require('../config/prisma');

/**
 * GET /api/v1/customers
 */
exports.getAllCustomers = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const { search } = req.query;
    const userFilter = userId ? { OR: [{ userId }, { userId: null }] } : {};
    let where = {
      ...userFilter,
      isActive: true,
    };

    if (search) {
      where = {
        AND: [
          where,
          {
            OR: [
              { customerName: { contains: search, mode: 'insensitive' } },
              { phone: { contains: search, mode: 'insensitive' } },
              { city: { contains: search, mode: 'insensitive' } },
            ],
          },
        ],
      };
    }

    const customers = await prisma.customer.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });

    return res.status(200).json({ success: true, count: customers.length, data: customers });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/v1/customers/:id
 */
exports.getCustomerById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const customer = await prisma.customer.findFirst({
      where: { id, isActive: true },
    });

    if (!customer) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    return res.status(200).json({ success: true, data: customer });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/v1/customers
 */
exports.createCustomer = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    const { customerName, customer_name, phone, gstin, address, city, state, pin } = req.body;
    const cName = customerName || customer_name;

    if (!cName) {
      return res.status(400).json({ success: false, message: 'Customer name is required' });
    }

    const customer = await prisma.customer.create({
      data: {
        userId,
        customerName: cName,
        phone: phone || '',
        gstin: gstin || '',
        address: address || '',
        city: city || '',
        state: state || '',
        pin: pin || '',
        isActive: true,
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Customer created successfully',
      data: customer,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/v1/customers/:id
 */
exports.updateCustomer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.customer.findFirst({
      where: { id, isActive: true },
    });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    const customer = await prisma.customer.update({
      where: { id },
      data: req.body,
    });

    return res.status(200).json({
      success: true,
      message: 'Customer updated successfully',
      data: customer,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/v1/customers/:id
 */
exports.deleteCustomer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const existing = await prisma.customer.findFirst({
      where: { id, isActive: true },
    });

    if (!existing) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    await prisma.customer.update({
      where: { id },
      data: { isActive: false },
    });

    return res.status(200).json({ success: true, message: 'Customer deleted successfully' });
  } catch (error) {
    next(error);
  }
};
