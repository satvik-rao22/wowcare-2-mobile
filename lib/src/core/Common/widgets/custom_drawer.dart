// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import 'package:schoolerp/core/common/widgets/reusable_log_out_model_sheet.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/src/activity/presentation/views/activity_screen.dart';
// import 'package:schoolerp/src/attendance/presentation/widgets/attendance_popup.dart';
// import 'package:schoolerp/src/classroom/presentation/views/screens/classroom_screen.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/communication_screen.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/messaging_tabs/messaging_tab.dart';
// // Import the persona-specific dashboards
// import 'package:schoolerp/src/dashboard/presentation/views/admin_dashboard.dart';
// import 'package:schoolerp/src/dashboard/presentation/views/parent_dashboard.dart';
// import 'package:schoolerp/src/dashboard/presentation/views/staff_dashboard.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:schoolerp/src/staff/presentation/views/screens/all_staff_screen.dart';
// import 'package:schoolerp/src/student/presentation/views/all_students_screen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:schoolerp/src/guardian_profile/guardian_activity_screen.dart';
// import 'package:schoolerp/src/communication/presentation/student_messaging/student_conversation_screen.dart';
// import 'package:schoolerp/src/billing/presentation/screen/admin_billing_screen.dart';
// import 'package:schoolerp/src/billing/presentation/screen/recurring_plans_screen.dart';
// import 'package:schoolerp/src/billing/presentation/screen/transactions_screen.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/attendance_tabbed_view.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/staff_attendance_tabbed_view.dart';

// class CustomDrawer extends StatefulWidget {
//   const CustomDrawer({super.key});

//   @override
//   State<CustomDrawer> createState() => _CustomDrawerState();
// }

// class _CustomDrawerState extends State<CustomDrawer> {
//   // --- FIX: List of all possible "home" dashboard routes ---

//   static const List<String> dashboardRoutes = [
//     AdminDashboard.routeName,
//     StaffDashboard.routeName,
//     ParentDashboard.routeName,
//   ];

//   static bool isDashboardRoute(String? route) {
//     return dashboardRoutes.contains(route);
//   }

//   // ... (buildHeader method is unchanged)
//   Widget _buildHeader(BuildContext context, DocumentState state) {
//     return SafeArea(
//       bottom: false,
//       child: Padding(
//         padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CircleAvatar(
//               backgroundColor: Colors.white,
//               radius: 28,
//               backgroundImage: AssetImage(MediaRes.logo_wow),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 14),
//                   const Text(
//                     'WowCare',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 19,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             AuthProvider.userSchool.name.isEmpty
//                                 ? ''
//                                 : AuthProvider.userSchool.name,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         if (context.isAdminOrDirector)
//                           const Icon(
//                             Icons.keyboard_arrow_down,
//                             color: Colors.white,
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentRoute = ModalRoute.of(context)?.settings.name;
//     // Debug print to check current route and dashboardRoutes
//     print(
//       'DEBUG: currentRoute = '
//       ' [33m$currentRoute [0m, dashboardRoutes = $dashboardRoutes',
//     );

