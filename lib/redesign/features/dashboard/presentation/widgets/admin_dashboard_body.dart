import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/attention_deck.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/availability_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/billing_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/message_row.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/my_day_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/ratio_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/school_status_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/shifts_card.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/staff_day_sheet.dart';

/// 3A1 and 3A2. What an Admin sees: the deck first, their own day collapsed
/// under it, then the school, the classrooms, and the money.
///
/// My day is collapsed because an Admin's own shift is not what they open the
/// app for. It is still here, and still theirs to act on.
class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({required this.state, super.key});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final snapshot = state.snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.cardGap,
      children: <Widget>[
        if (!snapshot.attention.isEmpty)
          AttentionDeck(
            summary: snapshot.attention,
            onOpen: (_) => _later(context),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenGutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSizes.cardGap,
            children: <Widget>[
              if (snapshot.myDay != null)
                MyDayCard(
                  day: snapshot.myDay!,
                  isOpen: state.isMyDayOpen,
                  onToggle: cubit.toggleMyDay,
                  onScanQr: () =>
                      unawaited(context.push(AppRoutes.kioskScanner)),
                  onTransfer: () => unawaited(
                    showTransferSheet(context, cubit: cubit),
                  ),
                  onMarkAbsent: () => unawaited(
                    showMarkAbsentSheet(context, cubit: cubit),
                  ),
                  onSignOut: () => unawaited(
                    showStaffSignOutSheet(
                      context,
                      cubit: cubit,
                      canAdjustTime: true,
                    ),
                  ),
                ),
              if (snapshot.message != null && state.isMyDayOpen)
                MessageRow(
                  message: snapshot.message!,
                  onTap: () => _later(context),
                ),
              if (snapshot.schoolStatus != null)
                SchoolStatusCard(
                  status: snapshot.schoolStatus!,
                  onViewAll: () => _later(context),
                ),
              if (snapshot.ratios.isNotEmpty) RatioCard(rows: snapshot.ratios),
              if (snapshot.shifts.isNotEmpty) ShiftsCard(rows: snapshot.shifts),
              AvailabilityCard(
                placesFilled: snapshot.placesFilled,
                capacity: snapshot.capacity,
                movesToApprove: snapshot.movesToApprove,
                onOpenAvailability: () => _later(context),
                onOpenMovements: () => _later(context),
              ),
              if (snapshot.billing != null)
                BillingCard(
                  summary: snapshot.billing!,
                  onChangeRange: () => _later(context),
                  onOpenUnpaid: () => _later(context),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// A module the dashboard points at that has not been rebuilt yet says so
  /// rather than pushing a route that does not exist.
  static void _later(BuildContext context) =>
      showAppToast(context, AppStrings.comingSoon);
}
