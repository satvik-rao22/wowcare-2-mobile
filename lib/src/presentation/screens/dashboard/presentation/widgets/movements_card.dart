// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/common/widgets/profile_show_widget.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/future-enrollments/domain/entities/studentRoomMovement.dart';
// import 'package:schoolerp/features/future-enrollments/presentation/cubit/student_room_movement_cubit.dart';
// import 'package:schoolerp/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';

// const monthList = [
//   'Jan',
//   'Feb',
//   'Mar',
//   'Apr',
//   'May',
//   'Jun',
//   'Jul',
//   'Aug',
//   'Sep',
//   'Oct',
//   'Nov',
//   'Dec',
// ];

// class MovementsCard extends StatefulWidget {
//   const MovementsCard({super.key});

//   @override
//   State<MovementsCard> createState() => MovementsCardState();
// }

// class MovementsCardState extends State<MovementsCard> {
//   List<StudentRoomMovement> movements = [];
//   List<GroupedMovement> groupedMovements = [];
//   @override
//   void initState() {
//     super.initState();
//     getFutureEnrollments();
//   }

//   Future<void> getFutureEnrollments() async {
//     final DataMap parameters = {
//       'size': '100',
//       'sort': 'movementDate,asc',
//       'schoolId.equals': AuthProvider.userSchool.id.toString(),
//       'status.equals': 'A',
//       'enrollmentStatus.in': 'Overdue,Upcoming,Confirmed',
//       'page': '0',
//     };
//     final data = await context
//         .read<StudentRoomMovementCubit>()
//         .getStudentRoomMovements(parameters: parameters);
//     print(data);
//     setState(() {
//       movements = data;
//       groupedMovements = getVisibleMovements(data);
//     });
//   }

//   void refreshData() {
//     getFutureEnrollments();
//   }

//   List<GroupedMovement> getVisibleMovements(
//     List<StudentRoomMovement> movements,
//   ) {
//     final Map<String, GroupedMovement> groupedMap = {};

//     for (var move in movements) {
//       final key =
//           '${move.currentRoomId}-${move.nextRoomId}-${move.movementDate}-${move.enrollmentStatus}';

//       final day = DateTime.parse(move.movementDate).day.toString();
//       final month = monthList[DateTime.parse(move.movementDate).month - 1];
//       if (!groupedMap.containsKey(key)) {
//         groupedMap[key] = GroupedMovement(
//           currentRoomId: move.currentRoomId,
//           nextRoomId: move.nextRoomId,
//           movementDate: move.movementDate,
//           movementDay: day,
//           movementMonth: month,
//           enrollmentStatus: move.enrollmentStatus,
//           isLeaving: move.isLeaving,
//           currentRoom: move.currentRoom,
//           nextRoom: move.nextRoom,
//           students: [],
//         );
//       }

//       final student = Student(
//         id: move.studentId,
//         name: move.studentName,
//         photoUuid: move.studentPhotoUuid,
//       );

//       groupedMap[key]!.students.add(student);
//     }

//     final groupedList = groupedMap.values.toList();

//     final overdue = groupedList
//         .where((g) => g.enrollmentStatus == 'Overdue')
//         .toList();

//     final upcomingConfirmed =
//         groupedList
//             .where(
//               (g) =>
//                   g.enrollmentStatus == 'Upcoming' ||
//                   g.enrollmentStatus == 'Confirmed',
//             )
//             .toList()
//           ..sort((a, b) {
//             final aDate = DateTime.parse(a.movementDate);
//             final bDate = DateTime.parse(b.movementDate);
//             return aDate.compareTo(bDate);
//           });

//     return [...overdue, ...upcomingConfirmed].take(3).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.cardBorderColor),
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Movements',
//                 style: TextStyle(
//                   color: AppColors.primaryColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           ...groupedMovements
//               .map(
//                 (move) => _buildMoveItem(
//                   month: move.movementMonth,
//                   day: move.movementDay,
//                   studentCount: move.students.length.toString(),
//                   from: move.currentRoom ?? '',
//                   to: move.isLeaving
//                       ? 'Leaving the School'
//                       : move.nextRoom ?? '',
//                   students: move.students,
//                   status: move.enrollmentStatus,
//                 ),
//               )
//               .toList(),
//         ],
//       ),
//     );
//   }

//   void _showStudentsDialog(BuildContext context, List<Student> students) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Students'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: students.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   leading: Container(
//                     height: 40,
//                     width: 40,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: ClipOval(
//                       child: BlocProvider(
//                         create: (context) => sl<DocumentBloc>(),
//                         child: DocumentImageWidget(
//                           fileUuid: students[index].photoUuid ?? '',
//                           size: 40,
//                           name: students[index].name,
//                         ),
//                       ),
//                     ),
//                   ),
//                   title: Text(students[index].name),
//                 );
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildStudentAvatars(List<Student> students) {
//     return InkWell(
//       onTap: () => _showStudentsDialog(context, students),
//       child: Row(
//         children: [
//           SizedBox(
//             height: 45,
//             width: 45,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: List.generate(
//                 students.length > 5 ? 5 : students.length,
//                 (index) {
//                   String photoUuid = students[index].photoUuid ?? '';

//                   return Positioned(
//                     right: index * 5,
//                     child: Container(
//                       height: 45,
//                       width: 45,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: ClipOval(
//                         child: index == 4 && students.length > 5
//                             ? Center(
//                                 child: Text(
//                                   '+${students.length - 4}',
//                                   style: const TextStyle(
//                                     fontSize: 25,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               )
//                             : BlocProvider(
//                                 create: (context) => sl<DocumentBloc>(),
//                                 child: DocumentImageWidget(
//                                   fileUuid: photoUuid,
//                                   size: 45,
//                                   name: students[index].name,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color getStatusColor(String status) {
//     if (status == 'Overdue') {
//       return Colors.red;
//     } else if (status == 'Upcoming') {
//       return Colors.yellow.shade700;
//     } else if (status == 'Confirmed') {
//       return Colors.green;
//     }
//     return Colors.grey;
//   }

//   Color getBackgroundColor(String status) {
//     if (status == 'Overdue') {
//       return Colors.red.withValues(alpha: 0.25);
//     } else if (status == 'Upcoming') {
//       return Colors.yellow.withValues(alpha: 0.25);
//     } else if (status == 'Confirmed') {
//       return Colors.green.withValues(alpha: 0.25);
//     }
//     return Colors.grey.withValues(alpha: 0.25);
//   }

//   Widget _builtStatusContainer(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//       decoration: BoxDecoration(
//         color: getBackgroundColor(status),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         '${status}',
//         style: TextStyle(
//           fontSize: 16,
//           color: getStatusColor(status),
//           fontWeight: FontWeight.w500,
//         ),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }

//   Widget _buildMoveItem({
//     required String month,
//     required String day,
//     required String studentCount,
//     required String from,
//     required String to,
//     required List<Student> students,
//     required String status,
//   }) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             // Date column
//             SizedBox(
//               width: 48,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     month,
//                     style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                   ),
//                   Text(
//                     day,
//                     style: const TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Vertical line
//             Container(
//               width: 3,
//               height: 64,
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               color: getStatusColor(status),
//             ),
//             // Move details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             studentCount,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           const Text(
//                             'Students',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(width: 4),
//                       _builtStatusContainer(status),
//                       const SizedBox(width: 8),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '$from → $to',
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildStudentAvatars(students),
//           ],
//         ),
//         const SizedBox(height: 8),
//       ],
//     );
//   }
// }
