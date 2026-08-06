const express = require('express');
const router = express.Router();
const invoiceController = require('../controllers/invoiceController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, invoiceController.getAllInvoices);
router.get('/:id', authMiddleware, invoiceController.getInvoiceById);
router.get('/:id/summary', authMiddleware, invoiceController.getInvoiceSummary);
router.post('/', authMiddleware, invoiceController.createInvoice);
router.put('/:id', authMiddleware, invoiceController.updateInvoice);
router.delete('/:id', authMiddleware, invoiceController.deleteInvoice);

module.exports = router;
