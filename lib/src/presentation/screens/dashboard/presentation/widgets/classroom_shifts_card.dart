// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:schoolerp/core/common/widgets/simmer_loader.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/decorations.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/classroom-schedule/data/models/weeklyRoomRatioModel.dart';
// import 'package:schoolerp/features/classroom-schedule/presentation/cubit/weekly_room_ratio_cubit.dart';
// // import 'package:schoolerp/features/classroom-schedule/presentation/screens/classroom_shifts_screen.dart';

// class ClassroomShiftsCard extends StatefulWidget {
//   const ClassroomShiftsCard({super.key});
//   @override
//   State<ClassroomShiftsCard> createState() => ClassroomShiftsCardState();
// }

// class ClassroomShiftsCardState extends State<ClassroomShiftsCard> {
//   DateTime _selectedShiftDate = DateTime.now();
//   DateTime startWeek = DateTime.now();
//   DateTime endWeek = DateTime.now();
//   bool _showAllClassrooms = false;
//   static const int _initialDisplayCount = 7;

//   @override
//   void initState() {
//     super.initState();
//     final date = getStartAndEndWeekDate(_selectedShiftDate);
//     startWeek = date[0];
//     endWeek = date[1];
//     getWeeklyRoomRatio();
//   }

//   Future<void> getWeeklyRoomRatio() async {
//     final DataMap parameters = {
//       'schoolId': '${context.currentStaff!.schoolId}',
//       'startDate': convertDateTime(startWeek),
//       'endDate': convertDateTime(endWeek),
//       'sort': 'id,desc',
//       'page': '0',
//       'size': '100',
//     };
//     final data = await context
//         .read<WeeklyRoomRatioCubit>()
//         .getWeeklyRoomRatio(parameters: parameters);
//   }

//   void refreshData() {
//     getWeeklyRoomRatio();
//   }

//   String convertDateTime(DateTime dateTime) {
//     return dateTime.toUtc().toIso8601String(); // + 'Z';
//   }

//   List<DateTime> getStartAndEndWeekDate(DateTime date) {
//     int currentWeekday = date.weekday;
//     DateTime startOfWeek = DateTime.utc(
//       date.year,
//       date.month,
//       date.day - (currentWeekday - 1),
//     );
//     DateTime endOfWeek = DateTime.utc(
//       startOfWeek.year,
//       startOfWeek.month,
//       startOfWeek.day + 6,
//       23,
//       59,
//       59,
//       999,
//     );
//     return [startOfWeek, endOfWeek];
//   }

//   List<RoomRatioModel> getRoomsRatioByDate(WeeklyRoomRatioModel rooms) {
//     List<RoomRatioModel> ratios = [];
//     for (final room in rooms.rooms) {
//       final roomRatios = room.roomRatio;
//       for (final ratio in roomRatios) {
//         final DateTime dateTime = DateTime.parse(ratio.date);
//         final String formattedRatioDate =
//             DateFormat('yyyy-MM-dd').format(dateTime);

//         final String formattedSelectedDate =
//             DateFormat('yyyy-MM-dd').format(_selectedShiftDate);
//         if (formattedRatioDate == formattedSelectedDate) {
//           ratios.add(ratio);
//         }
//       }
//     }
//     ratios.sort((a, b) => a.name.compareTo(b.name));
//     return ratios;
//   }

//   Widget _buildClassroomShiftsDateNavigator(
//       void Function(DateTime)? onDateChanged) {
//     final formattedDate = DateFormat('EEE, MMM d').format(_selectedShiftDate);

//     void _changeDate(int days) {
//       final newDate = _selectedShiftDate.add(Duration(days: days));
//       List<DateTime> week = getStartAndEndWeekDate(newDate);
//       setState(() {
//         _selectedShiftDate = newDate;
//         bool isBefore = week[0].isAfter(startWeek);
//         bool isAfter = week[1].isBefore(endWeek);
//         if (isBefore || isAfter) {
//           startWeek = week[0];
//           endWeek = week[1];
//           getStartAndEndWeekDate(newDate);
//           getWeeklyRoomRatio();
//         }
//       });

