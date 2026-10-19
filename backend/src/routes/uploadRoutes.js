import express from 'express';
import * as uploadController from '../controllers/uploadController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/signature', authMiddleware, uploadController.uploadSignature);

export default router;
