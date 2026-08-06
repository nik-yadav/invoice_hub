import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../customers/domain/models/customer_model.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../vehicles/domain/models/vehicle_model.dart';
import '../../domain/models/invoice_model.dart';
import '../utils/invoice_pdf_generator.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;
  final FirmModel firm;
  final CustomerModel customer;
  final VehicleModel vehicle;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    required this.firm,
    required this.customer,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF Invoice',
            onPressed: () async {
              final pdfBytes = await InvoicePdfGenerator.generate(
                invoice: invoice,
                firm: firm,
                customer: customer,
                vehicle: vehicle,
              );
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${invoice.invoiceNumber}.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        pdfFileName: '${invoice.invoiceNumber}.pdf',
        canChangePageFormat: false,
        canChangeOrientation: false,
        build: (format) => InvoicePdfGenerator.generate(
          invoice: invoice,
          firm: firm,
          customer: customer,
          vehicle: vehicle,
        ),
      ),
    );
  }
}
