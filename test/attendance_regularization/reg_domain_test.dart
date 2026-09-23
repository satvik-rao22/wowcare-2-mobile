import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/missed_signout.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_batch_gate.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_batch_result.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_edit_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_page.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_raise_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/domain/policy/reg_time_policy.dart';
import 'package:wowcare/modules/attendance_regularization/domain/repositories/regularization_repository.dart';

/// Domain-layer unit tests. Pure Dart — no widgets, no HTTP.
///
/// These pin the business rules the spec locks down, so a later refactor of
/// the data or presentation layer cannot quietly change them.
void main() {
  final date = DateTime(2026, 6, 23);
  final signedIn = DateTime(2026, 6, 23, 7, 37);

  group('RegStatus — exactly two values (§6)', () {
    test('has no cancelled or rejected state', () {
      expect(RegStatus.values, [RegStatus.pending, RegStatus.approved]);
    });

    test('wire values round-trip', () {
      expect(regStatusFromWire('PENDING'), RegStatus.pending);
      expect(regStatusFromWire('approved'), RegStatus.approved);
      expect(RegStatus.pending.wireValue, 'PENDING');
      expect(RegStatus.approved.wireValue, 'APPROVED');
    });

    test('an unknown status throws rather than defaulting to pending', () {
      // Defaulting would show an Approve button on something not pending.
      expect(() => regStatusFromWire('CANCELLED'), throwsArgumentError);
      expect(() => regStatusFromWire('REJECTED'), throwsArgumentError);
    });
  });

  group('RegTimePolicy — §8.2 reason', () {
    test('blank, empty and whitespace-only reasons are rejected', () {
      expect(RegTimePolicy.validateReason(null), isNotNull);
      expect(RegTimePolicy.validateReason(''), isNotNull);
      expect(RegTimePolicy.validateReason('   '), isNotNull);
      expect(RegTimePolicy.validateReason('\n\t '), isNotNull);
    });

    test('a real reason passes', () {
      expect(RegTimePolicy.validateReason('parent meeting'), isNull);
      expect(RegTimePolicy.hasReason('  ok  '), isTrue);
    });
  });

  group('RegTimePolicy — sign-out window', () {
    test('sign-out must be after sign-in', () {
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: DateTime(2026, 6, 23, 7, 0),
          attendanceDate: date,
          signedInAt: signedIn,
        ),
        'Sign-out must be after sign-in.',
      );
    });

    test('a sign-out equal to sign-in is rejected', () {
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: signedIn,
          attendanceDate: date,
          signedInAt: signedIn,
        ),
        isNotNull,
      );
    });

    test('there is no closing-time bound', () {
      // Staff stay late — clean-up, a parent meeting, a late pick-up — and
      // those are exactly the days a sign-out is forgotten. A cap would
      // reject the requests this module exists to capture.
      for (final late in [
        DateTime(2026, 6, 23, 19, 1),
        DateTime(2026, 6, 23, 21, 30),
        DateTime(2026, 6, 23, 23, 59),
      ]) {
        expect(
          RegTimePolicy.validateSignOut(
            signOutLocal: late,
            attendanceDate: date,
            signedInAt: signedIn,
          ),
          isNull,
          reason: '$late should be submittable',
        );
      }
    });
  });

  group('MissedSignout', () {
    MissedSignout build({
      DateTime? suggested,
      bool hasPending = false,
      String? pendingCode,
    }) {
      return MissedSignout(
        attendanceCode: 'STAR_1',
        attendanceDate: date,
        signedInAt: signedIn,
        suggestedSignOutTime: suggested,
        hasPendingRequest: hasPending,
        pendingRequestCode: pendingCode,
      );
    }

    test('suggestedOrDefault uses the server suggestion when present', () {
      final at = DateTime(2026, 6, 23, 17, 30);
      expect(build(suggested: at).suggestedOrDefault, at);
    });

    test('suggestedOrDefault opens the picker at 19:00 when absent', () {
      // A starting point for the picker, not a limit on what may be picked.
      expect(build().suggestedOrDefault, DateTime(2026, 6, 23, 19, 0));
    });

    test('blocksSignIn is false once a request exists (§8.3)', () {
      // The whole point of hasPendingRequest: a staff who already raised must
      // not be pushed through the sheet again every morning.
      expect(build().blocksSignIn, isTrue);
      expect(build(hasPending: true).blocksSignIn, isFalse);
    });

    test('resolvesByEdit needs both the flag and the code (§9.4)', () {
      expect(build(hasPending: true, pendingCode: 'SREG_1').resolvesByEdit,
          isTrue);
      // Flag without a code cannot address PATCH /{code}, so create is the
      // only reachable path.
      expect(build(hasPending: true).resolvesByEdit, isFalse);
      expect(build(hasPending: true, pendingCode: '').resolvesByEdit, isFalse);
      expect(build(pendingCode: 'SREG_1').resolvesByEdit, isFalse);
    });

    test('initials handle one-word, two-word and empty names', () {
      MissedSignout named(String n) => MissedSignout(
            attendanceCode: 'STAR_1',
            attendanceDate: date,
            staffName: n,
          );
      expect(named('Sara Malik').initials, 'SM');
      expect(named('Sara').initials, 'S');
      expect(named('Sara Jane Malik').initials, 'SM');
      expect(named('').initials, '?');
      expect(named('   ').initials, '?');
    });
  });

  group('RegularizationRequest', () {
    RegularizationRequest build({
      RegStatus status = RegStatus.pending,
      DateTime? approvedAt,
      String raisedBy = 'STF_1',
      String? approvalBy,
      DateTime? updatedAt,
      bool autoApproved = false,
    }) {
      return RegularizationRequest(
        code: 'SREG_1',
        staffCode: 'STF_1',
        staffName: 'Sara Malik',
        attendanceCode: 'STAR_1',
        attendanceDate: date,
        requestedSignOutTime: DateTime(2026, 6, 23, 18, 0),
        reason: 'parent meeting',
        status: status,
        raisedByCode: raisedBy,
        createdAt: DateTime(2026, 6, 24, 8, 5),
        approvedSignOutTime: approvedAt,
        approvalByCode: approvalBy,
        updatedAt: updatedAt,
        autoApproved: autoApproved,
      );
    }

    test('autoApproved is carried, not derived', () {
      expect(build(autoApproved: true).autoApproved, isTrue);
      expect(build().autoApproved, isFalse);
    });

    test('isEditable only while pending (§8.6)', () {
      expect(build().isEditable, isTrue);
      expect(build(status: RegStatus.approved).isEditable, isFalse);
    });

    test('wasModified compares requested against approved (§7.4)', () {
      expect(
        build(
          status: RegStatus.approved,
          approvedAt: DateTime(2026, 6, 23, 17, 45),
        ).wasModified,
        isTrue,
      );
      expect(
        build(
          status: RegStatus.approved,
          approvedAt: DateTime(2026, 6, 23, 18, 0),
        ).wasModified,
        isFalse,
      );
      expect(build().wasModified, isFalse);
    });

    test('effectiveSignOutTime prefers the approved time', () {
      final approved = DateTime(2026, 6, 23, 17, 45);
      expect(
        build(status: RegStatus.approved, approvedAt: approved)
            .effectiveSignOutTime,
        approved,
      );
      expect(build().effectiveSignOutTime, DateTime(2026, 6, 23, 18, 0));
    });

    test('wasEdited only when updatedAt is later than createdAt (§9.4)', () {
      expect(build().wasEdited, isFalse);
      expect(
        build(updatedAt: DateTime(2026, 6, 24, 8, 5)).wasEdited,
        isFalse,
      );
      expect(
        build(updatedAt: DateTime(2026, 6, 24, 9, 0)).wasEdited,
        isTrue,
      );
    });
  });

  group('RegRaiseInput', () {
    RegRaiseInput build({DateTime? signOut, String reason = 'parent meeting'}) {
      return RegRaiseInput(
        staffCode: 'STF_1',
        attendanceCode: 'STAR_1',
        attendanceDate: date,
        signOutLocal: signOut ?? DateTime(2026, 6, 23, 18, 0),
        reason: reason,
      );
    }

    test('valid input passes', () {
      expect(build().validate(signedInAt: signedIn), isNull);
    });

    test('reason is checked before the time, so the first fix is the reason',
        () {
      final bad = build(reason: '', signOut: DateTime(2026, 6, 23, 23, 0));
      expect(bad.validate(signedInAt: signedIn), 'Add a reason.');
    });

    test('a late sign-out with a good reason is submittable', () {
      expect(
        build(signOut: DateTime(2026, 6, 23, 23, 0)).validate(
          signedInAt: signedIn,
        ),
        isNull,
      );
    });

    test('but sign-out before sign-in is still rejected', () {
      expect(
        build(signOut: DateTime(2026, 6, 23, 6, 0)).validate(
          signedInAt: signedIn,
        ),
        'Sign-out must be after sign-in.',
      );
    });

    test('forGate carries the codes from the gate item', () {
      final item = MissedSignout(
        attendanceCode: 'STAR_9',
        attendanceDate: date,
        staffCode: 'STF_9',
      );
      final input = RegRaiseInput.forGate(
        item,
        signOutStaffCode: 'FALLBACK',
        signOutLocal: DateTime(2026, 6, 23, 18, 0),
        reason: 'ok',
      );
      expect(input.attendanceCode, 'STAR_9');
      expect(input.staffCode, 'STF_9');
      expect(input.attendanceDate, date);
    });

    test('forGate falls back to the acting staff when the item carries none',
        () {
      // §9.1 omits staffCode for a staff resolving their own day; only the
      // batch gate (§9.1b) supplies it.
      final item = MissedSignout(
        attendanceCode: 'STAR_9',
        attendanceDate: date,
      );
      final input = RegRaiseInput.forGate(
        item,
        signOutStaffCode: 'STF_ME',
        signOutLocal: DateTime(2026, 6, 23, 18, 0),
        reason: 'ok',
      );
      expect(input.staffCode, 'STF_ME');
    });
  });

  group('RegEditInput (§9.4)', () {
    test('an empty patch is rejected', () {
      final input = RegEditInput(code: 'SREG_1', attendanceDate: date);
      expect(input.hasChange, isFalse);
      expect(input.validate(), isNotNull);
    });

    test('time-only edit is valid and does not require a reason', () {
      // Asymmetry with a raise: an edit leaves the existing reason in place.
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        signOutLocal: DateTime(2026, 6, 23, 18, 0),
      );
      expect(input.validate(signedInAt: signedIn), isNull);
    });

    test('reason-only edit is valid', () {
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        reason: 'corrected',
      );
      expect(input.validate(), isNull);
    });

    test('a supplied reason may not be blank — an edit never clears it', () {
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        reason: '  ',
      );
      expect(input.validate(), 'Add a reason.');
    });

    test('a late sign-out is accepted on edit too', () {
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        signOutLocal: DateTime(2026, 6, 23, 22, 0),
      );
      expect(input.validate(signedInAt: signedIn), isNull);
    });

    test('but "after sign-in" is still re-checked on edit', () {
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        signOutLocal: DateTime(2026, 6, 23, 6, 0),
      );
      expect(input.validate(signedInAt: signedIn),
          'Sign-out must be after sign-in.');
    });
  });

  group('RegBatchGate (§9.1b)', () {
    test('splits blocked from clear', () {
      final gate = RegBatchGate(
        blocked: [
          MissedSignout(
            attendanceCode: 'STAR_A',
            attendanceDate: date,
            staffCode: 'STF_A',
          ),
        ],
        clear: const ['STF_B', 'STF_C'],
      );
      expect(gate.hasBlocked, isTrue);
      expect(gate.blockedStaffCodes, ['STF_A']);
      expect(gate.total, 3);
    });

    test('empty gate blocks nobody', () {
      expect(const RegBatchGate.empty().hasBlocked, isFalse);
      expect(const RegBatchGate.empty().total, 0);
    });
  });

  group('RegBatchResult (§9.2b, §9.7)', () {
    test('reports skipped keys for reconciling an optimistic list', () {
      const r = RegBatchResult(
        applied: 2,
        skipped: [RegSkipped(code: 'SREG_C', reason: 'already decided')],
      );
      expect(r.hasSkipped, isTrue);
      expect(r.skippedKeys, {'SREG_C'});
      expect(r.isNoop, isFalse);
      expect(r.summary, '2 approved · 1 skipped — already decided');
    });

    test('a clean batch summarises without a skip clause', () {
      const r = RegBatchResult(applied: 3, skipped: []);
      expect(r.summary, '3 approved');
    });

    test('mixed skip reasons are not attributed to one cause', () {
      const r = RegBatchResult(
        applied: 0,
        skipped: [
          RegSkipped(code: 'a', reason: 'already decided'),
          RegSkipped(code: 'b', reason: 'already resolved'),
        ],
      );
      expect(r.isNoop, isTrue);
      expect(r.summary, '0 approved · 2 skipped');
    });
  });

  group('RegPage', () {
    RegPage<int> page(List<int> items, int p, bool more) => RegPage<int>(
        items: items, page: p, size: 2, total: 5, hasMore: more);

    test('append takes the newer page cursor and flag', () {
      final merged = page([1, 2], 0, true).append(page([3, 4], 1, false));
      expect(merged.items, [1, 2, 3, 4]);
      expect(merged.page, 1);
      expect(merged.hasMore, isFalse);
    });

    test('withItems replaces content but keeps the cursor', () {
      final replaced = page([1, 2], 1, true).withItems([9]);
      expect(replaced.items, [9]);
      expect(replaced.page, 1);
      expect(replaced.hasMore, isTrue);
    });

    test('an empty page reports nothing more', () {
      expect(const RegPage<int>.empty().hasMore, isFalse);
    });
  });

  group('RegSortOrder', () {
    test('maps to the API sort values (§9.3, §9.5)', () {
      expect(RegSortOrder.oldestFirst.wireValue, 'createdAt,asc');
      expect(RegSortOrder.newestFirst.wireValue, 'createdAt,desc');
    });
  });
}
