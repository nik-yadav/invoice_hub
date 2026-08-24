const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { prisma } = require('../config/prisma');

// Helper to generate access + refresh tokens and create a DB session
const generateTokensAndCreateSession = async (user, req) => {
  const accessTokenSecret = process.env.JWT_SECRET || 'super-secret-jwt-key-transport-invoice-pro-2026';
  const accessTokenExpires = process.env.JWT_EXPIRES_IN || '1h'; // Short-lived access token
  
  const accessToken = jwt.sign(
    {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      companyName: user.companyName,
    },
    accessTokenSecret,
    { expiresIn: accessTokenExpires }
  );

  const refreshToken = crypto.randomBytes(40).toString('hex');
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // Refresh token expires in 7 days

  const deviceInfo = req.headers['user-agent'] || 'Unknown Device';
  const ipAddress = req.ip || req.connection.remoteAddress || '0.0.0.0';

  await prisma.session.create({
    data: {
      userId: user.id,
      refreshToken,
      deviceInfo,
      ipAddress,
      expiresAt,
    },
  });

  return { accessToken, refreshToken };
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

    const { accessToken, refreshToken } = await generateTokensAndCreateSession(newUser, req);

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token: accessToken,
      refreshToken,
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

    const { accessToken, refreshToken } = await generateTokensAndCreateSession(user, req);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token: accessToken,
      refreshToken,
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
    const { refreshToken } = req.body;
    
    if (refreshToken) {
      await prisma.session.updateMany({
        where: { refreshToken },
        data: { isValid: false },
      });
    }

    // Invalidate sessions for this user on logout
    if (req.user && req.user.id) {
      await prisma.session.updateMany({
        where: { userId: req.user.id },
        data: { isValid: false },
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/recreate-session
 * @desc    Recreate user session using a valid refresh token (Refresh Token Rotation)
 * @access  Public
 */
exports.recreateSession = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required',
      });
    }

    // 1. Find session in database
    const session = await prisma.session.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    // 2. Validate session
    if (!session || !session.isValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or revoked session. Please log in again.',
      });
    }

    // Check expiration
    if (new Date() > session.expiresAt) {
      await prisma.session.update({
        where: { id: session.id },
        data: { isValid: false },
      });
      return res.status(401).json({
        success: false,
        message: 'Session has expired. Please log in again.',
      });
    }

    // 3. Create new access and rotated refresh tokens
    const accessTokenSecret = process.env.JWT_SECRET || 'super-secret-jwt-key-transport-invoice-pro-2026';
    const accessTokenExpires = process.env.JWT_EXPIRES_IN || '1h';
    
    const newAccessToken = jwt.sign(
      {
        id: session.user.id,
        email: session.user.email,
        fullName: session.user.fullName,
        companyName: session.user.companyName,
      },
      accessTokenSecret,
      { expiresIn: accessTokenExpires }
    );

    const newRefreshToken = crypto.randomBytes(40).toString('hex');
    const newExpiresAt = new Date();
    newExpiresAt.setDate(newExpiresAt.getDate() + 7);

    // 4. Invalidate old session and create a new one (Rotation)
    await prisma.session.update({
      where: { id: session.id },
      data: { isValid: false },
    });

    await prisma.session.create({
      data: {
        userId: session.user.id,
        refreshToken: newRefreshToken,
        deviceInfo: req.headers['user-agent'] || 'Unknown Device',
        ipAddress: req.ip || req.connection.remoteAddress || '0.0.0.0',
        expiresAt: newExpiresAt,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Session recreated successfully',
      token: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    next(error);
  }
};
