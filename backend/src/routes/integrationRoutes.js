import express from 'express';
import * as integrationInvoiceController from '../controllers/integrationInvoiceController.js';
import auditLog from '../middleware/auditLog.js';
import { apiKeyAuth, requireScope } from '../middleware/apiKeyAuth.js';
import apiKeyRateLimit from '../middleware/apiKeyRateLimit.js';

// Read-only, API-key authenticated routes for external integrations (MCP server).
// Kept separate from the app's JWT routes so the Flutter app is unaffected.
const router = express.Router();

router.use(auditLog, apiKeyAuth, requireScope('invoices:read'), apiKeyRateLimit);

router.get('/invoices', integrationInvoiceController.listInvoices);
router.get('/invoices/:id', integrationInvoiceController.getInvoice);

export default router;
