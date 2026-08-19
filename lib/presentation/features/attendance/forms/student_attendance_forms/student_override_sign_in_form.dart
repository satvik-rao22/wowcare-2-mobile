// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:intl/intl.dart';
// import 'package:moment_dart/moment_dart.dart';
// import 'package:schoolerp/core/common/widgets/custom_button_layout.dart';
// import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
// import 'package:schoolerp/core/common/widgets/remove_student_tile.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/util/TimeZoneConfiguration.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/core/util/date_utils.dart';
// import 'package:schoolerp/features/attendance/data/model/attendanceModel.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_cubit.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/absent_cubit.dart';
// import 'package:schoolerp/features/student/domain/entities/studentData.dart';
// import 'package:schoolerp/src/classroom/presentation/forms/date_picker_normal.dart';

// class StudentOverrideSignInForm extends StatefulWidget {
//   const StudentOverrideSignInForm({
//     super.key,
//     required this.students,
//     required this.refreshCallback,
//     required this.absentRecordIds, // Map of studentId to absent record ID
//   });

//   final VoidCallback refreshCallback;
//   final List<StudentEntity> students;
//   final Map<int, int> absentRecordIds; // studentId -> absent record ID

//   static const String routeName = '/student-override-sign-in-form';

//   @override
//   _StudentOverrideSignInFormState createState() =>
//       _StudentOverrideSignInFormState();
// }

// class _StudentOverrideSignInFormState extends State<StudentOverrideSignInForm> {
//   DateTime selectedDate = ServerTimeService.instance.now();
//   TimeOfDay selectedTime = TimeOfDay.now();
//   List<StudentEntity> currentStudents = [];
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     setCurrentDateTime();
//     currentStudents = List.from(widget.students);
//   }

//   void _removeStudent(StudentEntity student) {
//     setState(() {
//       currentStudents.remove(student);
//       if (currentStudents.isEmpty) {
//         Navigator.pop(context);
//       }
//     });
//   }

//   Future<void> _selectTime() async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: selectedTime,
//       builder: (context, child) {
//         return MediaQuery(
//           data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null && picked != selectedTime) {
//       setState(() {
//         selectedTime = picked;
//       });
//     }
//   }

//   String _formatTimeForValidation() {
//     final now = ServerTimeService.instance.now();
//     final selectedDateTime = DateTime(
//       selectedDate.year,
//       selectedDate.month,
//       selectedDate.day,
//       selectedTime.hour,
//       selectedTime.minute,
//     );

//     final timeDifference = selectedDateTime.difference(now);
//     final hoursDifference = timeDifference.inHours;
//     final minutesDifference = timeDifference.inMinutes;

//     if (hoursDifference > 24) {
//       return 'Cannot sign in more than 24 hours in advance';
//     } else if (hoursDifference < -24) {
//       return 'Cannot sign in more than 24 hours late';
//     } else if (minutesDifference > 0 && minutesDifference < 30) {
//       return 'Cannot sign in less than 30 minutes in advance';
//     }

//     return '';
//   }

//   void setCurrentDateTime() {
//     final now = ServerTimeService.instance.now();
//     selectedDate = DateTime(now.year, now.month, now.day);
//     selectedTime = TimeOfDay.fromDateTime(now);
//   }

//   String _formatTime(TimeOfDay time) {
//     // Match StudentSignInForm format: 'hh:mm:00 AM/PM'
//     final period = time.hour < 12 ? 'AM' : 'PM';
//     int hour12 = time.hourOfPeriod;
//     if (hour12 == 0) hour12 = 12;
//     final hour = hour12.toString().padLeft(2, '0');
//     final minute = time.minute.toString().padLeft(2, '0');
//     return '$hour:$minute:00 $period';
//   }

//   Future<void> _processOverrideSignIn() async {
//     if (_isProcessing) return;

