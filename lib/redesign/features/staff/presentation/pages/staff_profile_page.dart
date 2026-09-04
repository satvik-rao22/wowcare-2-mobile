import 'dart:async' show unawaited;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/add_document_sheet.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/attendance_tab.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/dates_tab.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/documents_tab.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/profile_tab.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/schedule_tab.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_profile_header.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/staff_tabs.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c. One staff record, with every tab the frame shows.
///
/// The Sign-In PIN is on the Profile tab, read only. It is never called a
/// Kiosk PIN and there is nothing here that resets it: the PIN endpoint is a
/// read, so resetting one from the app is on the module's costly list.
class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({required this.staffId, super.key});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;
    final lens = StaffLens(
      persona: session.persona,
      viewerId: session.user?.id ?? '',
      viewerClassroom: session.user?.classroomName,
    );

    return BlocProvider<StaffProfileCubit>(
      create: (_) {
        final cubit = redesignLocator<StaffProfileCubit>(
          param1: staffId,
          param2: lens,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _StaffProfileView(),
    );
  }
}

class _StaffProfileView extends StatelessWidget {
  const _StaffProfileView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffProfileCubit>();

    return BlocBuilder<StaffProfileCubit, StaffProfileState>(
      builder: (context, state) {
        final profile = state.profile;

        if (state.isLoading) {
          return const ScreenScaffold(
            body: LoadingState(label: StaffStrings.loadingStaff),
          );
        }
        if (profile == null) {
          return ScreenScaffold(
            body: Center(
              child: ErrorState(
                title: StaffStrings.couldNotReachTitle,
                message: StaffStrings.couldNotReachBody,
                onRetry: () => unawaited(cubit.load()),
              ),
            ),
          );
        }

        return ScreenScaffold(
          header: Column(
            children: <Widget>[
              StaffProfileHeader(member: profile.member),
              StaffTabs(
                tabs: state.tabs,
                selected: state.tab,
                onChanged: cubit.selectTab,
              ),
            ],
          ),
          bottomBar: _ActionBar(member: profile.member),
          scrollable: true,
          onRefresh: cubit.refresh,
          body: _tab(context, state, profile),
        );
      },
    );
  }

  Widget _tab(
    BuildContext context,
    StaffProfileState state,
    StaffProfile profile,
  ) => switch (state.tab) {
    StaffProfileTab.profile => ProfileTab(
      profile: profile,
      showDetails: state.seesDetails,
      onEdit: state.canEdit
          ? () => unawaited(_edit(context, profile.id))
          : null,
    ),
    StaffProfileTab.schedule => ScheduleTab(
      profile: profile,
      onEdit: state.canEditSchedule
          ? () => unawaited(_editSchedule(context, profile.id))
          : null,
    ),
    StaffProfileTab.attendance => AttendanceTab(profile: profile),
    StaffProfileTab.dates => DatesTab(profile: profile),
    StaffProfileTab.documents => DocumentsTab(
      profile: profile,
      onAdd: state.canEdit ? () => unawaited(_addDocument(context)) : null,
    ),
  };

  Future<void> _edit(BuildContext context, String staffId) async {
    final cubit = context.read<StaffProfileCubit>();
    final saved = await context.push<StaffProfile>(
      AppRoutes.editStaffMember(staffId),
    );
    if (saved != null) cubit.applySaved(saved);
  }

  Future<void> _editSchedule(BuildContext context, String staffId) async {
    final cubit = context.read<StaffProfileCubit>();
    await context.push<void>(AppRoutes.staffSchedule(staffId));
    await cubit.refresh();
  }

  Future<void> _addDocument(BuildContext context) async {
    final cubit = context.read<StaffProfileCubit>();
    final document = await AddDocumentSheet.show(context);
    if (document == null) return;
    await cubit.addDocument(name: document.name, type: document.type);
    if (context.mounted) {
      showAppToast(context, StaffStrings.documentAdded);
    }
  }
}

/// The two keys docked under the record: call them, or message them. Message
/// is the pink one, because calling leaves the app and messaging does not.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    // The bottom slot hands its child a loose height as tall as the screen,
    // and a key centres its face with an `Align`, which would take all of it.
    // `IntrinsicHeight` holds the row to the height its keys actually need.
    return IntrinsicHeight(
      child: Container(
        padding: StaffSizes.dockedBarPad.copyWith(
          bottom: StaffSizes.dockedBarPad.bottom + context.safeArea.bottom,
        ),
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.barLine)),
        ),
        child: Row(
          spacing: AppSizes.keyGap,
          children: <Widget>[
            Expanded(
              child: _QuietKey(
                label: StaffStrings.callName(member.firstName),
                onTap: () => showAppToast(
                  context,
                  StaffStrings.callName(member.firstName),
                ),
              ),
            ),
            Expanded(
              child: _PinkKey(
                label: StaffStrings.message,
                onTap: () => unawaited(context.push(AppRoutes.composeMessage)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietKey extends StatelessWidget {
  const _QuietKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.keySecondary(c),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.dockedKey.copyWith(color: c.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _PinkKey extends StatelessWidget {
  const _PinkKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyPrimary(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.dockedKey.copyWith(color: c.onPink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
