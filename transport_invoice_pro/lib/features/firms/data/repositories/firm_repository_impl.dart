import '../../../../core/services/api_service.dart';
import '../../domain/models/firm_model.dart';
import '../../domain/repositories/firm_repository.dart';
import '../datasources/firm_local_data_source.dart';

class FirmRepositoryImpl implements FirmRepository {
  final FirmLocalDataSource localDataSource;

  FirmRepositoryImpl(this.localDataSource);

  @override
  Future<List<FirmModel>> getFirms() async {
    try {
      final response = await ApiService.get('/firms');
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data'];
        final firms = list.map((e) => FirmModel.fromJson(Map<String, dynamic>.from(e))).toList();
        await localDataSource.saveFirms(firms);
        return firms;
      }
    } catch (_) {}
    return localDataSource.getFirms();
  }

  @override
  Future<FirmModel?> getFirmById(String id) async {
    try {
      final response = await ApiService.get('/firms/$id');
      if (response['success'] == true && response['data'] != null) {
        return FirmModel.fromJson(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    try {
      return firms.firstWhere((firm) => firm.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addFirm(FirmModel firm) async {
    FirmModel createdFirm = firm;
    try {
      final response = await ApiService.post('/firms', firm.toJson());
      if (response['success'] == true && response['data'] != null) {
        createdFirm = FirmModel.fromJson(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    if (firms.isEmpty || createdFirm.isDefault) {
      if (createdFirm.isDefault) {
        for (int i = 0; i < firms.length; i++) {
          firms[i] = firms[i].copyWith(isDefault: false);
        }
      } else {
        createdFirm = createdFirm.copyWith(isDefault: true);
      }
    }
    firms.add(createdFirm);
    await localDataSource.saveFirms(firms);
  }

  @override
  Future<void> updateFirm(FirmModel firm) async {
    FirmModel updatedFirm = firm;
    try {
      final response = await ApiService.put('/firms/${firm.id}', firm.toJson());
      if (response['success'] == true && response['data'] != null) {
        updatedFirm = FirmModel.fromJson(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    final index = firms.indexWhere((f) => f.id == updatedFirm.id);
    if (index != -1) {
      if (updatedFirm.isDefault) {
        for (int i = 0; i < firms.length; i++) {
          firms[i] = firms[i].copyWith(isDefault: false);
        }
      }
      firms[index] = updatedFirm;
      if (!firms.any((f) => f.isDefault) && firms.isNotEmpty) {
        firms[0] = firms[0].copyWith(isDefault: true);
      }
      await localDataSource.saveFirms(firms);
    }
  }

  @override
  Future<void> deleteFirm(String id) async {
    try {
      await ApiService.delete('/firms/$id');
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    final index = firms.indexWhere((f) => f.id == id);
    if (index != -1) {
      final wasDefault = firms[index].isDefault;
      firms.removeAt(index);
      if (wasDefault && firms.isNotEmpty) {
        firms[0] = firms[0].copyWith(isDefault: true);
      }
      await localDataSource.saveFirms(firms);
    }
  }
}
