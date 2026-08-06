import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/vehicle_model.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../data/datasources/vehicle_local_data_source.dart';
import '../../data/repositories/vehicle_repository_impl.dart';

// Provides the repository instance
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dataSource = VehicleLocalDataSource();
  return VehicleRepositoryImpl(dataSource);
});

// Provides the list of vehicles and handles state changes
final vehiclesProvider = AsyncNotifierProvider<VehicleNotifier, List<VehicleModel>>(() {
  return VehicleNotifier();
});

class VehicleNotifier extends AsyncNotifier<List<VehicleModel>> {
  late final VehicleRepository _repository;

  @override
  Future<List<VehicleModel>> build() async {
    _repository = ref.watch(vehicleRepositoryProvider);
    return _repository.getVehicles();
  }

  Future<void> loadVehicles() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getVehicles());
  }

  Future<void> addVehicle(VehicleModel vehicle) async {
    await _repository.addVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    await _repository.updateVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await _repository.deleteVehicle(id);
    await loadVehicles();
  }
}

// Search Query State
final vehicleSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered list based on search query
final filteredVehiclesProvider = Provider<AsyncValue<List<VehicleModel>>>((ref) {
  final vehiclesState = ref.watch(vehiclesProvider);
  final searchQuery = ref.watch(vehicleSearchQueryProvider).toLowerCase();

  return vehiclesState.whenData((vehicles) {
    if (searchQuery.isEmpty) return vehicles;
    return vehicles.where((v) {
      return v.vehicleNumber.toLowerCase().contains(searchQuery) ||
             v.driverName.toLowerCase().contains(searchQuery) ||
             v.type.toLowerCase().contains(searchQuery);
    }).toList();
  });
});
