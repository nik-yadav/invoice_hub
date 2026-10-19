import express from 'express';
import * as vehicleController from '../controllers/vehicleController.js';
import authMiddleware from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', authMiddleware, vehicleController.getAllVehicles);
router.get('/:id', authMiddleware, vehicleController.getVehicleById);
router.post('/', authMiddleware, vehicleController.createVehicle);
router.put('/:id', authMiddleware, vehicleController.updateVehicle);
router.patch('/:id/status', authMiddleware, vehicleController.updateVehicleStatus);
router.delete('/:id', authMiddleware, vehicleController.deleteVehicle);

export default router;
