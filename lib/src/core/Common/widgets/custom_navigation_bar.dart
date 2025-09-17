// // custom_navigation_bar.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/app/providers/nav_bar_providers.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/fonts.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/src/activity/presentation/views/activity_screen.dart';
// import 'package:schoolerp/src/attendance/presentation/widgets/attendance_popup.dart';
// import 'package:schoolerp/src/billing/presentation/screen/billing_screen.dart';
// import 'package:schoolerp/src/classroom/presentation/views/screens/classroom_info_screen.dart';
// import 'package:schoolerp/src/classroom/presentation/views/screens/classroom_overview_screen.dart';
// import 'package:schoolerp/src/classroom/presentation/views/screens/classroom_screen.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/communication_screen.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/staff_conversation_screen.dart';
// import 'package:schoolerp/src/communication/presentation/student_messaging/student_conversation_screen.dart';
// // Import the persona-specific dashboards
// import 'package:schoolerp/src/dashboard/presentation/views/admin_dashboard.dart';
// import 'package:schoolerp/src/dashboard/presentation/views/parent_dashboard.dart';
// import 'package:schoolerp/src/dashboard/presentation/views/staff_dashboard.dart';
// import 'package:schoolerp/src/guardian_profile/guardian_activity_screen.dart';

// class CustomNavigationBar extends StatefulWidget {
//   const CustomNavigationBar({super.key});

//   static final GlobalKey<_CustomNavigationBarState> navBarKey =
//       GlobalKey<_CustomNavigationBarState>();

//   static double get navBarHeight =>
//       navBarKey.currentState?._navBarHeight ?? 0.0;

//   @override
//   _CustomNavigationBarState createState() => _CustomNavigationBarState();
// }

// class _CustomNavigationBarState extends State<CustomNavigationBar> {
//   String _currentRoute = '';
//   final GlobalKey _containerKey = GlobalKey();
//   double _navBarHeight = 0.0;
//   bool _hasMeasured = false;

//   static const List<String> dashboardRoutes = [
//     AdminDashboard.routeName,
//     StaffDashboard.routeName,
//     ParentDashboard.routeName,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _currentRoute = ModalRoute.of(context)?.settings.name ?? '';
//   }

//   void _measureHeight() {
//     if (_hasMeasured) return;

//     final RenderBox? renderBox =
//         _containerKey.currentContext?.findRenderObject() as RenderBox?;

//     if (renderBox != null && mounted) {
//       final bottomInset = MediaQuery.of(context).padding.bottom;
//       final height = renderBox.size.height + bottomInset;
//       setState(() {
//         _navBarHeight = height;
//         _hasMeasured = true;
//       });

//       context.read<NavBarHeightProvider>().height = height;
//     }
//   }

//   Widget _buildNavItem({
//     required String icon,
//     required String label,
//     required List<String> routeNames,
//     required bool isDashboardItem,
//   }) {
//     final bool isActive = isDashboardItem
//         ? dashboardRoutes.contains(_currentRoute)
//         : routeNames.contains(_currentRoute);

//     return Expanded(
//       child: InkWell(
//         onTap: () {
//           if (label == 'Attendance') {
//             AttendancePopupManager.showAttendancePopup(context);
//             return;
//           }

//           if (isActive) return;

//           if (isDashboardItem) {
//             Navigator.of(context).popUntil((route) =>
//                 dashboardRoutes.contains(route.settings.name) || route.isFirst);
//           } else {
//             Navigator.pushNamed(context, routeNames.first);
//           }
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
//           decoration: isActive
//               ? BoxDecoration(
//                   color: Colors.black.withOpacity(0.4),
//                   borderRadius: BorderRadius.circular(12),
//                 )
//               : null,
//           child: FittedBox(
//             fit: BoxFit.scaleDown,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SvgPicture.asset(
//                   icon,
//                   colorFilter: isActive
//                       ? const ColorFilter.mode(
//                           Colors.white,
//                           BlendMode.dstIn,
//                         )
//                       : null,
//                   height: 24,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontFamily: Fonts.inter,
//                     fontSize: 12,
//                     fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false, // only respect bottom safe area
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//         child: Container(
//           key: _containerKey,
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             gradient: AppColors.buildPrimaryGradient(),
//           ),
//           child: Row(
//             children: [
//               _buildNavItem(
//                 icon: MediaRes.dashboardIcon,
//                 label: 'Dashboard',
//                 routeNames: dashboardRoutes,
//                 isDashboardItem: true,
//               ),
//               if (context.isPersonnel)
//                 _buildNavItem(
//                   icon: MediaRes.attendanceIcon,
//                   label: 'Attendance',
//                   routeNames: [],
//                   isDashboardItem: false,
//                 ),
//               if (context.isPersonnel)
//                 _buildNavItem(
//                   icon: MediaRes.classroomIcon,
//                   label: 'Classrooms',
//                   routeNames: [
//                     ClassroomScreen.routeName,
//                     ClassroomInfoScreen.routeName,
//                     ClassroomOverviewScreen.routeName,
//                   ],
//                   isDashboardItem: false,
//                 ),
//               _buildNavItem(
//                 icon: MediaRes.activitesIcon,
//                 label: 'Activities',
//                 routeNames: [
//                   if (context.isGuardian) GuardianActivityScreen.routeName,
//                   ActivityScreen.routeName,
//                 ],
//                 isDashboardItem: false,
//               ),
//               _buildNavItem(
//                 icon: MediaRes.communicationIcon,
//                 label: context.isPersonnel ? 'Messaging' : 'Communication',
//                 routeNames: [
//                   if (context.isGuardian) StudentConversationScreen.routeName,
//                   CommunicationScreen.routeName,
//                   StaffConversationScreen.routeName,
//                 ],
//                 isDashboardItem: false,
//               ),
//               if (context.isGuardian)
//                 _buildNavItem(
//                   icon: MediaRes.billing_drawer_icon,
//                   label: 'Billing',
//                   routeNames: [BillingScreen.routeName],
//                   isDashboardItem: false,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
