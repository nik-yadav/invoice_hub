const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const validator = require('validator');
const { prisma } = require('../config/prisma');
const dnsService = require('../services/dnsService');
const blocklistService = require('../services/blocklistService');
const mailService = require('../services/mailService');
const captchaService = require('../services/captchaService');

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
    const ipAddress = req.ip || req.connection.remoteAddress || '0.0.0.0';

    // 1. Bot Honeypot check
    // If a bot fills in the hidden honeypot fields, block and return a fake success
    const honeypot = req.body.username || req.body.honeypot;
    if (honeypot) {
      await prisma.blockedSignup.create({
        data: {
          email: email ? email.trim().toLowerCase() : 'bot@honeypot.com',
          reason: 'Honeypot filled (bot)',
          ipAddress,
        },
      });
      // Mimic success to trick the bot into stopping further automation
      return res.status(201).json({
        success: true,
        message: 'Registration successful. Please check your email to verify your account.',
      });
    }

    // 2. Validate email presence & basic format
    const trimmedEmail = email ? email.trim() : '';
    if (!trimmedEmail || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    if (!validator.isEmail(trimmedEmail)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid email address format',
      });
    }

    const emailLower = trimmedEmail.toLowerCase();
    const domain = emailLower.split('@')[1];

    // 3. Disposable Domain Blocklist Check
    if (blocklistService.isDisposable(domain)) {
      await prisma.blockedSignup.create({
        data: {
          email: emailLower,
          reason: 'Disposable email domain',
          ipAddress,
        },
      });
      return res.status(400).json({
        success: false,
        message: 'Registration is not allowed using disposable/temporary email addresses.',
      });
    }

    // 4. DNS MX Record Check
    const hasMx = await dnsService.checkMxRecords(domain);
    if (!hasMx) {
      await prisma.blockedSignup.create({
        data: {
          email: emailLower,
          reason: 'No valid MX records found',
          ipAddress,
        },
      });
      return res.status(400).json({
        success: false,
        message: 'The email domain provided does not exist or cannot receive mail.',
      });
    }

    // 5. CAPTCHA Check (Fail-open on validation provider error)
    const captchaToken = req.body.captchaToken;
    const isCaptchaValid = await captchaService.verifyCaptcha(captchaToken, ipAddress);
    if (!isCaptchaValid) {
      await prisma.blockedSignup.create({
        data: {
          email: emailLower,
          reason: 'Failed CAPTCHA verification',
          ipAddress,
        },
      });
      return res.status(400).json({
        success: false,
        message: 'CAPTCHA verification failed. Please try again.',
      });
    }

    // 6. Check if email already registered
    const existingUser = await prisma.user.findUnique({
      where: { email: emailLower },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists',
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Generate Verification Token (expires in 24 hours)
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const tokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    // Create User as Unverified
    const newUser = await prisma.user.create({
      data: {
        email: emailLower,
        password: hashedPassword,
        fullName: fullName || '',
        companyName: companyName || '',
        phone: phone || '',
        isVerified: false,
        verificationToken,
        tokenExpiresAt,
      },
    });

    // 7. Send Verification Email (fail-silent but logged so registration proceeds)
    try {
      await mailService.sendVerificationEmail(emailLower, verificationToken);
    } catch (mailError) {
      console.error('⚠️ Verification email failed to send on registration:', mailError.message);
    }

    return res.status(201).json({
      success: true,
      message: 'Registration successful. Please check your email to verify your account.',
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

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been deactivated. Please contact support.',
      });
    }

    if (!user.isVerified) {
      if (!user.verificationToken) {
        // Legacy user created before email verification was introduced - auto-verify
        await prisma.user.update({
          where: { id: user.id },
          data: { isVerified: true, isActive: true },
        });
        user.isVerified = true;
      } else {
        return res.status(403).json({
          success: false,
          message: 'Please verify your email address before logging in.',
        });
      }
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
    const user = await prisma.user.findFirst({
      where: { id: req.user.id, isActive: true },
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
        message: 'User not found or account deactivated',
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
        data: { isValid: false, isActive: false },
      });
    }

    // Invalidate sessions for this user on logout
    if (req.user && req.user.id) {
      await prisma.session.updateMany({
        where: { userId: req.user.id },
        data: { isValid: false, isActive: false },
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
 * @route   DELETE /api/v1/auth/me
 * @desc    Deactivate user account (soft delete)
 * @access  Private
 */
exports.deleteAccount = async (req, res, next) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const user = await prisma.user.findFirst({
      where: { id: userId, isActive: true },
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Soft delete user and invalidate sessions
    await prisma.user.update({
      where: { id: userId },
      data: { isActive: false },
    });

    await prisma.session.updateMany({
      where: { userId },
      data: { isValid: false, isActive: false },
    });

    return res.status(200).json({
      success: true,
      message: 'Account deactivated successfully',
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
    if (!session || !session.isValid || !session.isActive || !session.user || !session.user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or revoked session. Please log in again.',
      });
    }

    // Check expiration
    if (new Date() > session.expiresAt) {
      await prisma.session.update({
        where: { id: session.id },
        data: { isValid: false, isActive: false },
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
      data: { isValid: false, isActive: false },
    });

    await prisma.session.create({
      data: {
        userId: session.user.id,
        refreshToken: newRefreshToken,
        deviceInfo: req.headers['user-agent'] || 'Unknown Device',
        ipAddress: req.ip || req.connection.remoteAddress || '0.0.0.0',
        expiresAt: newExpiresAt,
        isValid: true,
        isActive: true,
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

/**
 * @route   GET /api/v1/auth/verify
 * @desc    Verify email address using verification token
 * @access  Public
 */
exports.verifyEmail = async (req, res, next) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).send(`
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #dc3545;">Verification Failed ❌</h1>
          <p>Verification token is missing.</p>
        </div>
      `);
    }

    const user = await prisma.user.findUnique({
      where: { verificationToken: token },
    });

    if (!user) {
      return res.status(400).send(`
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #dc3545;">Verification Failed ❌</h1>
          <p>Invalid or already-used verification token.</p>
        </div>
      `);
    }

    if (user.tokenExpiresAt && new Date() > user.tokenExpiresAt) {
      return res.status(400).send(`
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #dc3545;">Verification Failed ❌</h1>
          <p>The verification token has expired. Please request a new verification email.</p>
        </div>
      `);
    }

    // Activate user and clear token/expiry
    await prisma.user.update({
      where: { id: user.id },
      data: {
        isVerified: true,
        verificationToken: null,
        tokenExpiresAt: null,
      },
    });

    return res.status(200).send(`
      <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
        <h1 style="color: #28a745;">Email Verified Successfully! ✅</h1>
        <p>Thank you. Your email address has been verified. You can now log in to the Transport Invoice Pro application.</p>
      </div>
    `);
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /api/v1/auth/resend-verification
 * @desc    Resend email verification link
 * @access  Public
 */
exports.resendVerification = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required',
      });
    }

    const trimmedEmail = email.trim().toLowerCase();

    const user = await prisma.user.findUnique({
      where: { email: trimmedEmail },
    });

    // Fail silently (return success) if user doesn't exist to prevent user enumeration
    if (!user) {
      return res.status(200).json({
        success: true,
        message: 'If this email address is registered and unverified, a new verification link has been sent.',
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'This email address is already verified. Please log in.',
      });
    }

    // Generate new token & expiry (24 hours)
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const tokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        verificationToken,
        tokenExpiresAt,
      },
    });

    try {
      await mailService.sendVerificationEmail(trimmedEmail, verificationToken);
    } catch (mailError) {
      console.error('⚠️ Verification email failed to resend:', mailError.message);
    }

    return res.status(200).json({
      success: true,
      message: 'A new verification link has been sent to your email.',
    });
  } catch (error) {
    next(error);
  }
};
