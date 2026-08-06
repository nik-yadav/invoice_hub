import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/models/invoice_model.dart';

class InvoiceLocalDataSource {
  static const String _invoicesKey = 'invoices_list';

  Future<List<InvoiceModel>> getInvoices() async {
    final box = HiveService.getBox(AppConstants.offlineInvoicesBox);
    final String? data = box.get(_invoicesKey);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => InvoiceModel.fromMap(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> saveInvoices(List<InvoiceModel> invoices) async {
    final box = HiveService.getBox(AppConstants.offlineInvoicesBox);
    final String data = jsonEncode(invoices.map((e) => e.toMap()).toList());
    await box.put(_invoicesKey, data);
  }
}
