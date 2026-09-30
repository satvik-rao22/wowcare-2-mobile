/// Widget tests for [RichTextToolbar] after its Mandate 2 conversion of the
/// four selection-driven formatting flags from `setState` to a single
/// `ValueNotifier` record. Asserts the active-state highlight tracks the
/// controller selection — the behaviour the notifier drives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/rich_text_toolbar.dart';

void main() {
  Future<TextEditingController> pumpToolbar(
    WidgetTester tester, {
    required String text,
    required int cursor,
  }) async {
    final controller = TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: cursor);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RichTextToolbar(controller: controller)),
      ),
    );
    await tester.pump();
    return controller;
  }

  Color? iconColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color;

  testWidgets('cursor inside a <b> run highlights Bold, not Italic', (
    tester,
  ) async {
    // <b>hi</b> — cursor at offset 4 sits between h and i, inside the bold run.
    await pumpToolbar(tester, text: '<b>hi</b>', cursor: 4);

    expect(iconColor(tester, Icons.format_bold), AppColors.primaryColor);
    expect(
      iconColor(tester, Icons.format_italic),
      isNot(AppColors.primaryColor),
    );
  });

  testWidgets('moving the cursor out of the run clears the Bold highlight', (
    tester,
  ) async {
    final controller = await pumpToolbar(
      tester,
      text: '<b>hi</b> there',
      cursor: 4,
    );
    expect(iconColor(tester, Icons.format_bold), AppColors.primaryColor);

    // Move the cursor past the closing tag into the plain " there".
    controller.selection = const TextSelection.collapsed(offset: 12);
    await tester.pump();

    expect(iconColor(tester, Icons.format_bold), isNot(AppColors.primaryColor));
  });

  testWidgets('plain text leaves every format button inactive', (tester) async {
    await pumpToolbar(tester, text: 'plain', cursor: 3);

    for (final icon in const [
      Icons.format_bold,
      Icons.format_italic,
      Icons.format_underlined,
      Icons.format_strikethrough,
    ]) {
      expect(iconColor(tester, icon), isNot(AppColors.primaryColor));
    }
  });

  testWidgets(
    'tapping Bullet list on an empty field does not throw (regression)',
    (tester) async {
      // lastIndexOf('\n', pos - 1) with pos == 0 (empty field, cursor at
      // start) passed a negative start index and threw
      // "RangeError: Invalid value: Only valid value is 0: -1".
      final controller = await pumpToolbar(tester, text: '', cursor: 0);

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.text, '• ');
    },
  );

  testWidgets(
    'tapping Numbered list on an empty field does not throw (regression)',
    (tester) async {
      final controller = await pumpToolbar(tester, text: '', cursor: 0);

      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.text, '1. ');
    },
  );
}
