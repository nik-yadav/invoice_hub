import express from 'express';
import * as invoiceController from '../controllers/invoiceController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', authMiddleware, invoiceController.getAllInvoices);
router.get('/:id', authMiddleware, invoiceController.getInvoiceById);
router.get('/:id/summary', authMiddleware, invoiceController.getInvoiceSummary);
router.post('/', authMiddleware, invoiceController.createInvoice);
router.put('/:id', authMiddleware, invoiceController.updateInvoice);
router.delete('/:id', authMiddleware, invoiceController.deleteInvoice);

export default router;
