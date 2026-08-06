import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../data/datasources/invoice_local_data_source.dart';
import '../../data/repositories/invoice_repository_impl.dart';

// Provides the repository instance
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dataSource = InvoiceLocalDataSource();
  return InvoiceRepositoryImpl(dataSource);
});

// Provides the list of invoices and handles state changes
final invoicesProvider = AsyncNotifierProvider<InvoiceNotifier, List<InvoiceModel>>(() {
  return InvoiceNotifier();
});

class InvoiceNotifier extends AsyncNotifier<List<InvoiceModel>> {
  late final InvoiceRepository _repository;

  @override
  Future<List<InvoiceModel>> build() async {
    _repository = ref.watch(invoiceRepositoryProvider);
    return _repository.getInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getInvoices());
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    await _repository.addInvoice(invoice);
    await loadInvoices();
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    await _repository.updateInvoice(invoice);
    await loadInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    await _repository.deleteInvoice(id);
    await loadInvoices();
  }
}

// Filters State
class InvoiceFilters {
  final String searchQuery;
  final String? customerId;
  final String? vehicleId;
  final String? firmId;
  final PaymentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;

  InvoiceFilters({
    this.searchQuery = '',
    this.customerId,
    this.vehicleId,
    this.firmId,
    this.status,
    this.startDate,
    this.endDate,
  });

  InvoiceFilters copyWith({
    String? searchQuery,
    String? customerId,
    String? vehicleId,
    String? firmId,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStatus = false,
    bool clearDates = false,
    bool clearCustomer = false,
    bool clearVehicle = false,
    bool clearFirm = false,
  }) {
    return InvoiceFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      firmId: clearFirm ? null : (firmId ?? this.firmId),
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

final invoiceFiltersProvider = StateProvider<InvoiceFilters>((ref) => InvoiceFilters());

// Filtered list based on search and filters
final filteredInvoicesProvider = Provider<AsyncValue<List<InvoiceModel>>>((ref) {
  final invoicesState = ref.watch(invoicesProvider);
  final filters = ref.watch(invoiceFiltersProvider);

  return invoicesState.whenData((invoices) {
    var result = invoices;
    
    // Sort by invoiceDate descending by default
    result.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    if (filters.searchQuery.isNotEmpty) {
      final q = filters.searchQuery.toLowerCase();
      result = result.where((i) => 
        i.invoiceNumber.toLowerCase().contains(q) || 
        (i.materialDescription?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    
    if (filters.customerId != null) {
      result = result.where((i) => i.customerId == filters.customerId).toList();
    }
    
    if (filters.vehicleId != null) {
      result = result.where((i) => i.vehicleId == filters.vehicleId).toList();
    }
    
    if (filters.firmId != null) {
      result = result.where((i) => i.firmId == filters.firmId).toList();
    }
    
    if (filters.status != null) {
      result = result.where((i) => i.paymentStatus == filters.status).toList();
    }
    
    if (filters.startDate != null && filters.endDate != null) {
      result = result.where((i) {
        return i.invoiceDate.isAfter(filters.startDate!.subtract(const Duration(days: 1))) && 
               i.invoiceDate.isBefore(filters.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    return result;
  });
});
