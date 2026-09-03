import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/attendance_record_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/message_row.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/my_day_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/my_shifts_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/staff_day_sheet.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/staff_ratio_card.dart';

/// 3S1 and 3S2. What a Staff member sees: their own day first, because their
/// day is the screen, then the classroom they are standing in.
///
/// Attendance actions here are gated on the school geofence, and the card
/// says so rather than letting a key fail quietly.
class StaffDashboardBody extends StatelessWidget {
  const StaffDashboardBody({required this.state, super.key});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final snapshot = state.snapshot;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.cardGap,
        children: <Widget>[
          if (snapshot.myDay != null)
            MyDayCard(
              day: snapshot.myDay!,
              isOpen: true,
              showGeofence: true,
              onScanQr: () => unawaited(context.push(AppRoutes.kioskScanner)),
              onTransfer: () =>
                  unawaited(showTransferSheet(context, cubit: cubit)),
              onMarkAbsent: () =>
                  unawaited(showMarkAbsentSheet(context, cubit: cubit)),
              onSignOut: () => unawaited(
                showStaffSignOutSheet(context, cubit: cubit),
              ),
            ),
          if (snapshot.ratios.isNotEmpty)
            StaffRatioCard(rows: snapshot.ratios),
          if (snapshot.message != null)
            MessageRow(
              message: snapshot.message!,
              isCard: true,
              onTap: () => _later(context),
            ),
          if (snapshot.week.isNotEmpty)
            MyShiftsCard(
              days: snapshot.week,
              rangeLabel: snapshot.weekRangeLabel,
            ),
          if (snapshot.myAttendance != null)
            AttendanceRecordCard(
              title: DashboardStrings.myAttendance,
              record: snapshot.myAttendance!,
              onChangeRange: () => _later(context),
            ),
        ],
      ),
    );
  }

  static void _later(BuildContext context) =>
      showAppToast(context, AppStrings.comingSoon);
}
