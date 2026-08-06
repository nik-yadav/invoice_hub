import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getCustomers();
  Future<CustomerModel?> getCustomerById(String id);
  Future<void> addCustomer(CustomerModel customer);
  Future<void> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}
