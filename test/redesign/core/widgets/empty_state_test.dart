import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('EmptyState', () {
    testWidgets('shows the glyph in a 64px tile, title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const EmptyState(
            icon: AppIcons.classrooms,
            title: 'No classrooms yet',
            subtitle: 'Create the first one.',
          ),
        ),
      );

      expect(find.text('No classrooms yet'), findsOneWidget);
      expect(find.text('Create the first one.'), findsOneWidget);
      expect(find.byIcon(AppIcons.classrooms), findsOneWidget);
      expect(find.byType(PrimaryKey), findsNothing);

      final tile = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(AppIcons.classrooms),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(tile, const Size(AppSizes.emptyIcon, AppSizes.emptyIcon));
    });

    testWidgets('the one key is a primary key and fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          EmptyState(
            icon: AppIcons.classrooms,
            title: 'No classrooms yet',
            actionLabel: 'Create a classroom',
            onAction: () => taps++,
          ),
        ),
      );

      expect(find.byType(PrimaryKey), findsOneWidget);
      await tester.tap(find.text('Create a classroom'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    test('an action needs both its label and handler', () {
      expect(
        () => EmptyState(
          icon: AppIcons.classrooms,
          title: 'No classrooms yet',
          actionLabel: 'Create',
        ),
        throwsAssertionError,
      );
    });
  });
}
