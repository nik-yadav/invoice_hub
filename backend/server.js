const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const { initPrismaDb } = require('./src/config/prisma');
const errorHandler = require('./src/middleware/errorHandler');

// Import routes
const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const firmRoutes = require('./src/routes/firmRoutes');
const customerRoutes = require('./src/routes/customerRoutes');
const vehicleRoutes = require('./src/routes/vehicleRoutes');
const invoiceRoutes = require('./src/routes/invoiceRoutes');
const dashboardRoutes = require('./src/routes/dashboardRoutes');
const uploadRoutes = require('./src/routes/uploadRoutes');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '127.0.0.1';

// Enable CORS
app.use(cors());

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
});

module.exports = app;
