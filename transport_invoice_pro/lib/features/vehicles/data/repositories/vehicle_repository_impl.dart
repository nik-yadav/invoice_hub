import '../../../../core/services/api_service.dart';
import '../../domain/models/vehicle_model.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_local_data_source.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleLocalDataSource _localDataSource;

  VehicleRepositoryImpl(this._localDataSource);

  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final response = await ApiService.get('/vehicles');
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data'];
        final vehicles = list.map((e) => VehicleModel.fromMap(Map<String, dynamic>.from(e))).toList();
        await _localDataSource.saveVehicles(vehicles);
        return vehicles;
      }
    } catch (_) {}
    return _localDataSource.getVehicles();
  }

  @override
  Future<VehicleModel?> getVehicleById(String id) async {
    try {
      final response = await ApiService.get('/vehicles/$id');
      if (response['success'] == true && response['data'] != null) {
        return VehicleModel.fromMap(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final vehicles = await getVehicles();
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVehicle(VehicleModel vehicle) async {
    try {
      await ApiService.post('/vehicles', vehicle.toMap());
    } catch (_) {}

    final vehicles = await getVehicles();
    vehicles.add(vehicle);
    await _localDataSource.saveVehicles(vehicles);
  }

  @override
  Future<void> updateVehicle(VehicleModel vehicle) async {
    try {
      await ApiService.put('/vehicles/${vehicle.id}', vehicle.toMap());
    } catch (_) {}

    final vehicles = await getVehicles();
    final index = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      vehicles[index] = vehicle;
      await _localDataSource.saveVehicles(vehicles);
    }
  }

  @override
  Future<void> deleteVehicle(String id) async {
    try {
      await ApiService.delete('/vehicles/$id');
    } catch (_) {}

    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v.id == id);
    await _localDataSource.saveVehicles(vehicles);
  }
}
