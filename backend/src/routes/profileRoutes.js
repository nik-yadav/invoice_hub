import express from 'express';
import * as profileController from '../controllers/profileController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', authMiddleware, profileController.getProfile);
router.put('/', authMiddleware, profileController.updateProfile);
router.delete('/', authMiddleware, profileController.deleteProfile);

export default router;
