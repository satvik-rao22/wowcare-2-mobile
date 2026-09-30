import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/notification_preference_groups_cubit.dart';
import 'package:wowcare/presentation/features/user_profile/widgets/notification_preference_category_header.dart';
import 'package:wowcare/presentation/features/user_profile/widgets/notification_preference_group_row.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

// The cubit is owned by the ancestor BlocProvider set up in the router's
// GoRoute builder (which also kicks off .load()), and every read of it below
// goes through context.read — nothing here needs State at all.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const String routeName = '/dashboard/notificationSettings';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationPreferenceGroupsCubit,
        NotificationPreferenceGroupsState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: state.errorMessage ?? 'Something went wrong',
          isError: true,
        );
      },
      builder: (context, state) => _NotificationSettingsContent(state: state),
    );
  }
}

/// Extracted from a `_buildContent()` method into a private widget class
/// (Mandate 6) — it only needs [state] and [context].
class _NotificationSettingsContent extends StatelessWidget {
  const _NotificationSettingsContent({required this.state});

  final NotificationPreferenceGroupsState state;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackgroundColor,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppColors.pageBackgroundColor),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Notification Settings',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.userProfileTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                      Container(
                        width: responsive.containerWidth,
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        padding: EdgeInsets.all(
                          responsive.isTablet ? 32.0 : 16.0,
                        ),
                        decoration: AppSurfaces.card(borderRadius: BorderRadius.all( Radius.circular(responsive.isTablet ? 30.0 : 20.0), )),
                        child: _NotificationBody(state: state),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Extracted from a `_buildBody()` method. Reads the cubit via `context.read`
/// (already provided by the ancestor BlocProvider set up in the router)
/// rather than a captured State field, so it doesn't need State either.
class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.state});

  final NotificationPreferenceGroupsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.groups.isEmpty && state.errorMessage != null) {
      return AppErrorState(
        title: state.errorMessage!,
        onRetry: () => context.read<NotificationPreferenceGroupsCubit>().load(),
      );
    }

    if (state.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text(
              'No notification preferences available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  context.read<NotificationPreferenceGroupsCubit>().load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    String? lastCategory;
    for (final group in state.groups) {
      final label = group.categoryLabel;
      if (label != lastCategory) {
        // A category with neither a name nor a code gets no header at all,
        // rather than an empty band of padding above its rows.
        if (label.isNotEmpty) {
          rows.add(NotificationPreferenceCategoryHeader(categoryLabel: label));
        }
        lastCategory = label;
      }
      rows.add(
        NotificationPreferenceGroupRow(
          group: group,
          isSaving: state.savingGroupCodes.contains(group.groupCode),
          onChannelChanged: (channel, value) => context
              .read<NotificationPreferenceGroupsCubit>()
              .toggleChannel(group.groupCode, channel, value),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.userProfileSoftPurpleColor.withValues(alpha: 0.102),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: const Border(
              bottom: BorderSide(color: AppColors.userProfileDividerColor, width: 1),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 60, child: Center(child: _HeaderLabel('In-App'))),
              SizedBox(width: 60, child: Center(child: _HeaderLabel('Email'))),
              SizedBox(width: 60, child: Center(child: _HeaderLabel('Push'))),
            ],
          ),
        ),
        ...rows,
      ],
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }
}
