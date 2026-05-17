// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// Widget _scheduleCard() {
//   final times = List.generate(13, (index) {
//     final hour = index + 6;

//     final dt = DateTime(2000, 1, 1, hour);

//     return DateFormat('hh:00 a').format(dt);
//   });

//   final shift = _selectedStaffShifts.isNotEmpty
//       ? _selectedStaffShifts.first
//       : null;

//   final scheduleDate = DateFormat('EEE, MMM d yyyy').format(_selectedDate);

//   final shiftRange = shift != null
//       ? '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}'
//       : '';

//   final breakRange =
//       (shift?.breakStartTime ?? '').isNotEmpty &&
//           (shift?.breakEndTime ?? '').isNotEmpty
//       ? '${_formatTime(shift!.breakStartTime!)} - ${_formatTime(shift.breakEndTime!)}'
//       : null;

//   const slotHeight = 38.0;
//   final timelineHeight = slotHeight * times.length;

//   final startRefMin = 6 * 60;
//   final endRefMin = 18 * 60;
//   final totalRefMin = endRefMin - startRefMin;

//   double shiftTop = 16;
//   double shiftHeight = 180;
//   double? breakTop;

//   if (shift != null) {
//     final start = _toMinutes(shift.startTime);
//     final end = _toMinutes(shift.endTime);

//     final duration = (end - start).clamp(60, totalRefMin);

//     shiftTop = (((start - startRefMin) / totalRefMin) * timelineHeight).clamp(
//       8,
//       timelineHeight - 80,
//     );

//     shiftHeight = ((duration / totalRefMin) * timelineHeight).clamp(
//       90,
//       timelineHeight - shiftTop,
//     );

//     if ((shift.breakStartTime ?? '').isNotEmpty) {
//       final bStart = _toMinutes(shift.breakStartTime!);

//       breakTop = (((bStart - startRefMin) / totalRefMin) * timelineHeight)
//           .clamp(8, timelineHeight - 30);
//     }
//   }

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       final timeColumnWidth = constraints.maxWidth * 0.39;

//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 6,
//               offset: Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             /// Header
//             Container(
//               height: 44,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFFBF8FC),
//                 border: Border(
//                   bottom: BorderSide(color: Color(0xFFC7D4FF), width: 1.5),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   SizedBox(
//                     width: timeColumnWidth,
//                     child: const Center(
//                       child: Text(
//                         'Time',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 32,
//                     child: VerticalDivider(
//                       width: 1,
//                       thickness: 1,
//                       color: Color(0xFFDADFEA),
//                     ),
//                   ),

//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         scheduleDate,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             /// Timeline
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// Time Column
//                 SizedBox(
//                   width: timeColumnWidth,
//                   child: Column(
//                     children: times.map((t) {
//                       return Container(
//                         height: slotHeight,
//                         alignment: Alignment.center,
//                         decoration: const BoxDecoration(
//                           border: Border(
//                             bottom: BorderSide(
//                               color: Color(0xFFDADFEA),
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         child: Text(
//                           t,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),

//                 const SizedBox(
//                   height: 494,
//                   child: VerticalDivider(
//                     width: 1,
//                     thickness: 1,
//                     color: Color(0xFFDADFEA),
//                   ),
//                 ),

//                 /// Schedule Area
//                 Expanded(
//                   child: SizedBox(
//                     height: timelineHeight,
//                     child: shift == null
//                         ? const Center(
//                             child: Text(
//                               'No schedule available',
//                               style: TextStyle(fontWeight: FontWeight.w500),
//                             ),
//                           )
//                         : Stack(
//                             children: [
//                               /// Shift Block
//                               Positioned(
//                                 left: 10,
//                                 right: 6,
//                                 top: shiftTop,
//                                 child: Container(
//                                   height: shiftHeight,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 16,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFC4D4F0),
//                                     borderRadius: BorderRadius.circular(24),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         _classroomNameForCode(
//                                           shift.classroomCode,
//                                         ),
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w800,
//                                           fontSize: 18,
//                                           color: Color(0xFF3B5BA9),
//                                         ),
//                                       ),

//                                       const SizedBox(height: 6),

//                                       Text(
//                                         shiftRange,
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                           fontSize: 15,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),

//                               /// Break Block
//                               if (breakRange != null && breakTop != null)
//                                 Positioned(
//                                   left: 10,
//                                   right: 6,
//                                   top: breakTop,
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 10,
//                                       vertical: 3,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFFFF3CD),
//                                       borderRadius: BorderRadius.circular(4),
//                                     ),
//                                     child: Text(
//                                       'Lunch Break $breakRange',
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
