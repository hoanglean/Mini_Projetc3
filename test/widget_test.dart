import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocr_expense_tracker/app.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OcrExpenseTrackerApp(),
      ),
    );

    // Verify basic dashboard destination is present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