//       onDateChanged?.call(_selectedShiftDate);
//     }

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Material(
//           child: InkWell(
//             onTap: () => _changeDate(-1),
//             borderRadius: BorderRadius.circular(100),
//             splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
//             child: const Padding(
//               padding: EdgeInsets.all(4),
//               child: Icon(
//                 Icons.arrow_back_ios_new,
//                 size: 18,
//                 color: AppColors.primaryColor,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 2),
//         Text(
//           formattedDate,
//           style: const TextStyle(
//             color: AppColors.primaryColor,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(width: 8),
//         // for calendar
//         // Material(
//         //   child: InkWell(
//         //     onTap: () async {
//         //       final result = await showDialog<Map<String, dynamic>>(
//         //         context: context,
//         //         builder: (_) => CalendarDialog(
//         //           isTimePicker: false,
//         //           initialDate: _selectedAvailabilityDate,
//         //         ),
//         //       );

//         //       if (result != null && result['date'] != null) {
//         //         final selectedDate = result['date'] as DateTime;
//         //         List<DateTime> week = getStartAndEndWeekDate(selectedDate);
//         //         setState(() {
//         //           _selectedShiftDate = selectedDate;
//         //           bool isBefore = week[0].isAfter(startWeek);
//         //           bool isAfter = week[1].isBefore(endWeek);
//         //           if (isBefore || isAfter) {
//         //             startWeek = week[0];
//         //             endWeek = week[1];
//         //             getStartAndEndWeekDate(selectedDate);
//         //             getWeeklyRoomRatio();
//         //           }
//         //         });
//         //         onDateChanged?.call(selectedDate);
//         //       }
//         //     },
//         //     borderRadius: BorderRadius.circular(100),
//         //     splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
//         //     child: Padding(
//         //       padding: const EdgeInsets.all(4),
//         //       child: SvgPicture.asset(MediaRes.calender_icon),
//         //     ),
//         //   ),
//         // ),

//         Material(
//           child: InkWell(
//             onTap: () => _changeDate(1),
//             borderRadius: BorderRadius.circular(100),
//             splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
//             child: const Padding(
//               padding: EdgeInsets.all(4),
//               child: Icon(
//                 Icons.arrow_forward_ios,
//                 size: 18,
//                 color: AppColors.primaryColor,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
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
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Classroom Shifts',
//                 style: TextStyle(
//                   color: AppColors.primaryColor,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               // Container(
//               //   padding: const EdgeInsets.symmetric(
//               //     horizontal: 8,
//               //     vertical: 4,
//               //   ),
//               //   decoration: BoxDecoration(
//               //     color: const Color.fromRGBO(254, 241, 195, 1),
//               //     borderRadius: BorderRadius.circular(6),
//               //   ),
//               //   child: const Text(
//               //     'Coming Soon',
//               //     style: TextStyle(
//               //       color: Color.fromRGBO(137, 108, 2, 1),
//               //       fontSize: 12,
//               //       fontWeight: FontWeight.bold,
//               //     ),
//               //   ),
//               // ),
//             ],
//           ),
//           const SizedBox(height: 16.0),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Row(
//                 children: [
//                   SvgPicture.asset(
//                     MediaRes.alertTriangleIcon,
//                     height: 16,
//                   ),
//                   const SizedBox(width: 4.0),
//                   const Text(
//                     'Not In Ratio',
//                     style: TextStyle(fontSize: 14.0),
//                   ),
//                 ],
//               ),
//               const SizedBox(width: 16.0),
//               Row(
//                 children: [
//                   SvgPicture.asset(
//                     MediaRes.greenCheckCircleIcon,
//                     height: 16,
//                   ),
//                   const SizedBox(width: 4.0),
//                   const Text(
//                     'In Ratio',
//                     style: TextStyle(fontSize: 14.0),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16.0),
//           BlocConsumer<WeeklyRoomRatioCubit, WeeklyRoomRatioState>(
//             listener: (context, state) {
//               if (state is WeeklyRoomRatioError) {
//                 // WidgetsBinding.instance.addPostFrameCallback((_) {
//                 //   CoreUtils.showTopSnackBar(
//                 //     context: context,
//                 //     isError: true,
//                 //     isWarning: false,
//                 //     isSuccess: false,
//                 //     isAdjust: true,
//                 //     message: 'Classroom Shitfs Error : ${state.message}',
//                 //   );
//                 // });
//               }
//             },
//             builder: (context, state) {
//               if (state is GettingWeeklyRoomRatio) {
//                 return ShimmerLoaderCard(
//                     child: Container(
//                   height: 400,
//                   decoration: ContainerDecorations.decoration0,
//                 ));
//               }

//               if (state is WeeklyRoomRatioLoaded) {
//                 final data = state.weeklyRoomRatio;
//                 final ratios = getRoomsRatioByDate(data);
//                 final displayRatios = (_showAllClassrooms)
//                     ? ratios
//                     : ratios.take(_initialDisplayCount).toList();

//                 final hasMoreToShow = ratios.length > _initialDisplayCount;

//                 return Column(
//                   children: [
//                     Table(
//                       border: TableBorder(
//                         horizontalInside: BorderSide(
//                           color: Colors.grey[300]!,
//                           width: 1.0,
//                         ),
//                       ),
//                       columnWidths: {
//                         0: const FlexColumnWidth(1),
//                         1: const FlexColumnWidth(1),
//                       },
//                       children: [
//                         TableRow(
//                           children: [
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(vertical: 8.0),
//                               child: Text(
//                                 'Classroom',
//                                 style: TextStyle(
//                                   fontSize: 14.0,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                             ),
//                             Padding(
//                               padding:
//                                   const EdgeInsets.symmetric(vertical: 8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   _buildClassroomShiftsDateNavigator((_) {}),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         ...displayRatios.map((ratio) => _buildTableRow(
//                               ratio.name,
//                               ratio.status == 'Not in ratio'
//                                   ? MediaRes.alertTriangleIcon
//                                   : MediaRes.greenCheckCircleIcon,
//                               ratio.status == 'Not in ratio'
//                                   ? Colors.red
//                                   : Colors.green,
//                             )),
//                         //           // _buildTableRow('1-Blue-D',
//                         //           //     FontAwesomeIcons.triangleExclamation, Colors.red),
//                         //           // _buildTableRow('2-Green-D',
//                         //           //     FontAwesomeIcons.circleCheck, Colors.green),
//                         //           // _buildTableRow('3-Purple-D',
//                         //           //     FontAwesomeIcons.circleCheck, Colors.green),
//                         //           // _buildTableRow('4-Yellow-D',
//                         //           //     FontAwesomeIcons.triangleExclamation, Colors.red),
//                         //           // _buildTableRow('5-Green-P',
//                         //           //     FontAwesomeIcons.circleCheck, Colors.green),
//                         //           // _buildTableRow('6-Pink-P', FontAwesomeIcons.circleCheck,
//                         //           //     Colors.green),
//                         //           // _buildTableRow('7-Yellow-P',
//                         //           //     FontAwesomeIcons.circleCheck, Colors.green),
//                         //           // _buildTableRow('8-Blue-P',
//                         //           //     FontAwesomeIcons.triangleExclamation, Colors.red),
//                       ],
//                     ),
//                     if (hasMoreToShow)
//                       InkWell(
//                         onTap: () {
//                           setState(() {
//                             _showAllClassrooms = !_showAllClassrooms;
//                           });
//                         },
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           decoration: BoxDecoration(
//                             color:
//                                 AppColors.primaryColor.withValues(alpha: 0.03),
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(12),
//                               bottomRight: Radius.circular(12),
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 (_showAllClassrooms)
//                                     ? 'Show Less'
//                                     : 'Show More',
//                                 style: const TextStyle(
//                                   color: AppColors.primaryColor,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Icon(
//                                 _showAllClassrooms
//                                     ? Icons.keyboard_arrow_up
//                                     : Icons.keyboard_arrow_down,
//                                 color: AppColors.primaryColor,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 );
//               }

//               return Column(
//                 children: [
//                   Table(
//                     border: TableBorder(
//                       horizontalInside: BorderSide(
//                         color: Colors.grey[300]!,
//                         width: 1.0,
//                       ),
//                     ),
//                     columnWidths: {
//                       0: const FlexColumnWidth(1),
//                       1: const FlexColumnWidth(1),
//                     },
//                     children: [
//                       TableRow(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Text(
//                               'Classroom',
//                               style: TextStyle(
//                                 fontSize: 14.0,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 _buildClassroomShiftsDateNavigator((_) {}),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       // ...displayRatios.map((ratio) => _buildTableRow(
//                       //       ratio.name,
//                       //       ratio.status == 'Not in ratio'
//                       //           ? MediaRes.alertIcon
//                       //           : MediaRes.greenCheckCircleIcon,
//                       //       ratio.status == 'Not in ratio'
//                       //           ? Colors.red
//                       //           : Colors.green,
//                       //     )),
//                       _buildTableRow(
//                           '1-Blue-D', MediaRes.alertIcon, Colors.red),
//                       _buildTableRow('2-Green-D', MediaRes.greenCheckCircleIcon,
//                           Colors.green),
//                       _buildTableRow('3-Purple-D',
//                           MediaRes.greenCheckCircleIcon, Colors.green),
//                       _buildTableRow(
//                           '4-Yellow-D', MediaRes.alertIcon, Colors.red),
//                       _buildTableRow(
//                           '5-Green-P', MediaRes.alertIcon, Colors.green),
//                       _buildTableRow('6-Pink-P', MediaRes.greenCheckCircleIcon,
//                           Colors.green),
//                       _buildTableRow(
//                           '7-Yellow-P', MediaRes.alertIcon, Colors.green),
//                       _buildTableRow(
//                           '8-Blue-P', MediaRes.alertIcon, Colors.red),
//                     ],
//                   ),
//                   InkWell(
//                     onTap: () {
//                       setState(() {
//                         _showAllClassrooms = !_showAllClassrooms;
//                       });
//                     },
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryColor.withValues(alpha: 0.03),
//                         borderRadius: const BorderRadius.only(
//                           bottomLeft: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             (_showAllClassrooms) ? 'Show Less' : 'Show More',
//                             style: const TextStyle(
//                               color: AppColors.primaryColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(width: 4),
//                           Icon(
//                             _showAllClassrooms
//                                 ? Icons.keyboard_arrow_up
//                                 : Icons.keyboard_arrow_down,
//                             color: AppColors.primaryColor,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   TableRow _buildTableRow(String classroom, String icon, Color iconColor) {
//     return TableRow(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 15.0),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     classroom,
//                     style: TextStyle(fontSize: 18.0, color: Colors.grey[700]),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 15.0),
//           child: Center(
//             child: SvgPicture.asset(
//               icon,
//               height: 20,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
