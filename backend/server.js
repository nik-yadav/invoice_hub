import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import morgan from 'morgan';

import { initPrismaDb } from './src/config/prisma.js';
import errorHandler from './src/middleware/errorHandler.js';

// Import routes
import authRoutes from './src/routes/authRoutes.js';
import profileRoutes from './src/routes/profileRoutes.js';
import firmRoutes from './src/routes/firmRoutes.js';
import customerRoutes from './src/routes/customerRoutes.js';
import vehicleRoutes from './src/routes/vehicleRoutes.js';
import invoiceRoutes from './src/routes/invoiceRoutes.js';
import dashboardRoutes from './src/routes/dashboardRoutes.js';
import uploadRoutes from './src/routes/uploadRoutes.js';
import integrationRoutes from './src/routes/integrationRoutes.js';

import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import blocklistService from './src/services/blocklistService.js';

if (process.env.NODE_ENV === 'production' && (!process.env.JWT_SECRET)) {
  console.error('FATAL ERROR: JWT_SECRET must be set to a secure custom value in production.');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '127.0.0.1';

// 1. Enable Helmet security headers
app.use(helmet());

// 2. Strict CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',') 
  : [];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (e.g. mobile apps, curl requests)
    if (!origin) return callback(null, true);
    
    if (process.env.NODE_ENV === 'production') {
      if (allowedOrigins.indexOf(origin) !== -1) {
        return callback(null, true);
      } else {
        return callback(new Error('Not allowed by CORS'));
      }
    }
    return callback(null, true);
  },
  credentials: true
}));

// 3. Configure Rate Limiters
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again after 15 minutes'
  }
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 15, // Limit each IP to 15 authentication attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again after 15 minutes'
  }
});

const resendVerificationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // Limit each IP to 3 verification resend requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many verification email resend requests from this IP. Please try again after 15 minutes.'
  }
});

// Apply rate limiters
app.use('/api/v1/auth/login', authLimiter);
app.use('/api/v1/auth/register', authLimiter);
app.use('/api/v1/auth/forgot-password', authLimiter);
app.use('/api/v1/auth/reset-password', authLimiter);
app.use('/api/v1/auth/resend-verification', resendVerificationLimiter);
app.use('/api/', generalLimiter);

// Body Parsers (Increased limit to 10mb for image/signature uploads)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// HTTP Request Logger
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Health Check Endpoint
const healthCheckHandler = (req, res) => {
  res.status(200).json({
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    service: 'Transport Invoice Pro API (Prisma ORM)',
  });
};

app.get('/health', healthCheckHandler);
app.get('/api/v1/health', healthCheckHandler);

app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Welcome to Transport Invoice Pro API (Prisma ORM)',
    documentation: '/api/v1',
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/profile', profileRoutes);
app.use('/api/v1/firms', firmRoutes);
app.use('/api/v1/customers', customerRoutes);
app.use('/api/v1/vehicles', vehicleRoutes);
app.use('/api/v1/invoices', invoiceRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1/integrations', integrationRoutes);

// 404 Route Handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
  });
});

// Global Error Handler Middleware
app.use(errorHandler);

// Start Server and Initialize Prisma Database
app.listen(PORT, async () => {
  console.log(`===================================================`);
  console.log(`🚀 Transport Invoice Pro Server running on http://${HOST}:${PORT}`);
  console.log(`🌍 API Base URL: http://${HOST}:${PORT}/api/v1`);
  console.log(`💚 Health Check: http://${HOST}:${PORT}/health`);
  console.log(`===================================================`);

  await initPrismaDb();

  // Initialize disposable email blocklist (remote fetch + local cache + weekly update schedule)
  await blocklistService.initBlocklist();
});

export default app;
