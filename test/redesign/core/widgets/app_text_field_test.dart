import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

void main() {
  const c = Colourway.l4;

  group('AppTextField', () {
    testWidgets('shows the label with a pink required mark', (tester) async {
      await tester.pumpWidget(
        _host(const AppTextField(label: 'Email', isRequired: true)),
      );

      final label = find.text('Email *', findRichText: true);
      expect(label, findsOneWidget);

      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(FieldLabel),
          matching: find.byType(RichText),
        ),
      );
      // Text.rich wraps the label span in one carrying the default style.
      final root = rich.text as TextSpan;
      final labelSpan = root.children!.single as TextSpan;
      final mark = labelSpan.children!.single as TextSpan;
      expect(mark.style?.color, c.pink);
    });

    testWidgets('an optional field has no mark', (tester) async {
      await tester.pumpWidget(_host(const AppTextField(label: 'Notes')));
      expect(find.text('Notes', findRichText: true), findsOneWidget);
      expect(find.text('Notes *', findRichText: true), findsNothing);
    });

    testWidgets('error state shows the line in danger ink and the border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AppTextField(
            label: 'Phone',
            helpText: 'With a country code',
            errorText: 'Enter a phone number',
          ),
        ),
      );

      final error = tester.widget<Text>(find.text('Enter a phone number'));
      expect(error.style?.color, c.dangerFg);
      expect(find.text('With a country code'), findsNothing);

      final well = tester
          .widgetList<Container>(find.byType(Container))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      expect(well.border!.top.color, c.danger);
      expect(well.border!.top.width, 1.5);
    });

    testWidgets('help line shows when there is no error', (tester) async {
      await tester.pumpWidget(
        _host(const AppTextField(label: 'Phone', helpText: 'Optional')),
      );
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('the eye toggles obscured text', (tester) async {
      await tester.pumpWidget(
        _host(const AppTextField(label: 'Password', obscureText: true)),
      );

      EditableText input() =>
          tester.widget<EditableText>(find.byType(EditableText));

      expect(input().obscureText, isTrue);
      expect(find.byIcon(AppIcons.eye), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.eye));
      await tester.pumpAndSettle();
      expect(input().obscureText, isFalse);
      expect(find.byIcon(AppIcons.eyeOff), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.eyeOff));
      await tester.pumpAndSettle();
      expect(input().obscureText, isTrue);
    });

    testWidgets('forwards typed text', (tester) async {
      String? value;
      await tester.pumpWidget(
        _host(AppTextField(label: 'Name', onChanged: (v) => value = v)),
      );

      await tester.enterText(find.byType(EditableText), 'Amara');
      expect(value, 'Amara');
    });
  });
}
