import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_durations.dart';
import 'package:wowcare/redesign/core/preview/widget_gallery_page.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_tab_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';

/// The gallery shows a spinning `LoadingRing`, so `pumpAndSettle` never
/// settles. Every step pumps a fixed span instead: a panel's worth, twice.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(AppMotion.panel);
  await tester.pump(AppMotion.panel);
}

Future<void> _pumpGallery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(410, 864);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const WidgetGalleryPage()),
  );
  await _settle(tester);
}

void main() {
  group('WidgetGalleryPage', () {
    testWidgets('lays out every widget at phone size without errors', (
      tester,
    ) async {
      await _pumpGallery(tester);

      expect(find.byType(AppTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Scroll the whole page through so every section gets laid out.
      final scroll = find.byType(SingleChildScrollView).first;
      for (var i = 0; i < 14; i++) {
        await tester.drag(scroll, const Offset(0, -600));
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: 'after drag $i');
      }
    });

    testWidgets('a toast shows and dismisses itself', (tester) async {
      await _pumpGallery(tester);

      // The page shows static toast samples too, so count the delta.
      final samples = find.byType(AppToast).evaluate().length;

      // The header's leading key is the menu key, and it toasts.
      await tester.tap(find.byType(IconKey).first);
      await _settle(tester);
      expect(find.byType(AppToast), findsNWidgets(samples + 1));

      await tester.pump(AppDurations.toast);
      await _settle(tester);
      expect(find.byType(AppToast), findsNWidgets(samples));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a sheet opens and closes', (tester) async {
      await _pumpGallery(tester);

      final scroll = find.byType(SingleChildScrollView).first;
      // The chip row nests its own Scrollable, so take the outer one.
      final scrollable = find
          .descendant(of: scroll, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('Show sheet'),
        400,
        scrollable: scrollable,
      );
      await _settle(tester);

      await tester.tap(find.text('Show sheet'));
      await _settle(tester);
      expect(find.byType(AppBottomSheet), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
