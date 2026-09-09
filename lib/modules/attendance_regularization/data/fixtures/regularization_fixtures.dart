import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';

/// Static sample data for the static-screen phase / widget tests.
///
/// These are deliberately dumb constants. The stateful in-memory
/// `RegFakeDataSource` (data phase) is what exercises the raise → approve →
/// gate-clears loop; fixtures exist only so widget tests stay fast and
/// cubit-free.
class RegularizationFixtures {
  const RegularizationFixtures._();

  static DateTime _at(int day, int h, int m) => DateTime(2026, 6, day, h, m);

  /// The unresolved past day shown in the next-day gate.
  static MissedSignout get pendingGate => MissedSignout(
        attendanceCode: 'STAR_DEMO_1',
        attendanceDate: DateTime(2026, 6, 23),
        suggestedSignOutTime: _at(23, 17, 30),
        signedInAt: _at(23, 7, 37),
        classroomCode: 'CLS_49E5BD28-A',
      );

  /// The same day, but a request has already been raised — the gate must let
  /// sign-in through (§8.3) and offer **edit** rather than a second create.
  static MissedSignout get pendingGateAlreadyRaised => MissedSignout(
        attendanceCode: 'STAR_DEMO_1',
        attendanceDate: DateTime(2026, 6, 23),
        suggestedSignOutTime: _at(23, 17, 30),
        signedInAt: _at(23, 7, 37),
        classroomCode: 'CLS_49E5BD28-A',
        hasPendingRequest: true,
        pendingRequestCode: 'SREG_0001',
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
          suggestedSignOutTime: _at(23, 17, 30),
          signedInAt: _at(23, 7, 30 + i),
          classroomCode: 'CLS_49E5BD28-A',
        ),
    ];
  }

  /// Admin inbox — pending requests from staff.
  static List<RegularizationRequest> get adminInbox => [
        RegularizationRequest(
          code: 'SREG_0001',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceCode: 'STAR_DEMO_1',
          attendanceDate: DateTime(2026, 6, 23),
          requestedSignOutTime: _at(23, 19, 0),
          reason: 'Stayed for parent meeting, forgot to sign out.',
          status: RegStatus.pending,
          raisedByCode: 'STF_1',
          createdAt: _at(24, 8, 5),
        ),
        RegularizationRequest(
          code: 'SREG_0002',
          staffCode: 'STF_2',
          staffName: 'PragnaSri Kokala',
          attendanceCode: 'STAR_DEMO_2',
          attendanceDate: DateTime(2026, 6, 22),
          requestedSignOutTime: _at(22, 18, 0),
          reason: 'Phone died, could not sign out at the end of shift.',
          status: RegStatus.pending,
          raisedByCode: 'STF_2',
          createdAt: _at(23, 9, 12),
        ),
      ];

  /// Staff "my requests" — pending, approved as submitted, and approved with a
  /// modified time (the `wasModified` case).
  static List<RegularizationRequest> get myRequests => [
        RegularizationRequest(
          code: 'SREG_0001',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceCode: 'STAR_DEMO_1',
          attendanceDate: DateTime(2026, 6, 23),
          requestedSignOutTime: _at(23, 19, 0),
          reason: 'Stayed for parent meeting.',
          status: RegStatus.pending,
          raisedByCode: 'STF_1',
          createdAt: _at(24, 8, 5),
        ),
        RegularizationRequest(
          code: 'SREG_0000',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceCode: 'STAR_DEMO_0',
          attendanceDate: DateTime(2026, 6, 18),
          requestedSignOutTime: _at(18, 18, 15),
          reason: 'Late pickup coverage.',
          status: RegStatus.approved,
          raisedByCode: 'STF_1',
          createdAt: _at(19, 8, 0),
          approvedSignOutTime: _at(18, 18, 15),
          approvalByCode: 'USR_ADMIN_1',
          approvalByName: 'Chaitanya Bhave',
          approvalAt: _at(19, 10, 30),
        ),
        RegularizationRequest(
          code: 'SREG_9999',
          staffCode: 'STF_1',
          staffName: 'Mohan Sonone',
          attendanceCode: 'STAR_DEMO_X',
          attendanceDate: DateTime(2026, 6, 12),
          requestedSignOutTime: _at(12, 17, 0),
          reason: 'Left after the staff meeting.',
          status: RegStatus.approved,
          raisedByCode: 'STF_1',
          createdAt: _at(13, 8, 0),
          approvedSignOutTime: _at(12, 16, 30),
          approvalByCode: 'USR_ADMIN_1',
          approvalByName: 'Chaitanya Bhave',
          approvalAt: _at(13, 11, 0),
          approvalNote: 'Adjusted to the classroom handover time.',
        ),
      ];
}
