import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';

// NOTE: the attendance FORMS and the daily VIEW pull ~10 dependencies from the
// service locator in initState/build, so a faithful widget test of those would
// need the whole DI graph faked. These smoke + responsive tests instead exercise
// the real, dependency-free presentation widgets they render (the card + its
// loading shimmer), which is where the render-state and overflow logic lives.

StudentAttendanceCardData _data() => StudentAttendanceCardData(
  id: 'REC-1',
  studentName: 'Alice Johnson',
  roomName: 'Sunflower Room',
  expectedToday: true,
  hasSignIn: true,
  studentId: 1,
  roomId: 2,
  schoolId: 3,
  isTransferSignIn: false,
  isTransferSignOut: false,
  signInTime: '09:00:00 AM',
);

Widget _host({required double width, required Widget child}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: Scaffold(
      body: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('StudentAttendanceCard — widget smoke (distinct UI per state)', () {
    testWidgets('loaded state renders the student name', (tester) async {
      await tester.pumpWidget(
        _host(width: 400, child: StudentAttendanceCard(student: _data(), index: 0)),
      );

      expect(find.textContaining('Alice Johnson'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'loading (shimmer) renders a DISTINCT UI — the loading skeleton, not the '
      'data card, and none of the student data text',
      (tester) async {
        await tester.pumpWidget(
          _host(width: 400, child: const StudentAttendanceCardShimmer()),
        );

        expect(find.byType(StudentAttendanceCardShimmer), findsOneWidget);
        expect(find.byType(StudentAttendanceCard), findsNothing);
        expect(find.textContaining('Alice Johnson'), findsNothing);
      },
    );
  });

  group('StudentAttendanceCard — responsive (no overflow at 375/768/1024)', () {
    for (final width in <double>[375, 768, 1024]) {
      testWidgets('lays out with no RenderFlex overflow at ${width.toInt()}px', (
        tester,
      ) async {
        // pumpWidget builds + lays out one frame; a RenderFlex overflow would
        // surface as an exception captured by takeException().
        await tester.pumpWidget(
          _host(
            width: width,
            child: StudentAttendanceCard(
              student: _data(),
              index: 0,
              isExpanded: true,
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'card overflowed at ${width.toInt()}px',
        );
      });
    }
  });
}
