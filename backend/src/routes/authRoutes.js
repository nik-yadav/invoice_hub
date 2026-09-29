const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/recreate-session', authController.recreateSession);
router.get('/me', authMiddleware, authController.getMe);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/logout', authMiddleware, authController.logout);
router.get('/verify', authController.verifyEmail);
router.post('/resend-verification', authController.resendVerification);
router.delete('/me', authMiddleware, authController.deleteAccount);
router.delete('/account', authMiddleware, authController.deleteAccount);

module.exports = router;
