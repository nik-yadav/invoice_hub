import express from 'express';
import * as uploadController from '../controllers/uploadController.js';

const router = express.Router();

router.post('/signature', uploadController.uploadSignature);

export default router;
