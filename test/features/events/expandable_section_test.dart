import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/expandable_section.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

AnimatedCrossFade _fade(WidgetTester tester) =>
    tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));

void main() {
  testWidgets('renders title, count pill and icon', (tester) async {
    await tester.pumpWidget(
      _host(
        const ExpandableSection(
          title: 'Active Holidays',
          count: 3,
          icon: Icons.event_available_outlined,
          child: Text('body'),
        ),
      ),
    );

    expect(find.text('Active Holidays'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // count pill
    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
  });

  testWidgets('starts collapsed by default and expands on header tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ExpandableSection(title: 'Section', child: Text('body content')),
      ),
    );

    // Default is collapsed.
    expect(_fade(tester).crossFadeState, CrossFadeState.showFirst);

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();

    expect(_fade(tester).crossFadeState, CrossFadeState.showSecond);
  });

  testWidgets('initiallyExpanded shows the body and collapses on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ExpandableSection(
          title: 'Section',
          initiallyExpanded: true,
          child: Text('body content'),
        ),
      ),
    );

    expect(_fade(tester).crossFadeState, CrossFadeState.showSecond);

    await tester.tap(find.text('Section'));
    await tester.pumpAndSettle();

    expect(_fade(tester).crossFadeState, CrossFadeState.showFirst);
  });
}
