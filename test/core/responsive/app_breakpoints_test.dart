import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/responsive/app_breakpoints.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';

void main() {
  group('AppBreakpoints.classify', () {
    test('resolves the four widths this mandate cares about', () {
      expect(AppBreakpoints.classify(375), ScreenSizeClass.compact);
      expect(AppBreakpoints.classify(700), ScreenSizeClass.medium);
      expect(AppBreakpoints.classify(768), ScreenSizeClass.medium);
      expect(AppBreakpoints.classify(1024), ScreenSizeClass.expanded);
      expect(AppBreakpoints.classify(900), ScreenSizeClass.medium);
    });

    test('boundaries are inclusive-low', () {
      expect(AppBreakpoints.classify(599.9), ScreenSizeClass.compact);
      expect(AppBreakpoints.classify(600), ScreenSizeClass.medium);
      expect(AppBreakpoints.classify(1023.9), ScreenSizeClass.medium);
      expect(AppBreakpoints.classify(1024), ScreenSizeClass.expanded);
      expect(AppBreakpoints.isNarrow(359.9), isTrue);
      expect(AppBreakpoints.isNarrow(360), isFalse);
    });

    test('isTablet is everything at or above 600', () {
      expect(ScreenSizeClass.compact.isTablet, isFalse);
      expect(ScreenSizeClass.medium.isTablet, isTrue);
      expect(ScreenSizeClass.expanded.isTablet, isTrue);
    });
  });

  group('ResponsiveScope', () {
    Future<ScreenSizeClass> classAt(WidgetTester tester, double width) async {
      late ScreenSizeClass seen;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 900)),
          child: ResponsiveScope(
            child: Builder(
              builder: (context) {
                seen = context.screenSize;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return seen;
    }

    testWidgets('publishes the size class at each width', (tester) async {
      expect(await classAt(tester, 375), ScreenSizeClass.compact);
      expect(await classAt(tester, 700), ScreenSizeClass.medium);
      expect(await classAt(tester, 768), ScreenSizeClass.medium);
      expect(await classAt(tester, 1024), ScreenSizeClass.expanded);
    });

    testWidgets('responsive() falls back to the next narrower value', (
      tester,
    ) async {
      late String medium;
      late String expanded;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 900)),
          child: ResponsiveScope(
            child: Builder(
              builder: (context) {
                medium = context.responsive(compact: 'c');
                expanded = context.responsive(compact: 'c', expanded: 'e');
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(medium, 'c', reason: 'medium falls back to compact');
      expect(expanded, 'c', reason: 'medium is not expanded');
    });

    testWidgets('resolves without a scope mounted', (tester) async {
      late bool tablet;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 900)),
          child: Builder(
            builder: (context) {
              tablet = context.isTablet;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tablet, isTrue);
    });
  });
}