//     final validationError = _formatTimeForValidation();
//     if (validationError.isNotEmpty) {
//       CoreUtils.showTopSnackBar(
//         context: context,
//         isError: true,
//         isWarning: false,
//         isSuccess: false,
//         isAdjust: false,
//         message: validationError,
//       );
//       return;
//     }

//     if (currentStudents.isEmpty) {
//       CoreUtils.showTopSnackBar(
//         context: context,
//         isError: true,
//         isWarning: false,
//         isSuccess: false,
//         isAdjust: false,
//         message: 'Please select at least one student to sign in',
//       );
//       return;
//     }

//     setState(() {
//       _isProcessing = true;
//     });

//     try {
//       final time = _formatTime(selectedTime);
//       // Match StudentSignInForm payload semantics
//       final DateTime currentUTC = ServerTimeService.instance.nowUtc();
//       final DateTime dateTimeUTC = DateTime.utc(
//         selectedDate.year,
//         selectedDate.month,
//         selectedDate.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );

//       // Process each student
//       for (final student in currentStudents) {
//         // Step 1: Delete the absent record if it exists
//         final absentRecordId = widget.absentRecordIds[student.id];
//         if (absentRecordId != null) {
//           try {
//             await context.read<AbsentCubit>().deleteAttendance(
//               id: absentRecordId,
//             );
//           } catch (e) {
//             AppLogger.d('Error deleting absent record for student ${student.id}: $e');
//             // Continue with sign in even if delete fails
//           }
//         }

//         // Step 2: Create attendance record
//         await context.read<AttendanceCubit>().createSingleAttendance(
//           signInTime: time,
//           signOutTime: '',
//           attendedTime: '00:00:00',
//           noSignOutCount: null,
//           totalHours: null,
//           daysAttended: null,
//           signInBy: context.isPersonnel
//               ? context.currentStaff!.name
//               : context.isGuardian
//               ? context.currentGuardian!.fullName
//               : context.currentStaff!.name,
//           signOutBy: '',
//           note: 'Override Sign In - Previously marked absent',
//           hasSignIn: true,
//           hasStudentId: true,
//           date: currentUTC,
//           roomId: student.roomId,
//           signInStaffId: context.isPersonnel ? context.currentStaff!.id : 0,
//           signOutStaffId: null,
//           status: 'A',
//           schoolId: context.isPersonnel
//               ? context.currentUser!.schoolId
//               : context.currentGuardian!.schoolId,
//           studentId: student.id,
//           lastModified: dateTimeUTC,
//           lastModifiedBy:
//               '${context.isPersonnel
//                   ? context.currentStaff!.name
//                   : context.isGuardian
//                   ? context.currentGuardian!.fullName
//                   : context.currentStaff!.name} from Mobile (Override)',
//           staffId: 0,
//           isPrimary: true,
//         );
//       }