//     return Drawer(
//       width: context.width * 2 / 3,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         decoration: BoxDecoration(gradient: AppColors.buildPrimaryGradient()),
//         child: Column(
//           children: [
//             BlocConsumer<DocumentBloc, DocumentState>(
//               listener: (context, state) {
//                 if (state is DocumentError) {
//                   CoreUtils.showTopSnackBar(
//                     context: context,
//                     isError: true,
//                     isWarning: false,
//                     isSuccess: false,
//                     isAdjust: false,
//                     message: state.message,
//                   );
//                 }
//               },
//               builder: (context, state) {
//                 return _buildHeader(context, state);
//               },
//             ),
//             const Divider(
//               color: Colors.white,
//               thickness: 0.3,
//               indent: 8,
//               endIndent: 8,
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 4),
//                   child: Column(
//                     children: [
//                       // Dashboard (always present, but routes differ)
//                       _CustomExpansionTile(
//                         title: 'Dashboard',
//                         icon: MediaRes.dashboardIcon,
//                         isCurrentRoute: isDashboardRoute(currentRoute),
//                         isDashboard: true,
//                         onTap: () {
//                           Navigator.pop(context);
//                           if (!isDashboardRoute(currentRoute)) {
//                             Navigator.of(context).popUntil(
//                               (route) =>
//                                   dashboardRoutes.contains(
//                                     route.settings.name,
//                                   ) ||
//                                   route.isFirst,
//                             );
//                           }
//                         },
//                       ),
//                       // Admin/Director/Staff options
//                       if (context.isAdminOrDirector || context.isStaff) ...[
//                         _CustomExpansionTile(
//                           title: 'Classrooms',
//                           icon: MediaRes.classroom_drawer_icon,
//                           routeName: ClassroomScreen.routeName,
//                           isCurrentRoute:
//                               currentRoute == ClassroomScreen.routeName,
//                         ),
//                         if (context.isAdminOrDirector) ...[
//                           _CustomExpansionTile(
//                             title: 'Students',
//                             icon: MediaRes.students_drawer_icon,
//                             routeName: AllStudentsScreen.routeName,
//                             isCurrentRoute:
//                                 currentRoute == AllStudentsScreen.routeName,
//                           ),
//                           _CustomExpansionTile(
//                             title: 'Staff',
//                             icon: MediaRes.staffs_drawer_icon,
//                             isCurrentRoute:
//                                 currentRoute == AllStaffScreen.routeName,
//                             onTap: () {
//                               Navigator.pop(context);
//                               Navigator.pushNamed(
//                                 context,
//                                 AllStaffScreen.routeName,
//                               );
//                             },
//                           ),
//                         ],
//                         _CustomExpansionTile(
//                           title: 'Attendance',
//                           icon: MediaRes.attendanceIcon,
//                           isExpansionEnabled: true,
//                           children: [
//                             DrawerListTile(
//                               title: 'Student Attendance',
//                               leading: SvgPicture.asset(
//                                 MediaRes.studentAttendanceDrawer,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 // For admin users, navigate directly to Student Tabbed View
//                                 if (context.isAdminOrDirector) {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const AttendanceTabbedView(),
//                                     ),
//                                   );
//                                 } else {
//                                   // For other users, show the attendance popup
//                                   AttendancePopupManager.showAttendancePopup(
//                                     context,
//                                   );
//                                 }
//                               },
//                             ),
//                             DrawerListTile(
//                               title: 'Staff Attendance',
//                               leading: SvgPicture.asset(
//                                 MediaRes.staffAttendanceDrawer,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 // For admin users, navigate directly to Staff Tabbed View
//                                 if (context.isAdminOrDirector) {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const StaffAttendanceTabbedView(),
//                                     ),
//                                   );
//                                 } else {
//                                   // For other users, show the attendance popup
//                                   AttendancePopupManager.showAttendancePopup(
//                                     context,
//                                     initialTabIndex: 1,
//                                   );
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                         _CustomExpansionTile(
//                           title: 'Activities',
//                           icon: MediaRes.activitesIcon,
//                           routeName: ActivityScreen.routeName,
//                           isCurrentRoute:
//                               currentRoute == ActivityScreen.routeName,
//                         ),
//                         // Added Billing option for Admin/Director
//                         if (context.isAdminOrDirector)
//                           _CustomExpansionTile(
//                             title: 'Billing',
//                             icon: MediaRes.billing_drawer_icon,
//                             isCurrentRoute:
//                                 false, // You may want to add route check if needed
//                             isExpansionEnabled: true,
//                             children: [
//                               DrawerListTile(
//                                 title: 'Accounting',
//                                 leading: Icon(
//                                   Icons.account_balance_wallet,
//                                   color: AppColors.themeColor,
//                                 ),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const AdminBillingScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                               DrawerListTile(
//                                 title: 'Recurring Plans',
//                                 leading: Icon(
//                                   Icons.repeat,
//                                   color: AppColors.themeColor,
//                                 ),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const RecurringPlansScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                               DrawerListTile(
//                                 title: 'Transactions',
//                                 leading: Icon(
//                                   Icons.swap_horiz,
//                                   color: AppColors.themeColor,
//                                 ),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const TransactionsScreen(),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         _CustomExpansionTile(
//                           title: 'Communication',
//                           icon: MediaRes.communicationIcon,
//                           isExpansionEnabled: true,
//                           isCurrentRoute:
//                               currentRoute == CommunicationScreen.routeName,
//                           children: [
//                             DrawerListTile(
//                               title: 'Staff Messaging',
//                               leading: SvgPicture.asset(
//                                 MediaRes.staffMessaging,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pushNamed(
//                                   context,
//                                   CommunicationScreen.routeName,
//                                   arguments: {
//                                     'initialTabIndex': 0,
//                                     'route': CommunicationScreen.messagingTab,
//                                     'tab': MessagingTab.staffMessagingTab,
//                                   },
//                                 );
//                               },
//                             ),
//                             DrawerListTile(
//                               title: 'Parent Messaging',
//                               leading: SvgPicture.asset(
//                                 MediaRes.parentMessaging,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pushNamed(
//                                   context,
//                                   CommunicationScreen.routeName,
//                                   arguments: {
//                                     'initialTabIndex': 0,
//                                     'route': CommunicationScreen.messagingTab,
//                                     'tab': MessagingTab.parentMessagingTab,
//                                   },
//                                 );
//                               },
//                             ),
//                             DrawerListTile(
//                               title: 'Newsletter',
//                               leading: SvgPicture.asset(
//                                 MediaRes.newsletter,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pushNamed(
//                                   context,
//                                   CommunicationScreen.routeName,
//                                   arguments: {'initialTabIndex': 1},
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                       // Guardian/Parent options
//                       if (context.isGuardian) ...[
//                         _CustomExpansionTile(
//                           title: 'Activities',
//                           icon: MediaRes.activitesIcon,
//                           routeName: GuardianActivityScreen.routeName,
//                           isCurrentRoute:
//                               currentRoute == GuardianActivityScreen.routeName,
//                         ),
//                         _CustomExpansionTile(
//                           title: 'Communication',
//                           icon: MediaRes.communicationIcon,
//                           isExpansionEnabled: true,
//                           isCurrentRoute:
//                               currentRoute ==
//                               StudentConversationScreen.routeName,
//                           children: [
//                             DrawerListTile(
//                               title: 'Messaging',
//                               leading: SvgPicture.asset(
//                                 MediaRes.parentMessaging,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pushNamed(
//                                   context,
//                                   StudentConversationScreen.routeName,
//                                 );
//                               },
//                             ),
//                             DrawerListTile(
//                               title: 'Newsletter',
//                               leading: SvgPicture.asset(
//                                 MediaRes.newsletter,
//                                 colorFilter: const ColorFilter.mode(
//                                   AppColors.themeColor,
//                                   BlendMode.srcIn,
//                                 ),
//                               ),
//                               onTap: () {
//                                 Navigator.pushNamed(
//                                   context,
//                                   CommunicationScreen.routeName,
//                                   arguments: {'initialTabIndex': 1},
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                       // Settings and Logout (always present)
//                       _CustomExpansionTile(
//                         title: 'Settings',
//                         icon: MediaRes.settings_drawer_Blue,
//                         isExpansionEnabled: true,
//                         children: [
//                           DrawerListTile(
//                             title: 'Privacy Policy',
//                             leading: SvgPicture.asset(
//                               MediaRes.settings_drawer_Blue,
//                               colorFilter: const ColorFilter.mode(
//                                 AppColors.themeColor,
//                                 BlendMode.srcIn,
//                               ),
//                             ),
//                             onTap: () async {
//                               const url =
//                                   'https://childcarewow.com/privacy-policy/';
//                               if (await canLaunchUrl(Uri.parse(url))) {
//                                 await launchUrl(Uri.parse(url));
//                               } else {
//                                 await launchUrl(Uri.parse(url));
//                               }
//                             },
//                           ),
//                           DrawerListTile(
//                             title: 'Terms & Conditions',
//                             leading: SvgPicture.asset(
//                               MediaRes.settings_drawer_Blue,
//                               colorFilter: const ColorFilter.mode(
//                                 AppColors.themeColor,
//                                 BlendMode.srcIn,
//                               ),
//                             ),
//                             onTap: () async {
//                               const url =
//                                   'https://childcarewow.com/terms-and-conditions/';
//                               if (await canLaunchUrl(Uri.parse(url))) {
//                                 await launchUrl(Uri.parse(url));
//                               } else {
//                                 await launchUrl(Uri.parse(url));
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                       _CustomExpansionTile(
//                         title: 'Logout',
//                         icon: MediaRes.logout,
//                         onTap: () {
//                           Navigator.pop(context);
//                           showModalBottomSheet(
//                             context: context,
//                             shape: const RoundedRectangleBorder(
//                               borderRadius: BorderRadius.vertical(
//                                 top: Radius.circular(16),
//                               ),
//                             ),
//                             builder: (context) =>
//                                 const LogOutModelBottomSheet(),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const Text(
//               "Version : 1.2.6",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.white),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ... (_CustomExpansionTile and DrawerListTile are unchanged from your original code)
// class _CustomExpansionTile extends StatefulWidget {
//   final String title;
//   final String icon;
//   final List<Widget> children;
//   final bool isExpansionEnabled;
//   final String? routeName;
//   final bool isCurrentRoute;
//   final VoidCallback? onTap;
//   final bool isDashboard; // <-- add this

//   const _CustomExpansionTile({
//     required this.title,
//     required this.icon,
//     this.children = const [],
//     this.isExpansionEnabled = false,
//     this.routeName,
//     this.isCurrentRoute = false,
//     this.onTap,
//     this.isDashboard = false, // <-- add this
//   });

//   @override
//   State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
// }

// class _CustomExpansionTileState extends State<_CustomExpansionTile> {
//   bool _isExpanded = false;

//   void _handleTap() {
//     if (widget.onTap != null) {
//       widget.onTap!();
//       return;
//     }
//     if (!widget.isExpansionEnabled) {
//       if (widget.routeName != null) {
//         Navigator.pop(context);
//         Navigator.pushNamed(context, widget.routeName!);
//       }
//       return;
//     }
//   }

//   Color _getIconColor() {
//     if (widget.isCurrentRoute) {
//       return AppColors.themeColor;
//     }
//     return _isExpanded ? AppColors.themeColor : Colors.white;
//   }

//   Color _getTextColor() {
//     if (widget.isCurrentRoute) {
//       return AppColors.themeColor;
//     }
//     return _isExpanded ? AppColors.themeColor : Colors.white;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _handleTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: widget.isCurrentRoute || _isExpanded
//               ? Colors.white
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             if (widget.isCurrentRoute || _isExpanded)
//               const BoxShadow(
//                 blurRadius: 4,
//                 color: Colors.black26,
//                 offset: Offset(0, 4),
//               ),
//           ],
//         ),
//         child: widget.isExpansionEnabled
//             ? ExpansionTile(
//                 backgroundColor: Colors.white,
//                 collapsedBackgroundColor: Colors.transparent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 collapsedShape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 maintainState: true,
//                 onExpansionChanged: (expanded) {
//                   setState(() {
//                     _isExpanded = expanded;
//                   });
//                 },
//                 leading: SvgPicture.asset(
//                   widget.icon,
//                   colorFilter: ColorFilter.mode(
//                     _getIconColor(),
//                     BlendMode.srcIn,
//                   ),
//                 ),
//                 iconColor: AppColors.themeColor,
//                 collapsedIconColor: Colors.white,
//                 title: Text(
//                   widget.title,
//                   maxLines: 1,
//                   style: TextStyle(color: _getTextColor()),
//                 ),
//                 children: widget.children,
//                 trailing: const Icon(Icons.keyboard_arrow_down),
//               )
//             : ListTile(
//                 leading: SvgPicture.asset(
//                   widget.icon,
//                   colorFilter: ColorFilter.mode(
//                     widget.isCurrentRoute ? AppColors.themeColor : Colors.white,
//                     BlendMode.srcIn,
//                   ),
//                 ),
//                 title: Text(
//                   widget.title,
//                   maxLines: 1,
//                   style: TextStyle(
//                     color: widget.isCurrentRoute
//                         ? AppColors.themeColor
//                         : Colors.white,
//                   ),
//                 ),
//                 tileColor: (widget.isDashboard && widget.isCurrentRoute)
//                     ? Colors.white
//                     : (!widget.isDashboard && widget.isCurrentRoute)
//                     ? Colors.white
//                     : Colors.transparent,
//                 selected: widget.isCurrentRoute,
//                 selectedTileColor: Colors.white,
//               ),
//       ),
//     );
//   }
// }

// class DrawerListTile extends StatelessWidget {
//   final String title;
//   final Widget leading;
//   final VoidCallback onTap;
//   final double horizontalTitleGap;
//   final Color? textColor;

//   const DrawerListTile({
//     super.key,
//     required this.title,
//     required this.leading,
//     required this.onTap,
//     this.horizontalTitleGap = 16,
//     this.textColor = AppColors.themeColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       onTap: onTap,
//       horizontalTitleGap: horizontalTitleGap,
//       leading: leading,
//       title: Text(title, maxLines: 1, style: TextStyle(color: textColor)),
//     );
//   }
// }
