import '../../domain/models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceModel>> getInvoices();
  Future<InvoiceModel?> getInvoiceById(String id);
  Future<void> addInvoice(InvoiceModel invoice);
  Future<void> updateInvoice(InvoiceModel invoice);
  Future<void> deleteInvoice(String id);
}
