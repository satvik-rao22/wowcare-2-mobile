import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../view_model/notification_settings_cubit.dart';
import '../widgets/notification_setting_row.dart';

enum UserPersona {
  parent,
  admin,
  staff;

  bool get isParent => this == UserPersona.parent;
  bool get isAdmin => this == UserPersona.admin;
  bool get isStaff => this == UserPersona.staff;

  String get label {
    return switch (this) {
      UserPersona.parent => 'Parent',
      UserPersona.admin => 'Admin',
      UserPersona.staff => 'Staff',
    };
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    this.persona = UserPersona.staff,
  });
  final UserPersona persona;

  static const String routeName = '/dashboard/notificationSettings';

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late UserPersona persona;

  @override
  void initState() {
    super.initState();
    persona = widget.persona;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationSettingsCubit(),
      child: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationSettingsState state) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 48,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFB1AFE9,
                                ).withValues(alpha: 0.102),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFE9ECEF),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Text(
                                        'In-App',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  //const SizedBox(width: 10,),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  //const SizedBox(width: 10,),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Text(
                                        'Push',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  //const SizedBox(width: 10,),
                                ],
                              ),
                            ),
                            NotificationSettingRow(
                              title: 'Receive a message from staff',
                              inAppValue: state
                                  .settings['Receive a message from staff']![0],
                              emailValue: state
                                  .settings['Receive a message from staff']![1],
                              pushValue: state
                                  .settings['Receive a message from staff']![2],
                              onInAppChanged: (v) => context
                                  .read<NotificationSettingsCubit>()
                                  .updateSetting(
                                    'Receive a message from staff',
                                    0,
                                    v,
                                  ),
                              onEmailChanged: (v) => context
                                  .read<NotificationSettingsCubit>()
                                  .updateSetting(
                                    'Receive a message from staff',
                                    1,
                                    v,
                                  ),
                              onPushChanged: (v) => context
                                  .read<NotificationSettingsCubit>()
                                  .updateSetting(
                                    'Receive a message from staff',
                                    2,
                                    v,
                                  ),
                            ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title: 'Receive a message from parents',
                                inAppValue: state
                                    .settings['Receive a message from parents']![0],
                                emailValue: state
                                    .settings['Receive a message from parents']![1],
                                pushValue: state
                                    .settings['Receive a message from parents']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Receive a message from parents',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Receive a message from parents',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Receive a message from parents',
                                      2,
                                      v,
                                    ),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title: 'Ratio is breached',
                                inAppValue:
                                    state.settings['Ratio is breached']![0],
                                emailValue:
                                    state.settings['Ratio is breached']![1],
                                pushValue:
                                    state.settings['Ratio is breached']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Ratio is breached', 0, v),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Ratio is breached', 1, v),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Ratio is breached', 2, v),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'Student is signed‑in / signed‑out (or marked absent)',
                                inAppValue: state
                                    .settings['Student is signed‑in / signed‑out (or marked absent)']![0],
                                emailValue: state
                                    .settings['Student is signed‑in / signed‑out (or marked absent)']![1],
                                pushValue: state
                                    .settings['Student is signed‑in / signed‑out (or marked absent)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Student is signed‑in / signed‑out (or marked absent)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Student is signed‑in / signed‑out (or marked absent)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Student is signed‑in / signed‑out (or marked absent)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title: 'Newsletter is received',
                                inAppValue: state
                                    .settings['Newsletter is received']![0],
                                emailValue: state
                                    .settings['Newsletter is received']![1],
                                pushValue: state
                                    .settings['Newsletter is received']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      2,
                                      v,
                                    ),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title: 'Student’s birthday',
                                inAppValue:
                                    state.settings['Student’s birthday']![0],
                                emailValue:
                                    state.settings['Student’s birthday']![1],
                                pushValue:
                                    state.settings['Student’s birthday']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Student’s birthday', 0, v),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Student’s birthday', 1, v),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Student’s birthday', 2, v),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'Sign‑in alert just after shift start time (if not already done)',
                                inAppValue: state
                                    .settings['Sign‑in alert just after shift start time (if not already done)']![0],
                                emailValue: state
                                    .settings['Sign‑in alert just after shift start time (if not already done)']![1],
                                pushValue: state
                                    .settings['Sign‑in alert just after shift start time (if not already done)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after shift start time (if not already done)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after shift start time (if not already done)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after shift start time (if not already done)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'Sign‑out alert just after shift end time (if not already done)',
                                inAppValue: state
                                    .settings['Sign‑out alert just after shift end time (if not already done)']![0],
                                emailValue: state
                                    .settings['Sign‑out alert just after shift end time (if not already done)']![1],
                                pushValue: state
                                    .settings['Sign‑out alert just after shift end time (if not already done)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after shift end time (if not already done)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after shift end time (if not already done)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after shift end time (if not already done)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (!persona.isParent)
                              NotificationSettingRow(
                                title: 'My schedule when published/updated',
                                inAppValue: state
                                    .settings['My schedule when published/updated']![0],
                                emailValue: state
                                    .settings['My schedule when published/updated']![1],
                                pushValue: state
                                    .settings['My schedule when published/updated']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My schedule when published/updated',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My schedule when published/updated',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My schedule when published/updated',
                                      2,
                                      v,
                                    ),
                              ),
                            // extended settings for admin only
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Students – Immunization (not added, upcoming, expiry/overdue)',
                                inAppValue: state
                                    .settings['Students – Immunization (not added, upcoming, expiry/overdue)']![0],
                                emailValue: state
                                    .settings['Students – Immunization (not added, upcoming, expiry/overdue)']![1],
                                pushValue: state
                                    .settings['Students – Immunization (not added, upcoming, expiry/overdue)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students – Immunization (not added, upcoming, expiry/overdue)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students – Immunization (not added, upcoming, expiry/overdue)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students – Immunization (not added, upcoming, expiry/overdue)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
                                inAppValue: state
                                    .settings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![0],
                                emailValue: state
                                    .settings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![1],
                                pushValue: state
                                    .settings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Students & Staff – Documents (expiry/overdue)',
                                inAppValue: state
                                    .settings['Students & Staff – Documents (expiry/overdue)']![0],
                                emailValue: state
                                    .settings['Students & Staff – Documents (expiry/overdue)']![1],
                                pushValue: state
                                    .settings['Students & Staff – Documents (expiry/overdue)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Documents (expiry/overdue)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Documents (expiry/overdue)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Documents (expiry/overdue)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Students & Staff – Other details (not added, edits)',
                                inAppValue: state
                                    .settings['Students & Staff – Other details (not added, edits)']![0],
                                emailValue: state
                                    .settings['Students & Staff – Other details (not added, edits)']![1],
                                pushValue: state
                                    .settings['Students & Staff – Other details (not added, edits)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Other details (not added, edits)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Other details (not added, edits)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Students & Staff – Other details (not added, edits)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title: 'Payment refunded / Failed',
                                inAppValue: state
                                    .settings['Payment refunded / Failed']![0],
                                emailValue: state
                                    .settings['Payment refunded / Failed']![1],
                                pushValue: state
                                    .settings['Payment refunded / Failed']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment refunded / Failed',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment refunded / Failed',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment refunded / Failed',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title: 'Upcoming student starting the school',
                                inAppValue: state
                                    .settings['Upcoming student starting the school']![0],
                                emailValue: state
                                    .settings['Upcoming student starting the school']![1],
                                pushValue: state
                                    .settings['Upcoming student starting the school']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming student starting the school',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming student starting the school',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming student starting the school',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title: 'Upcoming room movements',
                                inAppValue: state
                                    .settings['Upcoming room movements']![0],
                                emailValue: state
                                    .settings['Upcoming room movements']![1],
                                pushValue: state
                                    .settings['Upcoming room movements']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming room movements',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming room movements',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Upcoming room movements',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title: 'Overdue room movements',
                                inAppValue: state
                                    .settings['Overdue room movements']![0],
                                emailValue: state
                                    .settings['Overdue room movements']![1],
                                pushValue: state
                                    .settings['Overdue room movements']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Overdue room movements',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Overdue room movements',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Overdue room movements',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Classroom shifts/schedule needs attention',
                                inAppValue: state
                                    .settings['Classroom shifts/schedule needs attention']![0],
                                emailValue: state
                                    .settings['Classroom shifts/schedule needs attention']![1],
                                pushValue: state
                                    .settings['Classroom shifts/schedule needs attention']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Classroom shifts/schedule needs attention',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Classroom shifts/schedule needs attention',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Classroom shifts/schedule needs attention',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Today’s attendance is not marked for Students & Staff',
                                inAppValue: state
                                    .settings['Today’s attendance is not marked for Students & Staff']![0],
                                emailValue: state
                                    .settings['Today’s attendance is not marked for Students & Staff']![1],
                                pushValue: state
                                    .settings['Today’s attendance is not marked for Students & Staff']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Today’s attendance is not marked for Students & Staff',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Today’s attendance is not marked for Students & Staff',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Today’s attendance is not marked for Students & Staff',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isAdmin)
                              NotificationSettingRow(
                                title:
                                    'Incident is approved/rejected/acknowledged',
                                inAppValue: state
                                    .settings['Incident is approved/rejected/acknowledged']![0],
                                emailValue: state
                                    .settings['Incident is approved/rejected/acknowledged']![1],
                                pushValue: state
                                    .settings['Incident is approved/rejected/acknowledged']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Incident is approved/rejected/acknowledged',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Incident is approved/rejected/acknowledged',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Incident is approved/rejected/acknowledged',
                                      2,
                                      v,
                                    ),
                              ),

                            // settings for parents only
                            if (persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'My child is signed‑in/signed‑out or marked absent',
                                inAppValue: state
                                    .settings['My child is signed‑in/signed‑out or marked absent']![0],
                                emailValue: state
                                    .settings['My child is signed‑in/signed‑out or marked absent']![1],
                                pushValue: state
                                    .settings['My child is signed‑in/signed‑out or marked absent']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child is signed‑in/signed‑out or marked absent',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child is signed‑in/signed‑out or marked absent',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child is signed‑in/signed‑out or marked absent',
                                      2,
                                      v,
                                    ),
                              ),

                            if (persona.isParent)
                              NotificationSettingRow(
                                title: 'Newsletter is received',
                                inAppValue: state
                                    .settings['Newsletter is received']![0],
                                emailValue: state
                                    .settings['Newsletter is received']![1],
                                pushValue: state
                                    .settings['Newsletter is received']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Newsletter is received',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title: 'New activity is recorded for my child',
                                inAppValue: state
                                    .settings['New activity is recorded for my child']![0],
                                emailValue: state
                                    .settings['New activity is recorded for my child']![1],
                                pushValue: state
                                    .settings['New activity is recorded for my child']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'New activity is recorded for my child',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'New activity is recorded for my child',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'New activity is recorded for my child',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title: 'Invoice is received',
                                inAppValue:
                                    state.settings['Invoice is received']![0],
                                emailValue:
                                    state.settings['Invoice is received']![1],
                                pushValue:
                                    state.settings['Invoice is received']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Invoice is received', 0, v),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Invoice is received', 1, v),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting('Invoice is received', 2, v),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title: 'Payment is successful / failed',
                                inAppValue: state
                                    .settings['Payment is successful / failed']![0],
                                emailValue: state
                                    .settings['Payment is successful / failed']![1],
                                pushValue: state
                                    .settings['Payment is successful / failed']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment is successful / failed',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment is successful / failed',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Payment is successful / failed',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title: 'My child’s profile/details are updated',
                                inAppValue: state
                                    .settings['My child’s profile/details are updated']![0],
                                emailValue: state
                                    .settings['My child’s profile/details are updated']![1],
                                pushValue: state
                                    .settings['My child’s profile/details are updated']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child’s profile/details are updated',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child’s profile/details are updated',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'My child’s profile/details are updated',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'Sign‑in alert just after start time (if not already done)',
                                inAppValue: state
                                    .settings['Sign‑in alert just after start time (if not already done)']![0],
                                emailValue: state
                                    .settings['Sign‑in alert just after start time (if not already done)']![1],
                                pushValue: state
                                    .settings['Sign‑in alert just after start time (if not already done)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after start time (if not already done)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after start time (if not already done)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑in alert just after start time (if not already done)',
                                      2,
                                      v,
                                    ),
                              ),
                            if (persona.isParent)
                              NotificationSettingRow(
                                title:
                                    'Sign‑out alert just after end time (if not already done)',
                                inAppValue: state
                                    .settings['Sign‑out alert just after end time (if not already done)']![0],
                                emailValue: state
                                    .settings['Sign‑out alert just after end time (if not already done)']![1],
                                pushValue: state
                                    .settings['Sign‑out alert just after end time (if not already done)']![2],
                                onInAppChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after end time (if not already done)',
                                      0,
                                      v,
                                    ),
                                onEmailChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after end time (if not already done)',
                                      1,
                                      v,
                                    ),
                                onPushChanged: (v) => context
                                    .read<NotificationSettingsCubit>()
                                    .updateSetting(
                                      'Sign‑out alert just after end time (if not already done)',
                                      2,
                                      v,
                                    ),
                              ),

                            // Container(
                            //   //height: 48,
                            //   width: double.infinity,
                            //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            //   decoration: BoxDecoration(
                            //     //color: const Color(0xFFB1AFE9).withValues(alpha:0.102),
                            //     borderRadius: BorderRadius.vertical(top : Radius.circular(10)),
                            //     border: Border(
                            //       bottom: BorderSide(
                            //         color:Color(0xFFE9ECEF),
                            //         width: 1,
                            //       ),
                            //     ),
                            //   ),
                            //   child: Row(
                            //       children: [
                            //       Flexible(
                            //         child: Text(
                            //           'Receive a message from staff',
                            //           style: TextStyle(
                            //           fontFamily: 'Manrope',
                            //           fontSize: 14,
                            //           fontWeight: FontWeight.w600,
                            //           color: AppColors.primaryColor,
                            //           ),
                            //           maxLines: 5,
                            //         ),
                            //       ),
                            //       Row(
                            //         mainAxisAlignment: MainAxisAlignment.end,
                            //         children: [
                            //           SizedBox(
                            //             width: 60,
                            //             child: Center(
                            //               child: CustomCheckbox(
                            //                 value: state.settings['Receive a message from staff']![0],
                            //                 borderColor: AppColors.themeColor,
                            //                 onChanged: (v) {
                            //                   final newVal = v ?? false;
                            //                   setState(() {
                            //                     state.settings['Receive a message from staff']![0] = newVal;
                            //                   });
                            //
                            //                 },
                            //               ),
                            //             ),
                            //           ),
                            //           //const SizedBox(width: 12,),
                            //           SizedBox(
                            //             width: 60,
                            //             child: Center(
                            //               child: CustomCheckbox(
                            //                 value: state.settings['Receive a message from staff']![1],
                            //                 borderColor: AppColors.themeColor,
                            //                 onChanged: (v) {
                            //                   final newVal = v ?? false;
                            //                   setState(() {
                            //                     state.settings['Receive a message from staff']![1] = newVal;
                            //                   });
                            //
                            //                 },
                            //               ),
                            //             ),
                            //           ),
                            //           //const SizedBox(width: 12,),
                            //           SizedBox(
                            //             width: 60,
                            //             child: Center(
                            //               child: CustomCheckbox(
                            //                 value: state.settings['Receive a message from staff']![2],
                            //                 borderColor: AppColors.themeColor,
                            //                 onChanged: (v) {
                            //                   final newVal = v ?? false;
                            //                   setState(() {
                            //                     state.settings['Receive a message from staff']![2] = newVal;
                            //                   });
                            //
                            //                 },
                            //               ),
                            //             ),
                            //           ),
                            //           //const SizedBox(width: 12,),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: Container(
                  //alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.buildPrimaryGradient().createShader(
                          bounds,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(overlayColor: Colors.transparent),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
