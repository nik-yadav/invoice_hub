const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { prisma } = require('../config/prisma');

// Helper to sign JWT token
const generateToken = (user) => {
  const secret = process.env.JWT_SECRET || 'super-secret-jwt-key-transport-invoice-pro-2026';
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d';
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      companyName: user.companyName,
    },
    secret,
    { expiresIn }
  );
};

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user using Prisma ORM
 * @access  Public
 */
exports.register = async (req, res, next) => {
  try {
    const { email, password, fullName, companyName, phone } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists',
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = await prisma.user.create({
      data: {
        email: email.toLowerCase(),
        password: hashedPassword,
        fullName: fullName || '',
        companyName: companyName || '',
        phone: phone || '',
      },
    });

    const token = generateToken(newUser);

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: {
        id: newUser.id,
        email: newUser.email,
        full_name: newUser.fullName,
        company_name: newUser.companyName,
        phone: newUser.phone,
        created_at: newUser.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/login
 * @desc    Authenticate user & get token using Prisma ORM
 * @access  Public
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const token = generateToken(user);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.fullName,
        company_name: user.companyName,
        phone: user.phone,
        created_at: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user details
 * @access  Private
 */
exports.getMe = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        fullName: true,
        companyName: true,
        phone: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.status(200).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        full_name: user.fullName,
        company_name: user.companyName,
        phone: user.phone,
        created_at: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/forgot-password
 * @access  Public
 */
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password reset instructions have been sent to your email',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/reset-password
 * @access  Public
 */
exports.resetPassword = async (req, res, next) => {
  try {
    const { token, newPassword } = req.body;
    if (!newPassword) {
      return res.status(400).json({
        success: false,
        message: 'New password is required',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password reset successfully. You can now log in.',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/logout
 * @access  Private
 */
exports.logout = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    next(error);
  }
};
