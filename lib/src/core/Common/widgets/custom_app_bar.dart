// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:http/http.dart' as http;
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import 'package:schoolerp/core/common/widgets/custom_profile_avatar.dart';
// import 'package:schoolerp/core/common/widgets/reusable_log_out_model_sheet.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/constants.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/schoolData/presentation/cubit/school_data_cubit.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/widgets/message_notification_icon.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:schoolerp/src/firebase_messaging/firebase_services/bell_icon_notification_service.dart';
// import 'package:schoolerp/src/firebase_messaging/notification_screens/notifications_screen.dart';
// import 'package:schoolerp/src/guardian_profile/guardian_user_profile_screen.dart';
// import 'package:schoolerp/src/user_profile/views/screens/user_profile_screen.dart';
// import 'package:url_launcher/url_launcher.dart';

// class PopupItem extends StatelessWidget {
//   final String title;
//   final Icon icon;

//   const PopupItem({required this.title, required this.icon, super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(children: [icon, const SizedBox(width: 12), Text(title)]);
//   }
// }

// class TabBarStyle {
//   final TabAlignment? tabAlignment;
//   final Decoration? indicator;
//   final EdgeInsetsGeometry? indicatorPadding;
//   final TextStyle? labelStyle;
//   final TextStyle? unselectedLabelStyle;
//   final Color? labelColor;
//   final Color? unselectedLabelColor;
//   final double? indicatorWeight;
//   final TabBarIndicatorSize? indicatorSize;
//   final bool? isScrollable;

//   const TabBarStyle({
//     this.tabAlignment,
//     this.indicator,
//     this.indicatorPadding,
//     this.labelStyle,
//     this.unselectedLabelStyle,
//     this.labelColor,
//     this.unselectedLabelColor,
//     this.indicatorWeight,
//     this.indicatorSize,
//     this.isScrollable,
//   });
// }

// class CustomAppBar extends StatefulWidget {
//   const CustomAppBar({
//     this.hasBackButton = false,
//     this.tabs,
//     this.tabController,
//     this.tabBarStyle,
//     super.key,
//   });

//   final bool hasBackButton;
//   final List<Tab>? tabs;
//   final TabController? tabController;
//   final TabBarStyle? tabBarStyle;

//   @override
//   State<CustomAppBar> createState() => _CustomAppBarState();
// }

// class _CustomAppBarState extends State<CustomAppBar> {
//   Uint8List? profileImage;
//   final UserNotificationService _notificationService =
//       UserNotificationService();
//   int _unreadCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     getStaffProfile();
//     _initNotifications();
//   }

//   void _initNotifications() {
//     final userId = context.currentUser?.id ?? '';
//     if (userId.toString().isEmpty) {
//       debugPrint('Error: userId is empty');
//       return;
//     }

//     debugPrint('Initializing notifications for userId: $userId');
//     _notificationService.fetchAndUpdateCount(userId.toString());

//     _notificationService.unreadCountStream.listen(
//       (count) {
//         if (mounted) {
//           debugPrint('Unread count updated: $count');
//           setState(() {
//             _unreadCount = count;
//           });
//         }
//       },
//       onError: (error) {
//         debugPrint('Error in unreadCountStream: $error');
//         if (mounted) {
//           setState(() {
//             _unreadCount = 0;
//           });
//         }
//       },
//     );
//   }

//   void getStaffProfile() {
//     DataMap parameters = {
//       'docType.equals': 'PROFILE',
//       'refTableId.equals':
//           '${context.currentStaff == null ? (context.isGuardian ? context.currentGuardian?.id ?? 0 : 0) : context.currentStaff!.id}',
//       'refTable.equals': context.isGuardian ? 'Guardian' : 'Staff',
//     };

//     context.read<DocumentBloc>().add(DownloadDocument(parameters));
//   }

//   Widget _buildActionIconButton({
//     required VoidCallback onPressed,
//     required String icon,
//     required int count,
//   }) => Stack(
//     children: [
//       IconButton(onPressed: onPressed, icon: SvgPicture.asset(icon)),
//       if (count > 0) // Only show badge if count is greater than 0
//         Positioned(
//           right: 6,
//           top: 6,
//           child: Container(
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: const Color.fromRGBO(179, 38, 30, 1),
//             ),
//             constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
//             child: Text(
//               count > 99 ? '99+' : count.toString(),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//     ],
//   );

