import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';

/// Static sample data for the static-screen phase / tests.
class RegularizationFixtures {
  const RegularizationFixtures._();

  static DateTime _at(int day, int h, int m) => DateTime(2026, 6, day, h, m);

  /// The unresolved soft sign-out shown in the next-day gate.
  static MissedSignout get pendingGate => MissedSignout(
        recordCode: 'STAR_DEMO_1',
        attendanceDate: DateTime(2026, 6, 23),
        softSignOutAt: _at(23, 17, 30),
        signInAt: _at(23, 7, 37),
        classroomName: '4-Indigo-Classroom',
      );

  /// Admin inbox — pending requests from staff.
  static List<RegularizationRequest> get adminInbox => [
        RegularizationRequest(
          code: 'REG_1',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          classroomName: '4-Indigo-Classroom',
          attendanceDate: DateTime(2026, 6, 23),
          type: RegType.missedSignOut,
          requestedSignOutAt: _at(23, 19, 0),
          softSignOutAt: _at(23, 17, 30),
          reason: 'Stayed for parent meeting, forgot to sign out.',
          status: RegStatus.pending,
          createdAt: _at(24, 8, 5),
        ),
        RegularizationRequest(
          code: 'REG_2',
          staffCode: 'STF_2',
          staffName: 'PragnaSri Kokala',
          classroomName: '4-Yellow-D',
          attendanceDate: DateTime(2026, 6, 22),
          type: RegType.missedSignIn,
          requestedSignInAt: _at(22, 8, 5),
          reason: 'Phone died, could not sign in on arrival.',
          status: RegStatus.pending,
          createdAt: _at(23, 9, 12),
        ),
      ];

  /// Staff "my requests" — mix of statuses.
  static List<RegularizationRequest> get myRequests => [
        RegularizationRequest(
          code: 'REG_1',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceDate: DateTime(2026, 6, 23),
          type: RegType.missedSignOut,
          requestedSignOutAt: _at(23, 19, 0),
          softSignOutAt: _at(23, 17, 30),
          reason: 'Stayed for parent meeting.',
          status: RegStatus.pending,
          createdAt: _at(24, 8, 5),
        ),
        RegularizationRequest(
          code: 'REG_0',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceDate: DateTime(2026, 6, 18),
          type: RegType.missedSignOut,
          requestedSignOutAt: _at(18, 18, 15),
          softSignOutAt: _at(18, 17, 30),
          reason: 'Late pickup coverage.',
          status: RegStatus.approved,
          createdAt: _at(19, 8, 0),
          decidedByName: 'Chaitanya Bhave',
          decidedAt: _at(19, 10, 30),
        ),
        RegularizationRequest(
          code: 'REG_X',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceDate: DateTime(2026, 6, 12),
          type: RegType.timeCorrection,
          requestedSignInAt: _at(12, 8, 0),
          requestedSignOutAt: _at(12, 16, 30),
          reason: 'Wrong sign-in time recorded.',
          status: RegStatus.rejected,
          createdAt: _at(13, 8, 0),
          decidedByName: 'Chaitanya Bhave',
          decidedAt: _at(13, 11, 0),
          decisionNote: 'No supporting record.',
        ),
      ];
}
