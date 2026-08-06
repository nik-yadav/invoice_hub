import '../../../../core/services/api_service.dart';
import '../../domain/models/invoice_model.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_local_data_source.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource _localDataSource;

  InvoiceRepositoryImpl(this._localDataSource);

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final response = await ApiService.get('/invoices');
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data'];
        final invoices = list.map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e))).toList();
        await _localDataSource.saveInvoices(invoices);
        return invoices;
      }
    } catch (_) {}
    return _localDataSource.getInvoices();
  }

  @override
  Future<InvoiceModel?> getInvoiceById(String id) async {
    try {
      final response = await ApiService.get('/invoices/$id');
      if (response['success'] == true && response['data'] != null) {
        return InvoiceModel.fromMap(Map<String, dynamic>.from(response['data']));
      }
    } catch (_) {}

    final invoices = await getInvoices();
    try {
      return invoices.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addInvoice(InvoiceModel invoice) async {
    try {
      await ApiService.post('/invoices', invoice.toMap());
    } catch (_) {}

    final invoices = await getInvoices();
    invoices.add(invoice);
    await _localDataSource.saveInvoices(invoices);
  }

  @override
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      await ApiService.put('/invoices/${invoice.id}', invoice.toMap());
    } catch (_) {}

    final invoices = await getInvoices();
    final index = invoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      invoices[index] = invoice;
      await _localDataSource.saveInvoices(invoices);
    }
  }

  @override
  Future<void> deleteInvoice(String id) async {
    try {
      await ApiService.delete('/invoices/$id');
    } catch (_) {}

    final invoices = await getInvoices();
    invoices.removeWhere((i) => i.id == id);
    await _localDataSource.saveInvoices(invoices);
  }
}
