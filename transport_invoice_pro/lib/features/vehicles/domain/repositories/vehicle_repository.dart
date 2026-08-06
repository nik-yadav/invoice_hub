import '../../domain/models/vehicle_model.dart';

abstract class VehicleRepository {
  Future<List<VehicleModel>> getVehicles();
  Future<VehicleModel?> getVehicleById(String id);
  Future<void> addVehicle(VehicleModel vehicle);
  Future<void> updateVehicle(VehicleModel vehicle);
  Future<void> deleteVehicle(String id);
}