//   PreferredSizeWidget? _buildTabBar() {
//     if (widget.tabs == null || widget.tabController == null) {
//       return null;
//     }

//     return TabBar(
//       controller: widget.tabController!,
//       tabAlignment: widget.tabBarStyle?.tabAlignment ?? TabAlignment.center,
//       indicator: widget.tabBarStyle?.indicator,
//       indicatorPadding: widget.tabBarStyle?.indicatorPadding ?? EdgeInsets.zero,
//       isScrollable: widget.tabBarStyle?.isScrollable ?? false,
//       labelColor: widget.tabBarStyle?.labelColor,
//       unselectedLabelColor: widget.tabBarStyle?.unselectedLabelColor,
//       indicatorWeight: widget.tabBarStyle?.indicatorWeight ?? 2,
//       indicatorSize: widget.tabBarStyle?.indicatorSize,
//       splashFactory: NoSplash.splashFactory,
//       labelStyle: widget.tabBarStyle?.labelStyle,
//       unselectedLabelStyle: widget.tabBarStyle?.unselectedLabelStyle,
//       tabs: widget.tabs!,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SliverAppBar(
//       pinned: true,
//       floating: true,
//       snap: true,
//       stretch: true,
//       scrolledUnderElevation: 0,
//       backgroundColor: Colors.white,
//       bottom: _buildTabBar() != null
//           ? PreferredSize(
//               preferredSize: Size.fromHeight(
//                 (_buildTabBar()?.preferredSize.height ?? 0) + 1.5,
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       border: const Border(
//                         bottom: BorderSide(
//                           width: 1.5,
//                           color: Colors.transparent,
//                         ),
//                       ),
//                       gradient: AppColors.buildSecondaryGradient(),
//                     ),
//                   ),
//                   _buildTabBar()!,
//                 ],
//               ),
//             )
//           : PreferredSize(
//               preferredSize: const Size.fromHeight(1.5),
//               child: Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       border: const Border(
//                         bottom: BorderSide(
//                           width: 1.5,
//                           color: Colors.transparent,
//                         ),
//                       ),
//                       gradient: AppColors.buildSecondaryGradient(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//       leading: widget.hasBackButton
//           ? IconButton(
//               onPressed: () => Navigator.pop(context),
//               icon: SvgPicture.asset(MediaRes.backButton),
//             )
//           : (context.isPersonnel || context.isGuardian)
//           ? IconButton(
//               onPressed: () => Scaffold.of(context).openDrawer(),
//               icon: SvgPicture.asset(MediaRes.hamburgerIcon),
//             )
//           : null,
//       actions: [
//         const MessageNotificationIcon(),
//         _buildActionIconButton(
//           onPressed: () =>
//               _navigateIfNotCurrent(context, NotificationsScreen.routeName),
//           icon: MediaRes.notificationsIcon,
//           count: _unreadCount,
//         ),
//         PopupMenuButton(
//           icon: SvgPicture.asset(MediaRes.kebabMenu),
//           offset: const Offset(0, 50),
//           surfaceTintColor: AppColors.cardColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           itemBuilder: (_) => [
//             PopupMenuItem<void>(
//               enabled: false,
//               height: 120,
//               child: Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     BlocConsumer<DocumentBloc, DocumentState>(
//                       listener: (context, state) {
//                         if (state is DocumentError) {
//                           CoreUtils.showTopSnackBar(
//                             context: context,
//                             isError: true,
//                             isWarning: false,
//                             isSuccess: false,
//                             isAdjust: false,
//                             message: state.message,
//                           );
//                         }
//                       },
//                       builder: (context, state) {
//                         return CustomProfileAvatar(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => context.isGuardian
//                                     ? BlocProvider(
//                                         create: (context) =>
//                                             sl<SchoolDataCubit>(),
//                                         child:
//                                             const GuardianUserProfileScreen(),
//                                       )
//                                     : BlocProvider(
//                                         create: (context) =>
//                                             sl<SchoolDataCubit>(),
//                                         child: const UserProfileScreen(),
//                                       ),
//                               ),
//                             );
//                           },
//                           fontSize: 24,
//                           radius: 30,
//                           hasStatus: true,
//                           statusSize: 16,
//                           statusPositionTop: 1,
//                           statusPositionRight: 1,
//                           statusBorder: 2,
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       context.isPersonnel
//                           ? context.currentStaff?.name ?? 'Staff'
//                           : context.currentGuardian?.fullName ?? 'Guardian',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     if (context.isPersonnel)
//                       Text(
//                         context.currentStaff?.designation ?? 'Designation',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     if (!context.isPersonnel)
//                       Text(
//                         context.currentGuardian?.relation ?? 'Relation',
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             PopupMenuItem<void>(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => context.isGuardian
//                         ? BlocProvider(
//                             create: (context) => sl<SchoolDataCubit>(),
//                             child: const GuardianUserProfileScreen(),
//                           )
//                         : BlocProvider(
//                             create: (context) => sl<SchoolDataCubit>(),
//                             child: const UserProfileScreen(),
//                           ),
//                   ),
//                 );
//               },
//               child: const PopupItem(
//                 title: 'My Profile',
//                 icon: Icon(Icons.person, color: AppColors.themeColor),
//               ),
//             ),
//             PopupMenuItem<void>(
//               onTap: () {
//                 _showChangePasswordBottomSheet(context);
//               },
//               child: const PopupItem(
//                 title: 'Change Password',
//                 icon: Icon(Icons.lock_outline, color: AppColors.themeColor),
//               ),
//             ),
//             PopupMenuItem<void>(
//               onTap: () async {
//                 const url = 'https://help.childcarewow.com/portal/en/home';
//                 debugPrint('Launching help URL: $url');
//                 final uri = Uri.parse(url);
//                 if (await canLaunchUrl(uri)) {
//                   await launchUrl(uri);
//                 } else {
//                   debugPrint('Failed to launch URL: $url');
//                 }
//               },
//               child: const PopupItem(
//                 title: 'Help',
//                 icon: Icon(Icons.help, color: AppColors.themeColor),
//               ),
//             ),
//             PopupMenuItem<void>(
//               onTap: () {
//                 showModalBottomSheet(
//                   context: context,
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                   ),
//                   builder: (context) => const LogOutModelBottomSheet(),
//                 );
//               },
//               child: const PopupItem(
//                 title: 'Logout',
//                 icon: Icon(Icons.logout, color: AppColors.themeColor),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _notificationService.dispose();
//     super.dispose();
//   }
// }

// // Helper function to prevent duplicate navigation
// void _navigateIfNotCurrent(BuildContext context, String routeName) {
//   if (ModalRoute.of(context)?.settings.name != routeName) {
//     Navigator.pushNamed(context, routeName);
//   }
// }

// void _showChangePasswordBottomSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     builder: (BuildContext context) {
//       return Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: 20,
//           right: 20,
//           top: 20,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Change Password',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Are you sure you want to change your password? A password reset link will be sent to your registered email.',
//               style: TextStyle(fontSize: 14, color: Colors.grey),
//             ),
//             const SizedBox(height: 30),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       _sendPasswordResetRequest(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.themeColor,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Yes, Change Password',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       );
//     },
//   );
// }

// Future<void> _sendPasswordResetRequest(BuildContext context) async {
//   if (!context.mounted) return;

//   try {
//     String url =
//         '${baseUrl}api/user/reset-password/${context.currentUser!.ssoKey}';
//     String token = AuthProvider.accessToken;

//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'accept': 'application/json, text/plain, */*',
//         'Content-Type': 'application/json',
//       },
//     );
//     debugPrint('Password reset URL: $url');
//     debugPrint('Response status: ${response.statusCode}');
//     debugPrint('Response body: ${response.body}');

//     if (!context.mounted) return;

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Password reset link sent successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send reset link: ${response.statusCode}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } catch (e) {
//     if (!context.mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Error: ${e.toString()}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     debugPrint('Password reset error: $e');
//   }
// }
