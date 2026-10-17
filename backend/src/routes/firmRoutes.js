import express from 'express';
import * as firmController from '../controllers/firmController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', authMiddleware, firmController.getAllFirms);
router.get('/:id', authMiddleware, firmController.getFirmById);
router.post('/', authMiddleware, firmController.createFirm);
router.put('/:id', authMiddleware, firmController.updateFirm);
router.patch('/:id/set-default', authMiddleware, firmController.setDefaultFirm);
router.delete('/:id', authMiddleware, firmController.deleteFirm);

export default router;
