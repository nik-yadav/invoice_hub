const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');

router.post('/signature', uploadController.uploadSignature);

module.exports = router;
