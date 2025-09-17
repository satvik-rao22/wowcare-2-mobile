// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_cubit.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_report_cubit.dart';
// import 'package:schoolerp/features/newsletter/presentation/cubit/newsletter_cubit.dart';
// import 'package:schoolerp/features/student/presentation/cubit/student_data_cubit.dart';
// import 'package:schoolerp/src/billing/presentation/cubit/billing_data_cubit.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/childs_progress_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/my_childs_day_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/student_attendance_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/student_billing_card.dart';
// import 'package:schoolerp/src/dashboard/presentation/widgets/student_newsletters_card.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SelectedStudentCubit extends Cubit<String> {
//   SelectedStudentCubit(String initialStudentId) : super(initialStudentId);

//   void selectStudent(String studentId) => emit(studentId);
// }

// class ParentDashboard extends StatefulWidget {
//   const ParentDashboard({super.key});

//   static const String routeName = '/parent-dashboard';

//   @override
//   State<ParentDashboard> createState() => _ParentDashboardState();
// }

// class _ParentDashboardState extends State<ParentDashboard> {
//   int _selectedStudentIndex = 0;
//   late SelectedStudentCubit _selectedStudentCubit;
//   final GlobalKey<MyChildsDayCardState> _attendanceTimerCardKey = GlobalKey();
//   final GlobalKey<StudentAttendanceCardState> _attendanceCardKey = GlobalKey();
//   final GlobalKey<StudentNewslettersCardState> _newsletterCardKey = GlobalKey();
//   final GlobalKey<StudentBillingCardState> _billingCardKey = GlobalKey();
//   bool showCard = true; // <-- Add this

//   @override
//   void initState() {
//     super.initState();
//     _selectedStudentCubit = SelectedStudentCubit('');
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     final students = context.currentGuardian!.students;
//     if (students.isNotEmpty && _selectedStudentCubit.state.isEmpty) {
//       _selectedStudentCubit.selectStudent(students[0].id.toString());
//       _saveSelectedStudentForPayment(students[0].id);
//     }
//   }

//   Future<void> _onRefresh() async {
//     _attendanceTimerCardKey.currentState?.restartTimer();
//     _attendanceCardKey.currentState?.refreshData();
//     _newsletterCardKey.currentState?.getAllNewsLetters();
//     _billingCardKey.currentState?.refreshData();
//   }

//   @override
//   void dispose() {
//     _selectedStudentCubit.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final students = context.currentGuardian!.students;

//     return GlobalScaffold(
//       isRefreshable: true,
//       onRefresh: _onRefresh,
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 36,
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF8F7FA),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButtonHideUnderline(
//                 child: DropdownButton<int>(
//                   value: _selectedStudentIndex,
//                   icon: const Icon(
//                     Icons.keyboard_arrow_down,
//                     color: AppColors.primaryColor,
//                   ),
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         color: AppColors.primaryColor,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                       ),
//                   onChanged: (int? index) {
//                     if (index != null) {
//                       setState(() {
//                         _selectedStudentIndex = index;
//                       });
//                       _saveSelectedStudentForPayment(
//                           students[index].id);
//                     }
//                   },
//                   items: List.generate(
//                     students.length,
//                     (index) => DropdownMenuItem<int>(
//                       value: index,
//                       child: Text(
//                         students[index].fullName,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             BlocProvider(
//               create: (context) => sl<StudentDataCubit>(),
//               child: MyChildsDayCard(
//                 studentId: students[_selectedStudentIndex].id,
//                 key: _attendanceTimerCardKey,
//                 guardianStudents: students,
//                 onClose: () {
//                   setState(() {
//                     print('Card closed');
//                     showCard = false;
//                   });
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             MultiBlocProvider(
//               providers: [
//                 BlocProvider(
//                   create: (_) => sl<AttendanceCubit>(),
//                 ),
//                 BlocProvider(
//                   create: (_) => sl<AttendanceReportCubit>(),
//                 ),
//                 BlocProvider(
//                   create: (_) => sl<StudentDataCubit>(),
//                 ),
//               ],
//               child: StudentAttendanceCard(
//                 student: students[_selectedStudentIndex],
//                 key: _attendanceCardKey,
//                 onClose: () {
//                   setState(() {
//                     print('Attendance card minimized');
//                     // Optionally update state to hide the card or perform other actions
//                   });
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             MultiBlocProvider(
//               providers: [
//                 BlocProvider(
//                   create: (_) => sl<StudentDataCubit>(),
//                 ),
//                 BlocProvider(
//                   create: (context) => sl<BillingDataCubit>(),
//                 ),
//               ],
//               child: StudentBillingCard(
//                 key: _billingCardKey,
//                 students: students,
//               ),
//             ),
//             const SizedBox(height: 20),
//             BlocProvider(
//               create: (context) => sl<NewsletterCubit>(),
//               child: StudentNewslettersCard(
//                 student: students[_selectedStudentIndex],
//                 key: _newsletterCardKey,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ChildsProgressCard(),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Future<void> _saveSelectedStudentForPayment(int studentId) async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('payment_student_id', studentId);
//     // Optionally persist guardian as well if available later
//   } catch (_) {}
// }
