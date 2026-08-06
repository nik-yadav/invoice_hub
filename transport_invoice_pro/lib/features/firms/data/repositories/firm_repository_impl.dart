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
    try {
      await ApiService.post('/firms', firm.toJson());
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    if (firms.isEmpty || firm.isDefault) {
      if (firm.isDefault) {
        for (int i = 0; i < firms.length; i++) {
          firms[i] = firms[i].copyWith(isDefault: false);
        }
      } else {
        firm = firm.copyWith(isDefault: true);
      }
    }
    firms.add(firm);
    await localDataSource.saveFirms(firms);
  }

  @override
  Future<void> updateFirm(FirmModel firm) async {
    try {
      await ApiService.put('/firms/${firm.id}', firm.toJson());
    } catch (_) {}

    final firms = await localDataSource.getFirms();
    final index = firms.indexWhere((f) => f.id == firm.id);
    if (index != -1) {
      if (firm.isDefault) {
        for (int i = 0; i < firms.length; i++) {
          firms[i] = firms[i].copyWith(isDefault: false);
        }
      }
      firms[index] = firm;
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
