import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/firm_model.dart';
import '../../domain/repositories/firm_repository.dart';
import '../../data/datasources/firm_local_data_source.dart';
import '../../data/repositories/firm_repository_impl.dart';

final firmLocalDataSourceProvider = Provider<FirmLocalDataSource>((ref) {
  return FirmLocalDataSource();
});

final firmRepositoryProvider = Provider<FirmRepository>((ref) {
  final localDataSource = ref.watch(firmLocalDataSourceProvider);
  return FirmRepositoryImpl(localDataSource);
});

final firmSearchQueryProvider = StateProvider<String>((ref) => '');

final firmsProvider = AsyncNotifierProvider<FirmsNotifier, List<FirmModel>>(
  FirmsNotifier.new,
);

class FirmsNotifier extends AsyncNotifier<List<FirmModel>> {
  @override
  Future<List<FirmModel>> build() async {
    return ref.watch(firmRepositoryProvider).getFirms();
  }

  Future<void> loadFirms() async {
    state = const AsyncValue.loading();
    try {
      final firms = await ref.read(firmRepositoryProvider).getFirms();
      state = AsyncValue.data(firms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFirm(FirmModel firm) async {
    await ref.read(firmRepositoryProvider).addFirm(firm);
    await loadFirms();
  }

  Future<void> updateFirm(FirmModel firm) async {
    await ref.read(firmRepositoryProvider).updateFirm(firm);
    await loadFirms();
  }

  Future<void> deleteFirm(String id) async {
    await ref.read(firmRepositoryProvider).deleteFirm(id);
    await loadFirms();
  }
}

final filteredFirmsProvider = Provider<AsyncValue<List<FirmModel>>>((ref) {
  final firmsState = ref.watch(firmsProvider);
  final searchQuery = ref.watch(firmSearchQueryProvider).toLowerCase();

  return firmsState.whenData((firms) {
    if (searchQuery.isEmpty) return firms;
    return firms.where((firm) {
      return firm.businessName.toLowerCase().contains(searchQuery) ||
             firm.ownerName.toLowerCase().contains(searchQuery) ||
             firm.phone.contains(searchQuery) ||
             firm.gstin.toLowerCase().contains(searchQuery);
    }).toList();
  });
});

final defaultFirmProvider = Provider<AsyncValue<FirmModel?>>((ref) {
  return ref.watch(firmsProvider).whenData((firms) {
    if (firms.isEmpty) return null;
    try {
      return firms.firstWhere((f) => f.isDefault);
    } catch (_) {
      return firms.first;
    }
  });
});
