import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/vehicle_model.dart';

class VehicleLocalDataSource {
  static const String _vehiclesKey = 'vehicles_list';

  Future<List<VehicleModel>> getVehicles() async {
    final box = HiveService.getBox(AppConstants.vehicleCacheBox);
    final String? data = box.get(_vehiclesKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => VehicleModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> saveVehicles(List<VehicleModel> vehicles) async {
    final box = HiveService.getBox(AppConstants.vehicleCacheBox);
    final String data = jsonEncode(vehicles.map((e) => e.toMap()).toList());
    await box.put(_vehiclesKey, data);
  }
}
