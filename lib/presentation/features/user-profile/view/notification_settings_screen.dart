import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';
import '../widgets/notification_setting_row.dart';

enum UserPersona {
  parent,
  admin,
  staff;

  bool get isParent => this == UserPersona.parent;
  bool get isAdmin  => this == UserPersona.admin;
  bool get isStaff  => this == UserPersona.staff;

  String get label {
    return switch (this) {
      UserPersona.parent => 'Parent',
      UserPersona.admin  => 'Admin',
      UserPersona.staff  => 'Staff',
    };
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, this.persona = UserPersona.staff});
  final UserPersona persona;

  static const String routeName = '/notificationSettings';

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late UserPersona persona;

  static final Map<String, List<bool>> notificationSettings = { // first bool = in-app, second bool = push, third bool = email
    'Receive a message from staff': [true, true, false],
    'Receive a message from parents': [true, true, false],
    'Ratio is breached': [true, true, false],
    'Student is signed‑in / signed‑out (or marked absent)': [true, true, false],
    'Newsletter is received': [true, true,true],
    'Student’s birthday': [true, true, false],
    'Sign‑in alert just after shift start time (if not already done)': [true, true, false],
    'Sign‑out alert just after shift end time (if not already done)': [true, true, false],
    'My schedule when published/updated': [true, true, true],
    'Students – Immunization (not added, upcoming, expiry/overdue)': [true, true, true],
    'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)': [true, true,true],
    'Students & Staff – Documents (expiry/overdue)': [true, true, true],
    'Students & Staff – Other details (not added, edits)' : [true, true, true],
    'Payment refunded / Failed' : [true, true, true],
    'Upcoming student starting the school' : [true, true, true],
    'Upcoming room movements' : [true, true, true],
    'Overdue room movements' : [true, true, true],
    'Classroom shifts/schedule needs attention' : [true, true, true],
    'Today’s attendance is not marked for Students & Staff' : [false, false, true],
    'Incident is approved/rejected/acknowledged' : [true, true, true],

  };

  @override
  void initState(){
    super.initState();
    persona = widget.persona;
  }

  void _updateSetting(String key, int index, bool? value) {
    if (value == null) return;
    setState(() {
      notificationSettings[key]![index] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true,),
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
                        const SizedBox(height: 16,),
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
                          padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB1AFE9).withOpacity(0.102),
                                  borderRadius: BorderRadius.vertical(top : Radius.circular(10)),
                                  border: Border(
                                    bottom: BorderSide(
                                      color:Color(0xFFE9ECEF),
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
                                inAppValue: notificationSettings['Receive a message from staff']![0],
                                emailValue: notificationSettings['Receive a message from staff']![1],
                                pushValue: notificationSettings['Receive a message from staff']![2],
                                onInAppChanged: (v) => _updateSetting('Receive a message from staff', 0, v),
                                onEmailChanged: (v) => _updateSetting('Receive a message from staff', 1, v),
                                onPushChanged: (v) => _updateSetting('Receive a message from staff', 2, v),
                              ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Receive a message from parents',
                                  inAppValue: notificationSettings['Receive a message from parents']![0],
                                  emailValue: notificationSettings['Receive a message from parents']![1],
                                  pushValue: notificationSettings['Receive a message from parents']![2],
                                  onInAppChanged: (v) => _updateSetting('Receive a message from parents', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Receive a message from parents', 1, v),
                                  onPushChanged: (v) => _updateSetting('Receive a message from parents', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Ratio is breached',
                                  inAppValue: notificationSettings['Ratio is breached']![0],
                                  emailValue: notificationSettings['Ratio is breached']![1],
                                  pushValue: notificationSettings['Ratio is breached']![2],
                                  onInAppChanged: (v) => _updateSetting('Ratio is breached', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Ratio is breached', 1, v),
                                  onPushChanged: (v) => _updateSetting('Ratio is breached', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Student is signed‑in / signed‑out (or marked absent)',
                                  inAppValue: notificationSettings['Student is signed‑in / signed‑out (or marked absent)']![0],
                                  emailValue: notificationSettings['Student is signed‑in / signed‑out (or marked absent)']![1],
                                  pushValue: notificationSettings['Student is signed‑in / signed‑out (or marked absent)']![2],
                                  onInAppChanged: (v) => _updateSetting('Student is signed‑in / signed‑out (or marked absent)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Student is signed‑in / signed‑out (or marked absent)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Student is signed‑in / signed‑out (or marked absent)', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Newsletter is received',
                                  inAppValue: notificationSettings['Newsletter is received']![0],
                                  emailValue: notificationSettings['Newsletter is received']![1],
                                  pushValue: notificationSettings['Newsletter is received']![2],
                                  onInAppChanged: (v) => _updateSetting('Newsletter is received', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Newsletter is received', 1, v),
                                  onPushChanged: (v) => _updateSetting('Newsletter is received', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Student’s birthday',
                                  inAppValue: notificationSettings['Student’s birthday']![0],
                                  emailValue: notificationSettings['Student’s birthday']![1],
                                  pushValue: notificationSettings['Student’s birthday']![2],
                                  onInAppChanged: (v) => _updateSetting('Student’s birthday', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Student’s birthday', 1, v),
                                  onPushChanged: (v) => _updateSetting('Student’s birthday', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Sign‑in alert just after shift start time (if not already done)',
                                  inAppValue: notificationSettings['Sign‑in alert just after shift start time (if not already done)']![0],
                                  emailValue: notificationSettings['Sign‑in alert just after shift start time (if not already done)']![1],
                                  pushValue: notificationSettings['Sign‑in alert just after shift start time (if not already done)']![2],
                                  onInAppChanged: (v) => _updateSetting('Sign‑in alert just after shift start time (if not already done)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Sign‑in alert just after shift start time (if not already done)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Sign‑in alert just after shift start time (if not already done)', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'Sign‑out alert just after shift end time (if not already done)',
                                  inAppValue: notificationSettings['Sign‑out alert just after shift end time (if not already done)']![0],
                                  emailValue: notificationSettings['Sign‑out alert just after shift end time (if not already done)']![1],
                                  pushValue: notificationSettings['Sign‑out alert just after shift end time (if not already done)']![2],
                                  onInAppChanged: (v) => _updateSetting('Sign‑out alert just after shift end time (if not already done)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Sign‑out alert just after shift end time (if not already done)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Sign‑out alert just after shift end time (if not already done)', 2, v),
                                ),
                              if(!persona.isParent)
                                NotificationSettingRow(
                                  title: 'My schedule when published/updated',
                                  inAppValue: notificationSettings['My schedule when published/updated']![0],
                                  emailValue: notificationSettings['My schedule when published/updated']![1],
                                  pushValue: notificationSettings['My schedule when published/updated']![2],
                                  onInAppChanged: (v) => _updateSetting('My schedule when published/updated', 0, v),
                                  onEmailChanged: (v) => _updateSetting('My schedule when published/updated', 1, v),
                                  onPushChanged: (v) => _updateSetting('My schedule when published/updated', 2, v),
                                ),
                              // extended settings for admin only
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Students – Immunization (not added, upcoming, expiry/overdue)',
                                  inAppValue: notificationSettings['Students – Immunization (not added, upcoming, expiry/overdue)']![0],
                                  emailValue: notificationSettings['Students – Immunization (not added, upcoming, expiry/overdue)']![1],
                                  pushValue: notificationSettings['Students – Immunization (not added, upcoming, expiry/overdue)']![2],
                                  onInAppChanged: (v) => _updateSetting('Students – Immunization (not added, upcoming, expiry/overdue)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Students – Immunization (not added, upcoming, expiry/overdue)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Students – Immunization (not added, upcoming, expiry/overdue)', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
                                  inAppValue: notificationSettings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![0],
                                  emailValue: notificationSettings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![1],
                                  pushValue: notificationSettings['Students & Staff – Physical examination (not added, upcoming, expiry/overdue)']![2],
                                  onInAppChanged: (v) => _updateSetting('Students & Staff – Physical examination (not added, upcoming, expiry/overdue)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Students & Staff – Physical examination (not added, upcoming, expiry/overdue)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Students & Staff – Physical examination (not added, upcoming, expiry/overdue)', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Students & Staff – Documents (expiry/overdue)',
                                  inAppValue: notificationSettings['Students & Staff – Documents (expiry/overdue)']![0],
                                  emailValue: notificationSettings['Students & Staff – Documents (expiry/overdue)']![1],
                                  pushValue: notificationSettings['Students & Staff – Documents (expiry/overdue)']![2],
                                  onInAppChanged: (v) => _updateSetting('Students & Staff – Documents (expiry/overdue)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Students & Staff – Documents (expiry/overdue)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Students & Staff – Documents (expiry/overdue)', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Students & Staff – Other details (not added, edits)',
                                  inAppValue: notificationSettings['Students & Staff – Other details (not added, edits)']![0],
                                  emailValue: notificationSettings['Students & Staff – Other details (not added, edits)']![1],
                                  pushValue: notificationSettings['Students & Staff – Other details (not added, edits)']![2],
                                  onInAppChanged: (v) => _updateSetting('Students & Staff – Other details (not added, edits)', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Students & Staff – Other details (not added, edits)', 1, v),
                                  onPushChanged: (v) => _updateSetting('Students & Staff – Other details (not added, edits)', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Payment refunded / Failed',
                                  inAppValue: notificationSettings['Payment refunded / Failed']![0],
                                  emailValue: notificationSettings['Payment refunded / Failed']![1],
                                  pushValue: notificationSettings['Payment refunded / Failed']![2],
                                  onInAppChanged: (v) => _updateSetting('Payment refunded / Failed', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Payment refunded / Failed', 1, v),
                                  onPushChanged: (v) => _updateSetting('Payment refunded / Failed', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Upcoming student starting the school',
                                  inAppValue: notificationSettings['Upcoming student starting the school']![0],
                                  emailValue: notificationSettings['Upcoming student starting the school']![1],
                                  pushValue: notificationSettings['Upcoming student starting the school']![2],
                                  onInAppChanged: (v) => _updateSetting('Upcoming student starting the school', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Upcoming student starting the school', 1, v),
                                  onPushChanged: (v) => _updateSetting('Upcoming student starting the school', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Upcoming room movements',
                                  inAppValue: notificationSettings['Upcoming room movements']![0],
                                  emailValue: notificationSettings['Upcoming room movements']![1],
                                  pushValue: notificationSettings['Upcoming room movements']![2],
                                  onInAppChanged: (v) => _updateSetting('Upcoming room movements', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Upcoming room movements', 1, v),
                                  onPushChanged: (v) => _updateSetting('Upcoming room movements', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Overdue room movements',
                                  inAppValue: notificationSettings['Overdue room movements']![0],
                                  emailValue: notificationSettings['Overdue room movements']![1],
                                  pushValue: notificationSettings['Overdue room movements']![2],
                                  onInAppChanged: (v) => _updateSetting('Overdue room movements', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Overdue room movements', 1, v),
                                  onPushChanged: (v) => _updateSetting('Overdue room movements', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Classroom shifts/schedule needs attention',
                                  inAppValue: notificationSettings['Classroom shifts/schedule needs attention']![0],
                                  emailValue: notificationSettings['Classroom shifts/schedule needs attention']![1],
                                  pushValue: notificationSettings['Classroom shifts/schedule needs attention']![2],
                                  onInAppChanged: (v) => _updateSetting('Classroom shifts/schedule needs attention', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Classroom shifts/schedule needs attention', 1, v),
                                  onPushChanged: (v) => _updateSetting('Classroom shifts/schedule needs attention', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Today’s attendance is not marked for Students & Staff',
                                  inAppValue: notificationSettings['Today’s attendance is not marked for Students & Staff']![0],
                                  emailValue: notificationSettings['Today’s attendance is not marked for Students & Staff']![1],
                                  pushValue: notificationSettings['Today’s attendance is not marked for Students & Staff']![2],
                                  onInAppChanged: (v) => _updateSetting('Today’s attendance is not marked for Students & Staff', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Today’s attendance is not marked for Students & Staff', 1, v),
                                  onPushChanged: (v) => _updateSetting('Today’s attendance is not marked for Students & Staff', 2, v),
                                ),
                              if(persona.isAdmin)
                                NotificationSettingRow(
                                  title: 'Incident is approved/rejected/acknowledged',
                                  inAppValue: notificationSettings['Incident is approved/rejected/acknowledged']![0],
                                  emailValue: notificationSettings['Incident is approved/rejected/acknowledged']![1],
                                  pushValue: notificationSettings['Incident is approved/rejected/acknowledged']![2],
                                  onInAppChanged: (v) => _updateSetting('Incident is approved/rejected/acknowledged', 0, v),
                                  onEmailChanged: (v) => _updateSetting('Incident is approved/rejected/acknowledged', 1, v),
                                  onPushChanged: (v) => _updateSetting('Incident is approved/rejected/acknowledged', 2, v),
                                ),

                              // settings for parents only

                              // Container(
                              //   //height: 48,
                              //   width: double.infinity,
                              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              //   decoration: BoxDecoration(
                              //     //color: const Color(0xFFB1AFE9).withOpacity(0.102),
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
                              //                 value: notificationSettings['Receive a message from staff']![0],
                              //                 borderColor: AppColors.themeColor,
                              //                 onChanged: (v) {
                              //                   final newVal = v ?? false;
                              //                   setState(() {
                              //                     notificationSettings['Receive a message from staff']![0] = newVal;
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
                              //                 value: notificationSettings['Receive a message from staff']![1],
                              //                 borderColor: AppColors.themeColor,
                              //                 onChanged: (v) {
                              //                   final newVal = v ?? false;
                              //                   setState(() {
                              //                     notificationSettings['Receive a message from staff']![1] = newVal;
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
                              //                 value: notificationSettings['Receive a message from staff']![2],
                              //                 borderColor: AppColors.themeColor,
                              //                 onChanged: (v) {
                              //                   final newVal = v ?? false;
                              //                   setState(() {
                              //                     notificationSettings['Receive a message from staff']![2] = newVal;
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
                  )
              )
            ],
          )
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
            color: Colors.black.withOpacity(0.05),
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
                onPressed: (){},
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
