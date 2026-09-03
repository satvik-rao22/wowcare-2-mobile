import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

BoxDecoration _dotDecoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.descendant(
                of: find.byType(AttendanceDot),
                matching: find.byType(Container),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  const c = Colourway.l4;

  group('AppAvatar', () {
    testWidgets('is 44 round with the initials, and no dot by default', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppAvatar(initials: 'AO')));

      expect(find.text('AO'), findsOneWidget);
      expect(tester.getSize(find.byType(AppAvatar)), const Size(44, 44));
      expect(find.byType(AttendanceDot), findsNothing);
    });

    testWidgets('each attendance status draws its own dot colour', (
      tester,
    ) async {
      final expected = <AttendanceStatus, Color>{
        AttendanceStatus.signedIn: c.signedIn,
        AttendanceStatus.signedOut: c.signedOut,
        AttendanceStatus.absent: c.absent,
        AttendanceStatus.notMarked: c.notMarked,
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _host(AppAvatar(initials: 'AO', attendance: entry.key)),
        );
        final dot = _dotDecoration(tester);
        expect(dot.color, entry.value, reason: entry.key.name);
        expect(dot.border!.top.color, c.card, reason: 'ring is card colour');
        expect(dot.border!.top.width, AppSizes.attendanceDotRing);
        expect(
          tester.getSize(find.byType(AttendanceDot)),
          const Size(AppSizes.attendanceDot, AppSizes.attendanceDot),
        );
      }
    });

    testWidgets('the ring can take the ground it sits on', (tester) async {
      await tester.pumpWidget(
        _host(
          AppAvatar(
            initials: 'AO',
            attendance: AttendanceStatus.signedIn,
            ringColor: c.page,
          ),
        ),
      );
      expect(_dotDecoration(tester).border!.top.color, c.page);
    });

    testWidgets('tones colour the initials', (tester) async {
      Color? ink() => tester.widget<Text>(find.text('DW')).style?.color;

      await tester.pumpWidget(
        _host(const AppAvatar(initials: 'DW', tone: AvatarTone.staff)),
      );
      expect(ink(), c.staffFg);

      await tester.pumpWidget(
        _host(const AppAvatar(initials: 'DW', tone: AvatarTone.impact)),
      );
      expect(ink(), c.onAvatar);

      await tester.pumpWidget(_host(const AppAvatar(initials: 'DW')));
      expect(ink(), c.student);
    });
  });
}
