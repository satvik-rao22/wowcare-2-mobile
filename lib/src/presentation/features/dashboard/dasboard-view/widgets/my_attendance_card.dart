// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/widgets/custom_date_time_field.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/TimeZoneConfiguration.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_cubit.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_report_cubit.dart';
// import 'package:schoolerp/features/user/presentation/cubit/staff_cubit.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/staff_attendance_profile_screen.dart';
// import 'package:schoolerp/src/attendance/presentation/widgets/staff_attendance_profile_card.dart';

// class MyAttendanceCard extends StatefulWidget {
//   const MyAttendanceCard({
//     this.attendanceReportCubit,
//     super.key,
//   });

//   final AttendanceReportCubit? attendanceReportCubit;

//   @override
//   State<MyAttendanceCard> createState() => MyAttendanceCardState();
// }

// class MyAttendanceCardState extends State<MyAttendanceCard> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   late AttendanceReportCubit _attendanceReportCubit;

//   @override
//   void initState() {
//     super.initState();

//     _attendanceReportCubit =
//         widget.attendanceReportCubit ?? sl<AttendanceReportCubit>();
//     DateTime now = DateTime.now();
//     _startDate = DateTime(now.year, now.month, 1);
//     _endDate = DateTime(now.year, now.month + 1, 1).subtract(
//       const Duration(seconds: 1),
//     );

//     _fetchData();
//   }

//   @override
//   void dispose() {
//     if (widget.attendanceReportCubit == null) {
//       _attendanceReportCubit.close();
//     }
//     super.dispose();
//   }

//   void _fetchData() {
//     if (_startDate != null && _endDate != null) {
//       _fetchStaffAttendanceDetails(
//         startDate: convertLocalToUtc(_startDate!),
//         endDate: convertLocalToUtc(_endDate!),
//       );
//     }
//   }

//   void _fetchStaffAttendanceDetails({
//     required String startDate,
//     required String endDate,
//   }) {
//     final DataMap parameters = {
//       'staffId': '${context.currentStaff!.id}',
//       'startDate': startDate,
//       'endDate': endDate,
//     };

//     _attendanceReportCubit.getSingleAttendanceReport(
//       parameters: parameters,
//     );
//   }

//   void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
//     setState(() {
//       _startDate = startDate;
//       _endDate = endDate ??
//           DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
//     });

//     _fetchData();
//   }

//   void refreshData() {
//     _fetchData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       margin: const EdgeInsets.all(0),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: AppColors.primaryColor.withValues(alpha: 0.1),
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => MultiBlocProvider(
//                     providers: [
//                       BlocProvider(
//                         create: (_) => sl<AttendanceCubit>(),
//                       ),
//                       BlocProvider(
//                         create: (_) => sl<StaffCubit>(),
//                       ),
//                     ],
//                     child: StaffAttendanceProfileScreen(
//                       staff: context.currentStaff!,
//                     ),
//                   ),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Text(
//                     'My Attendance',
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   SvgPicture.asset(MediaRes.redirectArrowGradientIcon),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             CustomDateTimeField(
//               hasLabel: false,
//               isRangePicker: true,
//               initialDate: _startDate,
//               label: 'Date Range',
//               onRangeSelected: (start, end) {
//                 _onDateRangeSelected(start, end);
//               },
//             ),
//             const SizedBox(height: 20),
//             BlocProvider.value(
//               value: _attendanceReportCubit,
//               child: StaffAttendanceProfileCard(
//                 isDashboard: true,
//                 staff: context.currentStaff!,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
