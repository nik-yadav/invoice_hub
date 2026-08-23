import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_invoice_pro/app/app.dart';

void main() {
  testWidgets('App compiles and loads successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TransportInvoiceProApp()));

    // Verify that the app widget is instantiated.
    expect(find.byType(TransportInvoiceProApp), findsOneWidget);
  });
}
