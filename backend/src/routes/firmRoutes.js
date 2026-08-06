const express = require('express');
const router = express.Router();
const firmController = require('../controllers/firmController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, firmController.getAllFirms);
router.get('/:id', authMiddleware, firmController.getFirmById);
router.post('/', authMiddleware, firmController.createFirm);
router.put('/:id', authMiddleware, firmController.updateFirm);
router.patch('/:id/set-default', authMiddleware, firmController.setDefaultFirm);
router.delete('/:id', authMiddleware, firmController.deleteFirm);

module.exports = router;
