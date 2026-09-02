import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_card_permissions.dart';
import 'package:wowcare/presentation/features/activities/view/activity_item.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

// AC-P0-3 (permission integrity): the admin approve/reject bar must respect the
// LIVE active persona, not a once-read staffType. These tests pin the two halves
// that gate on the persona:
//   1. `canAdminApproveOrRejectActivityItem` — the downstream predicate the bar
//      calls; a non-admin persona (`isAdminPersona: false`) must never see it,
//      and even an admin persona only sees it while the item is pending.
//   2. `activeAdminPersona(context)` — the live RoleCubit read that feeds the
//      `isAdminPersona` flag: true only when the active persona is admin (not the
//      staff persona of a dual-role user).

ActivityItem _activity(String? approvalStatus) => ActivityItem(
  time: '10:00 AM',
  date: '2026-08-31',
  name: 'Meal',
  studentList: const <String>['Sam'],
  createdBy: 'STF-1',
  approvalStatus: approvalStatus,
);

/// Minimal RoleCubit stand-in whose persona is fixed by [role]. Constructed
/// directly (bypassing the real `_bootstrap`/service-locator wiring) so the
/// persona getters can be exercised in isolation.
class _RolePersonaCubit extends Cubit<RoleState> implements RoleCubit {
  _RolePersonaCubit({required String role}) : super(RoleState(role: role));
  @override
  bool get isAdmin => state.role == 'admin' || state.role == 'staff';
  @override
  bool get isStaff => state.role == 'staff';
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Pumps [child] under a provided [role] persona and returns the value that
/// `activeAdminPersona` resolves to for that persona.
Future<bool> _resolveActiveAdminPersona(
  WidgetTester tester, {
  required String role,
}) async {
  late bool captured;
  await tester.pumpWidget(
    BlocProvider<RoleCubit>(
      create: (_) => _RolePersonaCubit(role: role),
      child: Builder(
        builder: (context) {
          captured = activeAdminPersona(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('canAdminApproveOrRejectActivityItem', () {
    test('non-admin persona never sees approve/reject, even when pending', () {
      expect(
        canAdminApproveOrRejectActivityItem(
          _activity('PENDING_ADMIN_APPROVAL'),
          isAdminPersona: false,
        ),
        isFalse,
      );
      expect(
        canAdminApproveOrRejectActivityItem(
          _activity('PENDING'),
          isAdminPersona: false,
        ),
        isFalse,
      );
    });

    test('admin persona sees approve/reject for a pending item', () {
      expect(
        canAdminApproveOrRejectActivityItem(
          _activity('PENDING_ADMIN_APPROVAL'),
          isAdminPersona: true,
        ),
        isTrue,
      );
      expect(
        canAdminApproveOrRejectActivityItem(
          _activity('PENDING'),
          isAdminPersona: true,
        ),
        isTrue,
      );
    });

    test('non-pending status is never approvable, regardless of persona', () {
      for (final status in <String?>[
        'APPROVED',
        'REJECTED',
        'NOT_REQUIRED',
        null,
      ]) {
        expect(
          canAdminApproveOrRejectActivityItem(
            _activity(status),
            isAdminPersona: true,
          ),
          isFalse,
          reason: 'status=$status must not be approvable',
        );
      }
    });
  });

  group('activeAdminPersona', () {
    testWidgets('true when active persona is admin', (tester) async {
      expect(await _resolveActiveAdminPersona(tester, role: 'admin'), isTrue);
    });

    testWidgets('false when active persona is staff (dual-role acting as staff)',
        (tester) async {
      expect(await _resolveActiveAdminPersona(tester, role: 'staff'), isFalse);
    });

    testWidgets('false when active persona is parent', (tester) async {
      expect(await _resolveActiveAdminPersona(tester, role: 'parent'), isFalse);
    });
  });
}
