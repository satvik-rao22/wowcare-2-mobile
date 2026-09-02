import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';

/// Static sample data for the static-screen phase / tests.
class RegularizationFixtures {
  const RegularizationFixtures._();

  static DateTime _at(int day, int h, int m) => DateTime(2026, 6, day, h, m);

  /// The unresolved soft sign-out shown in the next-day gate.
  static MissedSignout get pendingGate => MissedSignout(
        attendanceCode: 'STAR_DEMO_1',
        attendanceDate: DateTime(2026, 6, 23),
        softSignOutAt: _at(23, 17, 30),
        signInAt: _at(23, 7, 37),
        classroomName: '4-Indigo-Classroom',
      );

  /// Bulk sign-in gate: the admin selected 50 staff and these 10 still have an
  /// unresolved past day, so they can't be signed in until it's closed.
  static List<MissedSignout> get bulkSignInGate {
    const names = [
      'Sara Malik', 'Leo Martins', 'Aisha Rahman', 'Tomas Neuman',
      'Grace Adeyemi', 'Ravi Menon', 'Elena Petrova', 'Kwame Boateng',
      'Yuki Tanaka', 'Nora Halvorsen',
    ];
    return [
      for (var i = 0; i < names.length; i++)
        MissedSignout(
          attendanceCode: 'STAR_BULK_$i',
          staffCode: 'STF_BULK_$i',
          staffName: names[i],
          attendanceDate: DateTime(2026, 6, 23),
          softSignOutAt: _at(23, 17, 30),
          signInAt: _at(23, 7, 30 + i),
          classroomName: '4-Indigo-Classroom',
        ),
    ];
  }

  /// Admin inbox — pending requests from staff.
  static List<RegularizationRequest> get adminInbox => [
        RegularizationRequest(
          code: 'REG_1',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          classroomName: '4-Indigo-Classroom',
          attendanceDate: DateTime(2026, 6, 23),
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
          requestedSignOutAt: _at(22, 18, 0),
          softSignOutAt: _at(22, 17, 30),
          reason: 'Phone died, could not sign out at the end of shift.',
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
          requestedSignOutAt: _at(12, 16, 30),
          softSignOutAt: _at(12, 17, 30),
          reason: 'Left early for an appointment.',
          status: RegStatus.cancelled,
          createdAt: _at(13, 8, 0),
          decidedByName: 'Chaitanya Bhave',
          decidedAt: _at(13, 11, 0),
          decisionNote: 'No supporting record.',
        ),
      ];
}
