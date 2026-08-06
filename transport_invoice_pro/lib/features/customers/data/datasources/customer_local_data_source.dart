import 'dart:convert';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/customer_model.dart';

class CustomerLocalDataSource {
  static const String _customersListKey = 'customers_list';

  Future<List<CustomerModel>> getCustomers() async {
    final rawData = HiveService.customersBox.get(_customersListKey);
    if (rawData == null) return [];

    try {
      final List<dynamic> jsonList;
      if (rawData is String) {
        jsonList = jsonDecode(rawData) as List<dynamic>;
      } else if (rawData is List) {
        jsonList = rawData;
      } else {
        return [];
      }

      return jsonList.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomers(List<CustomerModel> customers) async {
    final List<Map<String, dynamic>> jsonList = customers.map((e) => e.toJson()).toList();
    await HiveService.customersBox.put(_customersListKey, jsonEncode(jsonList));
  }
}
