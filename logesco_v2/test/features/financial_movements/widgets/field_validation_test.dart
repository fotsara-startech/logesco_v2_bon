import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/financial_movements/widgets/field_validation_indicator.dart';

void main() {
  group('FieldValidationIndicator', () {
    testWidgets('shows error icon when error text is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldValidationIndicator(
              errorText: 'Test error',
              isValid: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('shows check icon when valid and no error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldValidationIndicator(
              errorText: null,
              isValid: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('shows nothing when not valid but no error text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FieldValidationIndicator(
              errorText: null,
              isValid: false,
              showValidIcon: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.error), findsNothing);
    });
  });

  group('RealTimeValidatedTextField', () {
    testWidgets('validates input in real time', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealTimeValidatedTextField(
              controller: controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Field is required';
                }
                return null;
              },
            ),
          ),
        ),
      );

      // Initially no validation icon should be shown
      expect(find.byType(FieldValidationIndicator), findsNothing);

      // Tap the field to mark interaction
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Should show error icon for empty field
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Enter valid text
      await tester.enterText(find.byType(TextFormField), 'Valid text');
      await tester.pump();

      // Should show check icon for valid field
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });
  });
}
