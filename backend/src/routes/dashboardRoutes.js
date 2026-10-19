import express from 'express';
import * as dashboardController from '../controllers/dashboardController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/metrics', authMiddleware, dashboardController.getMetrics);
router.get('/recent-invoices', authMiddleware, dashboardController.getRecentInvoices);

export default router;
