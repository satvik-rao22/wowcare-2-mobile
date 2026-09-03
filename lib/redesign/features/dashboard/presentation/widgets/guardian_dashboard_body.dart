import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/attendance_record_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/child_activities_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/child_day_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/child_sign_out_sheet.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/child_switcher.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/guardian_billing_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/newsletter_card.dart';

/// 3P1 and 3P2. What a Guardian sees: one student at a time, through a
/// switcher that changes shape with the family.
///
/// No roster, no staff, no other family's data. A guardian's two actions are
/// scanning the door code and signing their own student out.
class GuardianDashboardBody extends StatelessWidget {
  const GuardianDashboardBody({required this.state, super.key});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final snapshot = state.snapshot;
    final child = state.selectedChild;

    if (child == null) {
      return const Padding(
        padding: AppSizes.bodyPad,
        child: EmptyState(
          icon: AppIcons.students,
          title: DashboardStrings.noChildren,
          subtitle: DashboardStrings.noChildrenSub,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.cardGap,
        children: <Widget>[
          ChildSwitcher(
            children: snapshot.children,
            selectedId: child.id,
            onSelect: cubit.selectChild,
          ),
          ChildDayCard(
            child: child,
            onScanQr: () => unawaited(context.push(AppRoutes.kioskScanner)),
            onSignOut: () => unawaited(
              showChildSignOutSheet(context, cubit: cubit, child: child),
            ),
            onReminderChanged: (isOn) =>
                unawaited(cubit.setReminder(isOn: isOn)),
          ),
          ChildActivitiesCard(
            firstName: child.firstName,
            tally: child.activities,
            onSeeAll: () => _later(context),
          ),
          if (snapshot.childAttendance != null)
            AttendanceRecordCard(
              title: DashboardStrings.attendance,
              record: snapshot.childAttendance!,
              presentLabel: DashboardStrings.daysPresent,
              onChangeRange: () => _later(context),
            ),
          if (snapshot.guardianBilling != null)
            GuardianBillingCard(
              billing: snapshot.guardianBilling!,
              onPayNow: () => _later(context),
              onOpenInvoices: () => _later(context),
            ),
          if (snapshot.newsletter != null)
            NewsletterCard(
              newsletter: snapshot.newsletter!,
              onTap: () => _later(context),
            ),
        ],
      ),
    );
  }

  static void _later(BuildContext context) =>
      showAppToast(context, AppStrings.comingSoon);
}
