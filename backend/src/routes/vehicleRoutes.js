const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicleController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/', authMiddleware, vehicleController.getAllVehicles);
router.get('/:id', authMiddleware, vehicleController.getVehicleById);
router.post('/', authMiddleware, vehicleController.createVehicle);
router.put('/:id', authMiddleware, vehicleController.updateVehicle);
router.patch('/:id/status', authMiddleware, vehicleController.updateVehicleStatus);
router.delete('/:id', authMiddleware, vehicleController.deleteVehicle);

module.exports = router;
