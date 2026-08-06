import '../../../../core/services/api_service.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_local_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;

  CustomerRepositoryImpl(this.localDataSource);

  @override
  Future<List<CustomerModel>> getCustomers() async {
    try {
      final response = await ApiService.get('/customers');
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data'];
        final customers = list.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e))).toList();
        await localDataSource.saveCustomers(customers);
        return customers;
      }
    } catch (_) {}
    return localDataSource.getCustomers();
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final response = await ApiService.get('/customers/$id');
      if (response['success'] == true && response['data'] != null) {
        return CustomerModel.fromJson(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final customers = await localDataSource.getCustomers();
    try {
      return customers.firstWhere((customer) => customer.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await ApiService.post('/customers', customer.toJson());
    } catch (_) {}

    final customers = await localDataSource.getCustomers();
    customers.add(customer);
    await localDataSource.saveCustomers(customers);
  }

  @override
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await ApiService.put('/customers/${customer.id}', customer.toJson());
    } catch (_) {}

    final customers = await localDataSource.getCustomers();
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      await localDataSource.saveCustomers(customers);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await ApiService.delete('/customers/$id');
    } catch (_) {}

    final customers = await localDataSource.getCustomers();
    final index = customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      customers.removeAt(index);
      await localDataSource.saveCustomers(customers);
    }
  }
}
