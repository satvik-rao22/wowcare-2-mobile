import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../view_model/notification_preference_groups_cubit.dart';
import '../widgets/notification_preference_category_header.dart';
import '../widgets/notification_preference_group_row.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  static const String routeName = '/dashboard/notificationSettings';

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationPreferenceGroupsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<NotificationPreferenceGroupsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationPreferenceGroupsCubit>.value(
      value: _cubit,
      child:
          BlocConsumer<
            NotificationPreferenceGroupsCubit,
            NotificationPreferenceGroupsState
          >(
            listenWhen: (prev, curr) =>
                prev.errorMessage != curr.errorMessage &&
                curr.errorMessage != null,
            listener: (context, state) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: state.errorMessage ?? 'Something went wrong',
                isError: true,
              );
            },
            builder: (context, state) => _buildContent(context, state),
          ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationPreferenceGroupsState state,
  ) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
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
                              fontFamily: 'Manrope',
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff573353),
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
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildBody(context, state),
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

  Widget _buildBody(
    BuildContext context,
    NotificationPreferenceGroupsState state,
  ) {
    if (state.isLoading && state.groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              state.errorMessage ?? 'No notification preferences available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _cubit.load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    String? lastCategory;
    for (final group in state.groups) {
      if (group.categoryName != lastCategory) {
        rows.add(
          NotificationPreferenceCategoryHeader(
            categoryName: group.categoryName,
          ),
        );
        lastCategory = group.categoryName;
      }
      rows.add(
        NotificationPreferenceGroupRow(
          group: group,
          isSaving: state.savingGroupCodes.contains(group.groupCode),
          onChannelChanged: (channel, value) =>
              _cubit.toggleChannel(group.groupCode, channel, value),
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
            color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
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
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
      ),
    );
  }
}
