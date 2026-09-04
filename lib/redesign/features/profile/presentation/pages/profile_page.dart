import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/offline_banner.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/guardian_children_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_actions_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_detail_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_failed_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_hero_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_note.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_photo_sheet.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/value_field.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/work_schedule_card.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// 13a, 13c and 13f. The signed-in person's own record.
///
/// One screen for both lenses. A school-side person gets the work schedule and
/// the roles their account holds here; a guardian gets their children and the
/// note explaining why there is nothing else. Which one is drawn comes off
/// `SessionCubit`, never off the route.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionCubit>().state;

    return BlocProvider<ProfileCubit>(
      create: (_) {
        final cubit = redesignLocator<ProfileCubit>(
          param1: session.user?.id ?? '',
          param2: session.persona,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.hasPhotoChanged != current.hasPhotoChanged ||
            previous.hasPhotoRemoved != current.hasPhotoRemoved,
        listener: (context, state) {
          if (!state.hasPhotoChanged && !state.hasPhotoRemoved) return;
          showAppToast(
            context,
            state.hasPhotoRemoved
                ? ProfileStrings.photoRemoved
                : ProfileStrings.photoUpdated,
          );
          context.read<ProfileCubit>().clearPhotoNotice();
        },
        builder: (context, state) {
          final cubit = context.read<ProfileCubit>();

          return ScreenScaffold(
            header: AppHeaderBar(
              title: state.isGuardianLens
                  ? ProfileStrings.me
                  : ProfileStrings.myProfile,
              isDetail: true,
              leading: const BackKey(),
              actions: <Widget>[
                if (state.hasBody)
                  PrimaryKey(
                    label: AppStrings.edit,
                    expand: false,
                    padding: ProfileSizes.smallKeyPad,
                    onTap: () => unawaited(context.push(AppRoutes.editProfile)),
                  ),
              ],
            ),
            scrollable: true,
            onRefresh: cubit.refresh,
            body: switch (state.status) {
              ProfileStatus.loading => const ProfileSkeleton(),
              ProfileStatus.failed => _FailedBody(onRetry: cubit.load),
              _ => _Body(state: state),
            },
          );
        },
      );
}

/// Everything 13a and 13c stack once the record is in hand.
class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final record = state.record!;
    final schedule = state.workSchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ProfileSizes.cardGap,
      children: <Widget>[
        if (state.isOffline)
          const OfflineBanner(message: ProfileStrings.offlineBanner),
        ProfileHeroCard(
          state: state,
          onChangePhoto: () => unawaited(_changePhoto(context)),
          onRetryPhoto: cubit.clearPhotoFailure,
        ),
        if (state.isGuardianLens && state.children.isNotEmpty)
          GuardianChildrenCard(
            children: state.children,
            onOpen: (child) =>
                unawaited(context.push(AppRoutes.student(child.id))),
          ),
        ProfileDetailCard(record: record),
        if (schedule != null)
          WorkScheduleCard(
            schedule: schedule,
            canEdit: state.canEditSchedule,
            // The schedule editor is M06's screen and is not built yet.
            onEdit: () => showAppToast(context, AppStrings.comingSoon),
          ),
        ProfileActionsCard(
          pinLabel: state.pinLabel,
          isPinVisible: state.isPinVisible,
          canHidePin: !state.isGuardianLens,
          onTogglePin: cubit.togglePin,
          onNotificationSettings: () =>
              unawaited(context.push(AppRoutes.notificationSettings)),
          onChangePassword: () =>
              unawaited(context.push(AppRoutes.changePassword)),
        ),
        if (state.isGuardianLens)
          const ProfileNote(text: ProfileStrings.guardianNote),
        if (state.isOffline)
          const ProfileNote(text: ProfileStrings.offlineNote),
        if (state.build != null)
          ProfileNote(
            text: ProfileStrings.versionLine(
              state.build!.version,
              state.build!.build,
            ),
          ),
      ],
    );
  }

  Future<void> _changePhoto(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final choice = await showProfilePhotoSheet(
      context,
      hasPhoto: state.record?.hasPhoto ?? false,
    );

    switch (choice) {
      case PhotoChoice.choose:
        await cubit.uploadPhoto();
      case PhotoChoice.remove:
        await cubit.removePhoto();
      case null:
        break;
    }
  }
}

/// 13f's failed state: the card that says what went missing, and the little
/// that sign-in already knew, so the screen is never blank.
class _FailedBody extends StatelessWidget {
  const _FailedBody({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionCubit>().state.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ProfileSizes.cardGap,
      children: <Widget>[
        ProfileFailedCard(onRetry: () => unawaited(onRetry())),
        AppCard(
          padding: ProfileSizes.detailCardPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ProfileSizes.detailGap,
            children: <Widget>[
              ValueField(
                label: ProfileStrings.name,
                value: user?.fullName ?? '',
              ),
              ValueField(
                label: ProfileStrings.email,
                value: user?.email ?? '',
                isLocked: true,
                showLockTag: true,
              ),
              const ValueField(
                label: ProfileStrings.phoneNumber,
                value: '',
                isLocked: true,
              ),
              const ValueField(
                label: ProfileStrings.address,
                value: '',
                isLocked: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
