import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/core/widgets/loading_state.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/features/profile/cubit/notification_settings_cubit.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/preference_notes.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/preference_table.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// 13e. Ten groups, three channels, and no Save key: a tick is the save.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionCubit>().state.user?.id ?? '';

    return BlocProvider<NotificationSettingsCubit>(
      create: (_) {
        final cubit = redesignLocator<NotificationSettingsCubit>(
          param1: userId,
        );
        unawaited(cubit.load());
        return cubit;
      },
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (previous, current) =>
            previous.hasSaveFailed != current.hasSaveFailed,
        listener: (context, state) {
          if (!state.hasSaveFailed) return;
          showAppToast(
            context,
            ProfileStrings.preferenceSaveFailed,
            tone: ToastTone.error,
          );
          context.read<NotificationSettingsCubit>().clearFailure();
        },
        builder: (context, state) {
          final cubit = context.read<NotificationSettingsCubit>();

          return ScreenScaffold(
            header: const AppHeaderBar.dashboard(
              title: ProfileStrings.notificationSettings,
              subline: ProfileStrings.notificationSettingsSubline,
              leading: BackKey(),
            ),
            scrollable: !state.isLoading && !state.isFailed && !state.isEmpty,
            body: _body(state, cubit),
          );
        },
      );

  /// The four answers the same fetch can give: still going, gone wrong, a
  /// school with no groups set up, and the table.
  Widget _body(
    NotificationSettingsState state,
    NotificationSettingsCubit cubit,
  ) {
    if (state.isLoading) {
      return const LoadingState(label: ProfileStrings.loadingPreferences);
    }
    if (state.isFailed) {
      return Center(child: ErrorState(onRetry: () => unawaited(cubit.load())));
    }
    if (state.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: AppIcons.bell,
          title: ProfileStrings.noPreferences,
          subtitle: ProfileStrings.noPreferencesBody,
        ),
      );
    }
    return _Table(state: state);
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.state});

  final NotificationSettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationSettingsCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PreferenceTable(
          categories: state.categories,
          isSaving: state.isSaving,
          onToggle: (groupCode, channel) =>
              unawaited(cubit.toggleChannel(groupCode, channel)),
        ),
        const Padding(
          padding: ProfileSizes.prefNotesPad,
          child: PreferenceNotes(),
        ),
      ],
    );
  }
}
