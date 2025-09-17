// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/widgets/custom_date_time_field.dart';
// import 'package:schoolerp/core/common/widgets/profile_show_widget.dart';
// import 'package:schoolerp/core/common/widgets/simmer_loader.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/decorations.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/TimeZoneConfiguration.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/attendance/domain/entities/attendance_report.dart';
// import 'package:schoolerp/features/attendance/presentation/cubit/attendance_report_cubit.dart';
// import 'package:schoolerp/features/guardian/data/model/guardianDataModel.dart';
// import 'package:schoolerp/features/student/domain/entities/studentData.dart';
// import 'package:schoolerp/features/student/presentation/cubit/student_data_cubit.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/student_attendance_profile.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';

// class StudentAttendanceCard extends StatefulWidget {
//   const StudentAttendanceCard({
//     required this.student,
//     this.onClose,
//     super.key,
//   });

//   final StudentModel student;
//   final VoidCallback? onClose;

//   @override
//   State<StudentAttendanceCard> createState() => StudentAttendanceCardState();
// }

// class StudentAttendanceCardState extends State<StudentAttendanceCard> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   bool _isMinimized = false;
//   StudentModel? _selectedStudent;

//   StudentModel get _effectiveStudent =>
//       context.isGuardian && _selectedStudent != null
//           ? _selectedStudent!
//           : widget.student;

//   @override
//   void initState() {
//     super.initState();
//     DateTime now = DateTime.now();
//     _startDate = DateTime(now.year, now.month, 1);
//     _endDate = DateTime(now.year, now.month + 1, 1).subtract(
//       const Duration(seconds: 1),
//     );
//     if (context.isGuardian) {
//       final guardianStudents = context.currentGuardian?.students ?? [];
//       _selectedStudent = guardianStudents.firstWhere(
//         (s) => s.id == widget.student.id,
//         orElse: () => guardianStudents.isNotEmpty
//             ? guardianStudents.first
//             : widget.student,
//       );
//     }
//     _fetchStudentAttendanceReport();
//     _fetchStudent();
//   }

//   @override
//   void didUpdateWidget(covariant StudentAttendanceCard oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.student.id != widget.student.id) {
//       if (context.isGuardian) {
//         final guardianStudents = context.currentGuardian?.students ?? [];
//         _selectedStudent = guardianStudents.firstWhere(
//           (s) => s.id == widget.student.id,
//           orElse: () => guardianStudents.isNotEmpty
//               ? guardianStudents.first
//               : widget.student,
//         );
//       }
//       _fetchStudent();
//       _fetchStudentAttendanceReport();
//     }
//   }

//   void refreshData() {
//     _fetchStudent();
//     _fetchStudentAttendanceReport();
//   }

//   void _fetchStudentAttendanceReport() {
//     final DataMap reportParameters = {
//       'studentId': '${_effectiveStudent.id}',
//       'startDate': convertLocalToUtc(_startDate!),
//       'endDate': convertLocalToUtc(_endDate!),
//     };

//     context.read<AttendanceReportCubit>().getSingleAttendanceReport(
//           parameters: reportParameters,
//         );
//   }

//   void _fetchStudent() {
//     DataMap parameters = {
//       'id.equals': '${_effectiveStudent.id}',
//     };

//     context.read<StudentDataCubit>().getAllStudentsData(parameters: parameters);
//   }

//   void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
//     setState(() {
//       _startDate = startDate;
//       _endDate = endDate ??
//           DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
//     });

//     _fetchStudentAttendanceReport();
//   }

//   // Check if the current user has permission to view this student's profile
//   bool _hasPermissionToViewStudent() {
//     // Admin/Director can view all student profiles
//     if (context.isAdminOrDirector) {
//       return true;
//     }

//     // Guardian can only view their own children's profiles
//     if (context.isGuardian) {
//       final guardianStudents = context.currentGuardian?.students ?? [];
//       return guardianStudents
//           .any((student) => student.id == _effectiveStudent.id);
//     }

//     // Staff can view students in their assigned rooms
//     if (context.isStaff) {
//       final staffRooms = context.currentStaff?.rooms ?? [];
//       return staffRooms.any((room) => room.id == _effectiveStudent.roomId);
//     }

//     return false;
//   }

