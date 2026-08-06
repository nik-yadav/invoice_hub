import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Abstract utility helper for PDF document generation and printing services.
class PdfHelper {
  PdfHelper._();

  /// Create a standard PDF Document configured with default A4 page setup.
  static pw.Document createDocument({
    String title = 'Transport Invoice',
    String author = 'Transport Invoice Pro',
  }) {
    return pw.Document(
      title: title,
      author: author,
      pageMode: PdfPageMode.thumbs,
    );
  }

  /// Print document directly to system default printer or trigger print modal.
  static Future<bool> printDocument({
    required Uint8List pdfBytes,
    String jobName = 'Transport_Invoice',
  }) async {
    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: jobName,
    );
  }

  /// Share generated PDF file via device share sheet.
  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String filename,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  /// Standard Page Format getter (A4 standard for invoices).
  static PdfPageFormat get defaultPageFormat => PdfPageFormat.a4;
}
