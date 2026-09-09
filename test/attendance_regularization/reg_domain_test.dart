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

  group('RegTimePolicy — §8.5 day window', () {
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

    test('past the 19:00 fallback cap is rejected', () {
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: DateTime(2026, 6, 23, 19, 1),
          attendanceDate: date,
          signedInAt: signedIn,
        ),
        'Time is outside the school day.',
      );
    });

    test('the cap itself is allowed', () {
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: DateTime(2026, 6, 23, 19, 0),
          attendanceDate: date,
          signedInAt: signedIn,
        ),
        isNull,
      );
    });

    test('a real school cap overrides the fallback', () {
      final cap = DateTime(2026, 6, 23, 17, 30);
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: DateTime(2026, 6, 23, 18, 0),
          attendanceDate: date,
          signedInAt: signedIn,
          cap: cap,
        ),
        isNotNull,
      );
    });

    test('a corrected time may not cross midnight', () {
      expect(
        RegTimePolicy.validateSignOut(
          signOutLocal: DateTime(2026, 6, 24, 1, 0),
          attendanceDate: date,
          signedInAt: signedIn,
        ),
        isNotNull,
      );
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

    test('suggestedOrCap uses the server suggestion when present', () {
      final at = DateTime(2026, 6, 23, 17, 30);
      expect(build(suggested: at).suggestedOrCap, at);
    });

    test('suggestedOrCap falls back to the 19:00 cap when absent (§8.5)', () {
      final resolved = build().suggestedOrCap;
      expect(resolved, DateTime(2026, 6, 23, 19, 0));
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
      );
    }

    test('isAutoApproved when the raiser approved their own request (§8.2b)',
        () {
      // Derived from the two actor columns — raised_by_role and auto_approved
      // were dropped from the model precisely because this works (§7.2).
      expect(
        build(raisedBy: 'USR_ADMIN', approvalBy: 'USR_ADMIN').isAutoApproved,
        isTrue,
      );
      expect(
        build(raisedBy: 'STF_1', approvalBy: 'USR_ADMIN').isAutoApproved,
        isFalse,
      );
      // Still pending — nobody approved it.
      expect(build().isAutoApproved, isFalse);
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

    test('time rules still apply with a good reason', () {
      expect(
        build(signOut: DateTime(2026, 6, 23, 23, 0)).validate(
          signedInAt: signedIn,
        ),
        'Time is outside the school day.',
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

    test('the day window is re-checked on edit (§8.5)', () {
      final input = RegEditInput(
        code: 'SREG_1',
        attendanceDate: date,
        signOutLocal: DateTime(2026, 6, 23, 22, 0),
      );
      expect(input.validate(signedInAt: signedIn), isNotNull);
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
        count: 2,
        skipped: [RegSkipped(key: 'SREG_C', reason: 'already decided')],
      );
      expect(r.hasSkipped, isTrue);
      expect(r.skippedKeys, {'SREG_C'});
      expect(r.isNoop, isFalse);
      expect(r.summary, '2 approved · 1 skipped — already decided');
    });

    test('a clean batch summarises without a skip clause', () {
      const r = RegBatchResult(count: 3, skipped: []);
      expect(r.summary, '3 approved');
    });

    test('mixed skip reasons are not attributed to one cause', () {
      const r = RegBatchResult(
        count: 0,
        skipped: [
          RegSkipped(key: 'a', reason: 'already decided'),
          RegSkipped(key: 'b', reason: 'already resolved'),
        ],
      );
      expect(r.isNoop, isTrue);
      expect(r.summary, '0 approved · 2 skipped');
    });
  });

  group('RegPage', () {
    RegPage<int> page(List<int> items, int p, int size, int total) =>
        RegPage<int>(items: items, page: p, size: size, total: total);

    test('hasMore while later pages remain', () {
      expect(page([1, 2], 0, 2, 5).hasMore, isTrue);
      expect(page([5], 2, 2, 5).hasMore, isFalse);
    });

    test('an empty page never reports more, whatever total says', () {
      // Guards against an endless load-more loop if total is inconsistent.
      expect(page([], 0, 10, 99).hasMore, isFalse);
      expect(const RegPage<int>.empty().hasMore, isFalse);
    });

    test('append keeps the newer cursor and concatenates', () {
      final merged = page([1, 2], 0, 2, 5).append(page([3, 4], 1, 2, 5));
      expect(merged.items, [1, 2, 3, 4]);
      expect(merged.page, 1);
      expect(merged.hasMore, isTrue);
    });

    test('withItems replaces content but keeps the cursor', () {
      final replaced = page([1, 2], 1, 2, 5).withItems([9]);
      expect(replaced.items, [9]);
      expect(replaced.page, 1);
      expect(replaced.total, 5);
    });
  });

  group('RegSortOrder', () {
    test('maps to the API sort values (§9.3, §9.5)', () {
      expect(RegSortOrder.oldestFirst.wireValue, 'createdAt,asc');
      expect(RegSortOrder.newestFirst.wireValue, 'createdAt,desc');
    });
  });
}