//   // Navigate to student attendance profile
//   void _navigateToStudentAttendanceProfile() {
//     if (!_hasPermissionToViewStudent()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//               'You do not have permission to view this student\'s profile.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Convert StudentModel to StudentEntity for the profile screen
//     final studentEntity = convertToStudentEntity(_effectiveStudent);

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StudentAttendanceProfile(
//           students: [studentEntity],
//           refreshCallback: () {
//             // Refresh data when returning from profile
//             refreshData();
//           },
//         ),
//       ),
//     );
//   }

//   StudentEntity convertToStudentEntity(StudentModel studentModel) {
//     return StudentEntity(
//       id: studentModel.id,
//       fullName: studentModel.fullName,
//       photoUuid: studentModel.photoUuid,
//       gender: studentModel.gender,
//       bloodGroup: studentModel.bloodGroup,
//       studentUniqueId: studentModel.studentUniqueId,
//       dateOfBirth: studentModel.dateOfBirth,
//       isSignedIn: studentModel.isSignedIn,
//       isAbsent: studentModel.isAbsent,
//       isExpectedToday: studentModel.isExpectedToday,
//       isPresentToday: false,
//       napStartOrEnd: '',
//       movementDate: studentModel.movementDate,
//       studentFte: studentModel.studentFte,
//       foodProgram: studentModel.foodProgram,
//       isPhotoPermission: false,
//       registrationDate: studentModel.registrationDate,
//       leavingDate: studentModel.leavingDate,
//       roomStartDate: studentModel.roomStartDate,
//       profileStatus: studentModel.profileStatus,
//       allergies: studentModel.allergies,
//       medications: studentModel.medications,
//       dietRestriction: studentModel.dietRestriction,
//       note: studentModel.note,
//       roomId: studentModel.roomId,
//       status: studentModel.status,
//       schoolId: studentModel.schoolId,
//       lastModified: studentModel.lastModified,
//       lastModifiedBy: studentModel.lastModifiedBy,
//       hasPrivateChat: studentModel.hasPrivateChat,
//       isTagRemoved: studentModel.isTagRemoved,
//       privatedByGuardian: studentModel.privatedByGuardian,
//       subsidyInvoiced: studentModel.subsidyInvoiced,
//       subsidyBalance: studentModel.subsidyBalance,
//       subsidyReceived: studentModel.subsidyReceived,
//       childCustody: studentModel.childCustody,
//       startDate: studentModel.startDate,
//       expectedMoveDate: studentModel.expectedMoveDate,
//       isStateSubsidyAllowed: studentModel.isStateSubsidyAllowed,
//       tags: [],
//       siblings: studentModel.siblings,
//       activities: [],
//       schedule: studentModel.schedule,
//       transactions: studentModel.transactions,
//       programRoom: studentModel.programRoom,
//       openBalance: studentModel.openBalance,
//       roomName: studentModel.roomName,
//       invoice: studentModel.invoice,
//       students: studentModel.students,
//       recurringPlan: studentModel.recurringPlan,
//     );
//   }

//   Widget _buildIconItem(String icon) {
//     final bool isSvg = icon.toLowerCase().endsWith('.svg');
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       child: isSvg
//           ? SvgPicture.asset(
//               icon,
//               height: 20,
//             )
//           : Image.asset(
//               icon,
//               height: 20,
//             ),
//     );
//   }

//   Widget _buildIconDetail(String iconPath, String detail) {
//     final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           isSvg
//               ? SvgPicture.asset(iconPath, height: 24)
//               : Image.asset(iconPath, height: 24),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Text(
//               detail,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem({
//     required String icon,
//     required Color iconColor,
//     required String label,
//     required String value,
//     required Color valueColor,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black12, width: 1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           SvgPicture.asset(
//             icon,
//             height: 30,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const Spacer(),
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: valueColor,
//                 width: 1.5,
//               ),
//             ),
//             child: Center(
//               child: Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: valueColor,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.all(0),
//       shape: RoundedRectangleBorder(
//         side: BorderSide(
//           color: AppColors.primaryColor.withValues(alpha: 0.2),
//           width: 0.5,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       elevation: 0,
//       shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
//       child: InkWell(
//         onTap: _navigateToStudentAttendanceProfile,
//         borderRadius: BorderRadius.circular(16),
//         splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
//         highlightColor: AppColors.primaryColor.withValues(alpha: 0.05),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   GestureDetector(
//                     onTap: _navigateToStudentAttendanceProfile,
//                     behavior: HitTestBehavior.opaque,
//                     child: Row(
//                       children: [
//                         const Text(
//                           'Attendance',
//                           style: TextStyle(
//                             color: Color(0xFF573353),
//                             fontSize: 16,
//                             fontFamily: 'Manrope',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         InkWell(
//                           onTap: _navigateToStudentAttendanceProfile,
//                           child: SvgPicture.asset(
//                               MediaRes.redirectArrowGradientIcon),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Spacer(),
//                   Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       onTap: () {
//                         setState(() {
//                           _isMinimized = !_isMinimized;
//                         });
//                         if (_isMinimized && widget.onClose != null) {
//                           widget.onClose!();
//                         }
//                       },
//                       borderRadius: BorderRadius.circular(8),
//                       child: Container(
//                         width: 32,
//                         height: 32,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           border: Border.all(
//                             color: AppColors.themeColor,
//                             width: 2,
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Center(
//                           child: Icon(
//                             _isMinimized ? Icons.add : Icons.remove,
//                             color: AppColors.themeColor,
//                             size: 24,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               if (!_isMinimized) ...[
//                 const SizedBox(height: 16),
//                 CustomDateTimeField(
//                   hasLabel: false,
//                   isRangePicker: true,
//                   initialDate: _startDate,
//                   label: 'Date Range',
//                   onRangeSelected: (start, end) {
//                     _onDateRangeSelected(start, end);
//                   },
//                 ),
//                 if (context.isGuardian) ...[
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<StudentModel>(
//                     value: _effectiveStudent,
//                     icon: const Icon(Icons.arrow_drop_down),
//                     decoration: InputDecoration(
//                       labelText: 'Select Child',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 8),
//                     ),
//                     items: (context.currentGuardian?.students ?? [])
//                         .map((child) => DropdownMenuItem<StudentModel>(
//                               value: child,
//                               child: Row(
//                                 children: [
//                                   Text(child.fullName),
//                                 ],
//                               ),
//                             ))
//                         .toList(),
//                     onChanged: (newStudent) {
//                       if (newStudent == null) return;
//                       setState(() {
//                         _selectedStudent = newStudent;
//                       });
//                       _fetchStudent();
//                       _fetchStudentAttendanceReport();
//                     },
//                   ),
//                 ],
//                 const SizedBox(height: 20),
//                 BlocBuilder<StudentDataCubit, StudentDataState>(
//                   builder: (context, state) {
//                     if (state is AllStudentsDataLoaded) {
//                       final StudentEntity studentEntity = state.students.first;
//                       return Row(
//                         children: [
//                           Stack(
//                             children: [
//                               BlocProvider(
//                                 create: (context) => sl<DocumentBloc>(),
//                                 child: DocumentImageWidget(
//                                   fileUuid: studentEntity.photoUuid,
//                                   name: studentEntity.fullName,
//                                   size: 60,
//                                   fontSize: 24,
//                                 ),
//                               ),
//                               Positioned(
//                                 left: 42,
//                                 bottom: 42,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     color: studentEntity.profileStatus ==
//                                             'Upcoming'
//                                         ? const Color.fromARGB(
//                                             255, 253, 205, 22)
//                                         : studentEntity.isSignedIn
//                                             ? const Color.fromRGBO(
//                                                 0, 177, 21, 1)
//                                             : studentEntity.isAbsent
//                                                 ? const Color.fromRGBO(
//                                                     200, 32, 32, 1)
//                                                 : null,
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(
//                                       color: studentEntity.profileStatus ==
//                                                   'Upcoming' ||
//                                               studentEntity.isSignedIn ||
//                                               studentEntity.isAbsent
//                                           ? Colors.white
//                                           : Colors.transparent,
//                                       width: 2,
//                                     ),
//                                   ),
//                                   constraints: const BoxConstraints(
//                                     minWidth: 18,
//                                     minHeight: 18,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(width: 20),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   convertToStudentEntity(_effectiveStudent)
//                                       .fullName,
//                                   style: const TextStyle(
//                                     color: AppColors.primaryColor,
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.w500,
//                                     letterSpacing: 22 * (-3 / 100),
//                                   ),
//                                 ),
//                                 Row(
//                                   children: [
//                                     Text(
//                                       studentEntity.roomName,
//                                       style: const TextStyle(
//                                         color: AppColors.primaryColor,
//                                         letterSpacing: 14 * (-3 / 100),
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Material(
//                                       color: Colors.transparent,
//                                       child: InkWell(
//                                         onTap: () {
//                                           showDialog(
//                                             context: context,
//                                             builder: (context) => AlertDialog(
//                                               title: const Text(
//                                                 'Details',
//                                                 style: TextStyle(
//                                                   color: AppColors.primaryColor,
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                               content: Column(
//                                                 mainAxisSize: MainAxisSize.min,
//                                                 children: [
//                                                   if (!studentEntity
//                                                       .isPhotoPermission)
//                                                     _buildIconDetail(
//                                                       MediaRes.cameraIcon,
//                                                       "No Photo Permission",
//                                                     ),
//                                                   if (studentEntity
//                                                       .medications.isNotEmpty)
//                                                     _buildIconDetail(
//                                                       MediaRes.healthIcon,
//                                                       "${studentEntity.medications}",
//                                                     ),
//                                                   if (widget
//                                                       .student.note.isNotEmpty)
//                                                     _buildIconDetail(
//                                                       MediaRes.docsIcon,
//                                                       "${studentEntity.note}",
//                                                     ),
//                                                   if (studentEntity
//                                                       .allergies.isNotEmpty)
//                                                     _buildIconDetail(
//                                                       MediaRes.alertIcon,
//                                                       "${studentEntity.allergies}",
//                                                     ),
//                                                   if (studentEntity
//                                                       .dietRestriction
//                                                       .isNotEmpty)
//                                                     _buildIconDetail(
//                                                       MediaRes.foodIcon2,
//                                                       "${studentEntity.dietRestriction}",
//                                                     ),
//                                                 ],
//                                               ),
//                                               actions: [
//                                                 TextButton(
//                                                   onPressed: () =>
//                                                       Navigator.of(context)
//                                                           .pop(),
//                                                   child: const Text(
//                                                     'Close',
//                                                     style: TextStyle(
//                                                       color: AppColors
//                                                           .primaryColor,
//                                                       fontWeight:
//                                                           FontWeight.w500,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         },
//                                         borderRadius: BorderRadius.circular(8),
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(4.0),
//                                           child: Row(
//                                             children: [
//                                               if (!studentEntity
//                                                   .isPhotoPermission)
//                                                 _buildIconItem(
//                                                     MediaRes.cameraIcon),
//                                               if (studentEntity
//                                                   .medications.isNotEmpty)
//                                                 _buildIconItem(
//                                                     MediaRes.healthIcon),
//                                               if (studentEntity.note.isNotEmpty)
//                                                 _buildIconItem(
//                                                     MediaRes.docsIcon),
//                                               if (studentEntity
//                                                   .allergies.isNotEmpty)
//                                                 _buildIconItem(
//                                                     MediaRes.alertIcon),
//                                               if (studentEntity
//                                                   .dietRestriction.isNotEmpty)
//                                                 _buildIconItem(
//                                                     MediaRes.foodIcon2),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       );
//                     }
//                     return const Row();
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 BlocConsumer<AttendanceReportCubit, AttendanceReportState>(
//                   listener: (context, state) {},
//                   builder: (context, state) {
//                     if (state is GettingSingleAttendanceReport) {
//                       return ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: 3,
//                         padding: const EdgeInsets.all(0),
//                         itemBuilder: (context, index) => ShimmerLoaderCard(
//                           margin: const EdgeInsets.only(bottom: 16),
//                           child: Container(
//                             height: 50,
//                             width: context.width,
//                             decoration: ContainerDecorations.decoration0,
//                           ),
//                         ),
//                       );
//                     }
//                     if (state is SingleAttendanceReportsLoaded) {
//                       AttendanceReport attendanceReport =
//                           state.attendanceReport;
//                       return Column(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildStatItem(
//                                   icon: MediaRes.calenderClockIcon,
//                                   iconColor: const Color(0xFF4285F4),
//                                   label: 'Attended Days',
//                                   value: '${attendanceReport.attendedDays}',
//                                   valueColor: const Color(0xFF4CAF50),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildStatItem(
//                                   icon: MediaRes.timerIcon,
//                                   iconColor: const Color(0xFF4285F4),
//                                   label: 'Attended Hours',
//                                   value: attendanceReport
//                                           .totalAttendedHours.isNotEmpty
//                                       ? '${attendanceReport.totalAttendedHours.split(' ').first}h'
//                                       : '0h',
//                                   valueColor: const Color(0xFF4285F4),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: _buildStatItem(
//                                   icon: MediaRes.calenderClockIcon,
//                                   iconColor: const Color(0xFF4285F4),
//                                   label: 'Absent Days',
//                                   value: '${attendanceReport.absentDays}',
//                                   valueColor: Colors.red,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       );
//                     }
//                     return Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildStatItem(
//                                 icon: MediaRes.calenderClockIcon,
//                                 iconColor: const Color(0xFF4285F4),
//                                 label: 'Attended Days',
//                                 value: '',
//                                 valueColor: const Color(0xFF4CAF50),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildStatItem(
//                                 icon: MediaRes.timerIcon,
//                                 iconColor: const Color(0xFF4285F4),
//                                 label: 'Attended Hours',
//                                 value: 'h',
//                                 valueColor: const Color(0xFF4285F4),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildStatItem(
//                                 icon: MediaRes.calenderClockIcon,
//                                 iconColor: const Color(0xFF4285F4),
//                                 label: 'Absent Days',
//                                 value: '',
//                                 valueColor: Colors.red,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
