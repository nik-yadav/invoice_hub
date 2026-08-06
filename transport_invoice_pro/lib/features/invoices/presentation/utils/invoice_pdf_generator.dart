import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/formatters.dart';
import '../../../customers/domain/models/customer_model.dart';
import '../../../firms/domain/models/firm_model.dart';
import '../../../vehicles/domain/models/vehicle_model.dart';
import '../../domain/models/invoice_model.dart';
import 'number_to_words.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generate({
    required InvoiceModel invoice,
    required FirmModel firm,
    required CustomerModel customer,
    required VehicleModel vehicle,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    if (firm.logoPath != null && firm.logoPath!.trim().isNotEmpty) {
      final path = firm.logoPath!.trim();
      try {
        if (path.startsWith('data:image')) {
          final base64String = path.split(',').last.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64String);
          logoImage = pw.MemoryImage(bytes);
        } else {
          final file = File(path);
          if (file.existsSync()) {
            logoImage = pw.MemoryImage(file.readAsBytesSync());
          } else {
            final bytes = base64Decode(path.replaceAll(RegExp(r'\s+'), ''));
            logoImage = pw.MemoryImage(bytes);
          }
        }
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    if (firm.signaturePath != null && firm.signaturePath!.trim().isNotEmpty) {
      final path = firm.signaturePath!.trim();
      try {
        if (path.startsWith('data:image')) {
          final base64String = path.split(',').last.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64String);
          signatureImage = pw.MemoryImage(bytes);
        } else {
          final file = File(path);
          if (file.existsSync()) {
            signatureImage = pw.MemoryImage(file.readAsBytesSync());
          } else {
            final bytes = base64Decode(path.replaceAll(RegExp(r'\s+'), ''));
            signatureImage = pw.MemoryImage(bytes);
          }
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey800, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. MAIN TAX INVOICE HEADER
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey800, width: 1.5),
                    ),
                  ),
                  child: pw.Text(
                    'TRANSPORT TAX INVOICE',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),

                // 2. CARRIER / FIRM DETAILS
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null) ...[
                            pw.Container(
                              width: 44,
                              height: 44,
                              margin: const pw.EdgeInsets.only(right: 10),
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          ],
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(firm.businessName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 3),
                              pw.Text(firm.address, style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text('Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text('PAN: ${firm.pan}', style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('GSTIN: ${firm.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          if (firm.email.isNotEmpty)
                            pw.Text('Email: ${firm.email}', style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. INVOICE METADATA & CLIENT
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // Bill To Customer
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BILL TO (CUSTOMER):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.SizedBox(height: 4),
                              pw.Text(customer.customerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              if (customer.address.isNotEmpty) pw.Text(customer.address, style: const pw.TextStyle(fontSize: 8)),
                              if (customer.gstin.isNotEmpty) pw.Text('GSTIN: ${customer.gstin}', style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                      // Invoice Details
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('INVOICE DETAILS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                              pw.SizedBox(height: 4),
                              pw.Row(children: [pw.Text('Invoice No: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(invoice.invoiceNumber, style: const pw.TextStyle(fontSize: 8))]),
                              pw.Row(children: [pw.Text('Invoice Date: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(DateFormat('dd MMM yyyy').format(invoice.invoiceDate), style: const pw.TextStyle(fontSize: 8))]),
                              pw.Row(children: [pw.Text('Vehicle Number: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(vehicle.vehicleNumber, style: const pw.TextStyle(fontSize: 8))]),
                              pw.Row(children: [pw.Text('Driver Info: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text('${vehicle.driverName} (${vehicle.driverPhone})', style: const pw.TextStyle(fontSize: 8))]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. TRANS TRIP & CARRIAGE ROUTE DETAILS
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CARRIAGE & TRIP DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Source Station:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.Text(invoice.sourceAddress, style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Destination Station:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.Text(invoice.destAddress, style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300, height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(child: pw.Row(children: [pw.Text('Material: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(invoice.materialDescription ?? 'N/A', style: const pw.TextStyle(fontSize: 8))])),
                          pw.Expanded(child: pw.Row(children: [pw.Text('Weight (Tons): ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)), pw.Text(invoice.weight != null ? '${invoice.weight} Tons' : 'N/A', style: const pw.TextStyle(fontSize: 8))])),
                        ],
                      ),
                      
                      // Render custom party-level fields dynamically
                      if (invoice.customPartiesFields.isNotEmpty) ...[
                        pw.Divider(color: PdfColors.grey300, height: 12),
                        pw.Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: invoice.customPartiesFields.entries.map((e) {
                            return pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text('${e.key}: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.Text(e.value, style: const pw.TextStyle(fontSize: 8)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // 5. CHARGES BREAKDOWN
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FREIGHT CHARGES BREAKDOWN', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Basic Transportation Freight Charge', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(_formatCurrency(invoice.transportationCharge), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 4),

                      // Dynamic Extra Charges
                      ...invoice.customChargesFields.entries.map((e) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(e.key, style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(_formatCurrency(e.value), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                // 6. TOTAL AMOUNT SUMMARY CARD & WORDS
                pw.Spacer(),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // Amount in words
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total In Words:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                              pw.SizedBox(height: 4),
                              pw.Text(NumberToWords.convert(invoice.totalAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // Grand Total Card
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            border: pw.Border(
                              left: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text(_formatCurrency(invoice.totalAmount), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 7. FOOTER NOTES & SIGNATURE
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      // Remarks
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Remarks:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                              pw.SizedBox(height: 2),
                              pw.Text(invoice.remarks.isNotEmpty ? invoice.remarks : 'No specific remarks.', style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                      // Authorized Signature
                      pw.Container(
                        width: 180,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            left: pw.BorderSide(color: PdfColors.grey800, width: 1.2),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('For ${firm.businessName}:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            if (signatureImage != null)
                              pw.Container(
                                height: 40,
                                width: 140,
                                alignment: pw.Alignment.center,
                                child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                              )
                            else
                              pw.SizedBox(height: 40),
                            pw.Container(height: 0.5, color: PdfColors.grey500),
                            pw.SizedBox(height: 2),
                            pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return 'Rs. ${formatter.format(amount)}';
  }
}
