import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/datasources/customer_local_data_source.dart';
import '../../data/repositories/customer_repository_impl.dart';

final customerLocalDataSourceProvider = Provider<CustomerLocalDataSource>((ref) {
  return CustomerLocalDataSource();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final localDataSource = ref.watch(customerLocalDataSourceProvider);
  return CustomerRepositoryImpl(localDataSource);
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<CustomerModel>>(
  CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<CustomerModel>> {
  @override
  Future<List<CustomerModel>> build() async {
    return ref.watch(customerRepositoryProvider).getCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await ref.read(customerRepositoryProvider).getCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await ref.read(customerRepositoryProvider).addCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await ref.read(customerRepositoryProvider).updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await ref.read(customerRepositoryProvider).deleteCustomer(id);
    await loadCustomers();
  }
}

final filteredCustomersProvider = Provider<AsyncValue<List<CustomerModel>>>((ref) {
  final customersState = ref.watch(customersProvider);
  final searchQuery = ref.watch(customerSearchQueryProvider).toLowerCase();

  return customersState.whenData((customers) {
    if (searchQuery.isEmpty) return customers;
    return customers.where((customer) {
      return customer.customerName.toLowerCase().contains(searchQuery) ||
             customer.phone.contains(searchQuery) ||
             customer.gstin.toLowerCase().contains(searchQuery) ||
             customer.city.toLowerCase().contains(searchQuery);
    }).toList();
  });
});
