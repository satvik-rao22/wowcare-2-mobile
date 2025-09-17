// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/common/widgets/custom_refresh_indicator.dart';
// import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/staff_utils.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_report_cubit.dart';
// import 'package:schoolerp/features/roomsdata/presentation/cubit/cubit/roomdata_cubit.dart';
// import 'package:schoolerp/features/staff-shitfs/presentation/cubit/weekly_room_schedule_cubit.dart';
// import 'package:schoolerp/features/staff-shitfs/presentation/cubit/weekly_schedule_summary_cubit.dart';
// import 'package:schoolerp/features/working_days/presentation/cubit/working_days_cubit.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/childs_progress_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/events_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/my_attendance_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/my_day_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/my_shifts_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/ratio_monitoring_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/todo_card.dart';

// class StaffDashboard extends StatefulWidget {
//   const StaffDashboard({super.key});

//   static const String routeName = '/staff-dashboard';

//   @override
//   State<StaffDashboard> createState() => _StaffDashboardState();
// }

// class _StaffDashboardState extends State<StaffDashboard> {
//   late RoomdataCubit _roomdataCubit;
//   late AttendanceReportCubit _attendanceReportCubit;
//   final GlobalKey<MyAttendanceCardState> _attendanceCardKey = GlobalKey();
//   final GlobalKey<MyDayCardState> _attendanceTimerCardKey = GlobalKey();
//   final GlobalKey<MyShiftsCardState> _myShiftsCardKey = GlobalKey();

//   @override
//   void initState() {
//     super.initState();
//     _roomdataCubit = sl<RoomdataCubit>();
//     _attendanceReportCubit = sl<AttendanceReportCubit>();
//   }

//   @override
//   void dispose() {
//     _roomdataCubit.close();
//     _attendanceReportCubit.close();
//     super.dispose();
//   }

//   Future<void> _onRefresh() async {
//     StaffUtils.refreshCurrentStaff(context);
//     _attendanceTimerCardKey.currentState?.refreshData();
//     _attendanceCardKey.currentState?.refreshData();
//     _myShiftsCardKey.currentState?.refreshData();
//     _fetchClassroomsData();
//   }

//   void _fetchClassroomsData() {
//     DataMap parameters = {
//       'size': '100',
//       'page': '0',
//       'sort': 'name,asc',
//       'status.equals': 'A',
//       'schoolId.equals':
//           '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//     };

//     if (context.currentStaff != null && context.isStaff) {
//       final roomIdsString =
//           context.currentStaff!.rooms.map((room) => room.id).join(',');

//       parameters.addEntries([MapEntry('id.in', roomIdsString)]);
//     }

//     _roomdataCubit.getAllCountRoomdata(parameters: parameters);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GlobalScaffold(
//       body: CustomRefreshIndicator(
//         onRefresh: _onRefresh,
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               BlocProvider(
//                 create: (_) => sl<WorkingDaysCubit>(),
//                 child: MyDayCard(
//                   key: _attendanceTimerCardKey,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               BlocProvider.value(
//                 value: _roomdataCubit,
//                 child: const RatioMonitoringCard(),
//               ),
//               const SizedBox(height: 20),
//               const EventsCard(),
//               const SizedBox(height: 20),
//               const TodoCard(),
//               const SizedBox(height: 20),
//               MultiBlocProvider(
//                 providers: [
//                   BlocProvider(
//                     create: (context) => sl<WeeklyScheduleSummaryCubit>(),
//                   ),
//                   BlocProvider(
//                     create: (context) => sl<WeeklyRoomScheduleCubit>(),
//                   ),
//                 ],
//                 child: MyShiftsCard(
//                   key: _myShiftsCardKey,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               MyAttendanceCard(
//                 key: _attendanceCardKey,
//                 attendanceReportCubit: _attendanceReportCubit,
//               ),
//               const SizedBox(height: 20),
//               ChildsProgressCard(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
