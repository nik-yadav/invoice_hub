import express from 'express';
import * as authController from '../controllers/authController.js';
import authMiddleware from '../middleware/authMiddleware.js';
import { optionalAuthMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/recreate-session', authController.recreateSession);
router.get('/me', authMiddleware, authController.getMe);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/logout', optionalAuthMiddleware, authController.logout);
router.get('/verify', authController.verifyEmail);
router.post('/resend-verification', authController.resendVerification);
router.delete('/me', authMiddleware, authController.deleteAccount);
router.delete('/account', authMiddleware, authController.deleteAccount);

export default router;
