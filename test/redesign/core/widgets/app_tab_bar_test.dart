import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_tab_bar.dart';

const _items = <AppTabItem>[
  AppTabItem(icon: AppIcons.dashboard, label: 'Dashboard'),
  AppTabItem(icon: AppIcons.attendance, label: 'Attendance'),
  AppTabItem(icon: AppIcons.classrooms, label: 'Classrooms'),
  AppTabItem(icon: AppIcons.activities, label: 'Activities'),
  AppTabItem(icon: AppIcons.messages, label: 'Messages', badgeCount: 7),
];

Widget _host({int? selectedIndex, ValueChanged<int>? onSelect}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    bottomNavigationBar: AppTabBar(
      items: _items,
      selectedIndex: selectedIndex,
      onSelect: onSelect ?? (_) {},
    ),
  ),
);

Color? _labelColour(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  const c = Colourway.l4;

  group('AppTabBar', () {
    testWidgets('renders every slot', (tester) async {
      await tester.pumpWidget(_host(selectedIndex: 0));
      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('the selected slot is pink and bold, the rest ink3', (
      tester,
    ) async {
      await tester.pumpWidget(_host(selectedIndex: 1));

      final active = tester.widget<Text>(find.text('Attendance'));
      expect(active.style?.color, c.pink);
      expect(active.style?.fontWeight, FontWeight.w700);

      expect(_labelColour(tester, 'Dashboard'), c.ink3);
      expect(_labelColour(tester, 'Messages'), c.ink3);
    });

    testWidgets('a null index highlights nothing', (tester) async {
      await tester.pumpWidget(_host());
      for (final item in _items) {
        expect(_labelColour(tester, item.label), c.ink3);
      }
    });

    testWidgets('shows the unread badge count', (tester) async {
      await tester.pumpWidget(_host(selectedIndex: 0));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('reports the tapped index', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _host(selectedIndex: 0, onSelect: (i) => selected = i),
      );

      await tester.tap(find.text('Classrooms'));
      await tester.pumpAndSettle();
      expect(selected, 2);
    });
  });
}