//       if (mounted) {
//         CoreUtils.showTopSnackBar(
//           context: context,
//           isError: false,
//           isWarning: false,
//           isSuccess: true,
//           isAdjust: false,
//           message: 'Students successfully signed in with override',
//         );
//         Navigator.pop(context, {'success': true, 'action': 'sign_in'});
//         widget.refreshCallback();
//       }
//     } catch (e) {
//       if (mounted) {
//         CoreUtils.showTopSnackBar(
//           context: context,
//           isError: true,
//           isWarning: false,
//           isSuccess: false,
//           isAdjust: false,
//           message: 'Error during override sign in: ${e.toString()}',
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (currentStudents.isEmpty) {
//       currentStudents =
//           ModalRoute.of(context)!.settings.arguments as List<StudentEntity>;
//     }

//     return GlobalScaffold(
//       body: BlocConsumer<AttendanceCubit, AttendanceState>(
//         listener: (context, state) {
//           if (state is AttendanceCreated) {
//             // Handle successful attendance creation
//           } else if (state is AuthErrorAttendance) {
//             CoreUtils.showTopSnackBar(
//               context: context,
//               isError: true,
//               isWarning: false,
//               isSuccess: false,
//               isAdjust: false,
//               message: 'Attendance Error: ${state.message}',
//             );
//           }
//         },
//         builder: (context, state) {
//           return Card(
//             elevation: 0,
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: BlocConsumer<AbsentCubit, AbsentState>(
//                 listener: (context, absentState) {
//                   if (absentState is AttendanceDeleted) {
//                     // Handle successful absent record deletion
//                   } else if (absentState is AuthErrorAbsent) {
//                     CoreUtils.showTopSnackBar(
//                       context: context,
//                       isError: true,
//                       isWarning: false,
//                       isSuccess: false,
//                       isAdjust: false,
//                       message:
//                           'Error deleting absent record: ${absentState.message}',
//                     );
//                   }
//                 },
//                 builder: (context, absentState) {
//                   return SingleChildScrollView(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const Text(
//                           'Override Sign-In',
//                           style: TextStyle(
//                             fontSize: 17,
//                             fontWeight: FontWeight.w600,
//                             color: Color.fromRGBO(87, 51, 82, 1),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         // Warning Banner (extra for override)
//                         Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade50,
//                             border: Border.all(color: Colors.orange.shade200),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.warning_amber_rounded,
//                                 color: Colors.orange.shade600,
//                                 size: 24,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Override Sign In',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.orange.shade800,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'This will delete the absent record and sign in the student for today.',
//                                       style: TextStyle(
//                                         color: Colors.orange.shade700,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 30),
//                         GridView.builder(
//                           physics: const NeverScrollableScrollPhysics(),
//                           shrinkWrap: true,
//                           gridDelegate:
//                               const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 crossAxisSpacing: 14,
//                                 mainAxisSpacing: 14,
//                                 childAspectRatio: 3.5,
//                               ),
//                           itemCount: currentStudents.length,
//                           itemBuilder: (context, index) => RemoveStudentTile(
//                             student: currentStudents[index],
//                             onRemove: () =>
//                                 _removeStudent(currentStudents[index]),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Date',
//                                     style: TextStyle(
//                                       color: Color.fromRGBO(10, 28, 93, 0.5),
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 8,
//                                       vertical: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       border: Border.all(
//                                         color: Colors.grey.shade300,
//                                       ),
//                                       borderRadius: BorderRadius.circular(8),
//                                       color: Colors.grey.shade100,
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(
//                                           DateUtilsNew.formatToReadableDate(
//                                             selectedDate,
//                                           ),
//                                           style: TextStyle(
//                                             fontSize: 15,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                         SvgPicture.asset(
//                                           MediaRes.calender_icon,
//                                           colorFilter: ColorFilter.mode(
//                                             Colors.grey.shade600,
//                                             BlendMode.srcIn,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Time',
//                                     style: TextStyle(
//                                       color: Color.fromRGBO(10, 28, 93, 0.5),
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   InkWell(
//                                     onTap: () {
//                                       _selectTime();
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 12,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         border: Border.all(
//                                           color: Colors.grey.shade300,
//                                         ),
//                                         borderRadius: BorderRadius.circular(8),
//                                         color: const Color.fromRGBO(
//                                           249,
//                                           245,
//                                           250,
//                                           1,
//                                         ),
//                                       ),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                             selectedTime.format(context),
//                                             style: const TextStyle(
//                                               fontSize: 15,
//                                               fontWeight: FontWeight.w500,
//                                               color: Colors.black,
//                                             ),
//                                           ),
//                                           SvgPicture.asset(MediaRes.clock_icon),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         if (_formatTimeForValidation().isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 8),
//                             child: Text(
//                               _formatTimeForValidation(),
//                               style: const TextStyle(
//                                 color: Colors.red,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       hasBackButton: true,
//       showCustomNavigationBar: false,
//       customButtonLayout: CustomButtonLayout(
//         confirmButtonLabel: _isProcessing
//             ? 'Processing...'
//             : 'Override Sign In',
//         onPressedConfirm: _isProcessing ? null : _processOverrideSignIn,
//       ),
//     );
//   }
// }
