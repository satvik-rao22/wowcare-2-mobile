// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:intl/intl.dart';

// class AvailabilityCard extends StatefulWidget {
//   const AvailabilityCard({super.key, this.isDashboard = true});

//   final bool isDashboard;

//   @override
//   State<AvailabilityCard> createState() => AvailabilityCardState();
// }

// class AvailabilityCardState extends State<AvailabilityCard> {
//   static const double cellHeightRow = 48;
//   DateTime _selectedAvailabilityDate = DateTime.now();
//   bool _showAllClassrooms = false;
//   static const int _initialDisplayCount = 7;
//   List<RoomDataEntity> _roomDataList = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchRoomsData();
//     _fetchAvailabilityData(_selectedAvailabilityDate);
//   }

//   void refreshData() {
//     _fetchRoomsData();
//     _fetchAvailabilityData(_selectedAvailabilityDate);
//   }

//   void _fetchRoomsData() {
//     DataMap parameters = {
//       'size': '100',
//       'page': '0',
//       'sort': 'name,asc',
//       'status.equals': 'A',
//       'schoolId.equals':
//           '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//     };

//     if (context.currentStaff != null && context.isStaff) {
//       final roomIdsString = context.currentStaff!.rooms
//           .map((room) => room.id)
//           .join(',');

//       parameters.addEntries([MapEntry('id.in', roomIdsString)]);
//     }

//     context.read<RoomdataCubit>().getAllCountRoomdata(parameters: parameters);
//   }

//   void _fetchAvailabilityData(DateTime date) {
//     context.read<AvailabilityCubit>().getAllAvailableCount(
//       parameters: {
//         'startDate': DateFormat('yyyy-MM-dd').format(date),
//         'endDate': DateFormat('yyyy-MM-dd').format(date),
//       },
//     );
//   }

//   void _onDateChanged(DateTime newDate) {
//     setState(() {
//       _selectedAvailabilityDate = newDate;
//     });
//     _fetchAvailabilityData(newDate);
//   }

//   Widget _buildAvailabilityDateNavigator(
//     void Function(DateTime)? onDateChanged,
//   ) {
//     final formattedDate = DateFormat(
//       'EEE, MMM d',
//     ).format(_selectedAvailabilityDate);

//     void _changeDate(int days) {
//       final newDate = _selectedAvailabilityDate.add(Duration(days: days));

//       setState(() {
//         _selectedAvailabilityDate = newDate;
//       });

//       onDateChanged?.call(_selectedAvailabilityDate);
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
//         Material(
//           child: InkWell(
//             onTap: () async {
//               final result = await showDialog<Map<String, dynamic>>(
//                 context: context,
//                 builder: (_) => CalendarDialog(
//                   isTimePicker: false,
//                   initialDate: _selectedAvailabilityDate,
//                 ),
//               );

//               if (result != null && result['date'] != null) {
//                 final selectedDate = result['date'] as DateTime;
//                 setState(() {
//                   _selectedAvailabilityDate = selectedDate;
//                 });
//                 onDateChanged?.call(selectedDate);
//               }
//             },
//             borderRadius: BorderRadius.circular(100),
//             splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
//             child: Padding(
//               padding: const EdgeInsets.all(4),
//               child: SvgPicture.asset(MediaRes.calender_icon),
//             ),
//           ),
//         ),
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
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.cardBorderColor),
//         borderRadius: BorderRadius.circular(12),
//         color: AppColors.cardColor,
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Availability',
//                   style: TextStyle(
//                     color: AppColors.primaryColor,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 _buildAvailabilityDateNavigator(_onDateChanged),
//               ],
//             ),
//           ),
//           BlocConsumer<RoomdataCubit, RoomdataState>(
//             listener: (context, state) {
//               if (state is CountRoomDataLoaded) {
//                 setState(() {
//                   _roomDataList = state.roomList;
//                 });
//               }
//             },
//             builder: (context, state) {
//               return BlocConsumer<AvailabilityCubit, AvailabilityState>(
//                 builder: (context, availabilityState) {
//                   if (availabilityState is GettingAllAvailableCount) {
//                     return const ShimmerLoader(height: 500);
//                   }
//                   if (availabilityState is AllAvailableCountLoaded) {
//                     return _buildTable(availabilityState.availableCount);
//                   }
//                   return const Center(child: Text('No data available'));
//                 },
//                 listener: (context, availabilityState) {},
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTable(List<AvailableCount> data) {
//     if (data.isEmpty) {
//       return const Center(
//         child: Text(
//           'No classroom data available',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       );
//     }

//     final sortedData = _getSortedData(data);

//     final displayedClassrooms = (_showAllClassrooms || !widget.isDashboard)
//         ? sortedData
//         : sortedData.take(_initialDisplayCount).toList();

//     final hasMoreToShow = sortedData.length > _initialDisplayCount;

//     return Column(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Table(
//             columnWidths: const {
//               0: FlexColumnWidth(1.6),
//               1: FlexColumnWidth(0.8),
//               2: FlexColumnWidth(0.8),
//             },
//             border: TableBorder.symmetric(
//               inside: BorderSide(
//                 color: AppColors.primaryColor.withValues(alpha: 0.05),
//               ),
//             ),
//             children: [
//               _buildHeaderRow(),
//               ...List.generate(
//                 displayedClassrooms.length,
//                 (index) => _buildDataRow(
//                   displayedClassrooms[index],
//                   isLast:
//                       index == displayedClassrooms.length - 1 &&
//                       (!hasMoreToShow || !widget.isDashboard),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (hasMoreToShow && widget.isDashboard)
//           InkWell(
//             onTap: () {
//               setState(() {
//                 _showAllClassrooms = !_showAllClassrooms;
//               });
//             },
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               decoration: BoxDecoration(
//                 color: AppColors.primaryColor.withValues(alpha: 0.03),
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(12),
//                   bottomRight: Radius.circular(12),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     (_showAllClassrooms) ? 'Show Less' : 'Show More',
//                     style: const TextStyle(
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   Icon(
//                     _showAllClassrooms
//                         ? Icons.keyboard_arrow_up
//                         : Icons.keyboard_arrow_down,
//                     color: AppColors.primaryColor,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   TableRow _buildHeaderRow() {
//     return TableRow(
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       children: [
//         _buildHeaderCell(
//           mainText: 'Classroom',
//           backgroundColor: const Color.fromRGBO(249, 245, 250, 1),
//         ),
//         _buildHeaderCell(
//           mainText: 'Morning',
//           backgroundColor: const Color.fromRGBO(249, 241, 255, 1),
//         ),
//         _buildHeaderCell(
//           mainText: 'Afternoon',
//           backgroundColor: const Color.fromRGBO(249, 241, 255, 1),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderCell({
//     required String mainText,
//     required Color backgroundColor,
//   }) {
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(color: backgroundColor),
//       child: Column(
//         children: [
//           Expanded(child: Container()),
//           Text(
//             mainText,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Color.fromRGBO(87, 51, 83, 1),
//             ),
//           ),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }

//   RoomDataEntity? _findRoomDataByRoomId(String roomId) {
//     try {
//       return _roomDataList.firstWhere(
//         (room) => room.roomDTO.id.toString() == roomId,
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   TableRow _buildDataRow(AvailableCount item, {bool isLast = false}) {
//     return TableRow(
//       children: [
//         GestureDetector(
//           onTap: () {
//             final roomData = _findRoomDataByRoomId(item.roomId);
//             if (roomData != null) {
//               Navigator.pushNamed(
//                 context,
//                 ClassroomScreen.routeName,
//                 arguments: roomData,
//               );
//             }
//           },
//           child: Container(
//             height: cellHeightRow,
//             color: Colors.white,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   _buildClassroomAvatar(item.roomName),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Tooltip(
//                       message: item.roomName,
//                       preferBelow: false,
//                       child: Text(
//                         item.roomName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 14,
//                           color: Color.fromRGBO(87, 51, 83, 1),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         Container(
//           height: cellHeightRow,
//           color: const Color.fromRGBO(249, 241, 255, 1),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   item.firstShiftCount.toString(),
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: _getCountColor(item.firstShiftCount),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           height: cellHeightRow,
//           decoration: BoxDecoration(
//             color: const Color.fromRGBO(249, 241, 255, 1),
//             borderRadius: isLast
//                 ? const BorderRadius.only(bottomRight: Radius.circular(8))
//                 : BorderRadius.zero,
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   item.secondShiftCount.toString(),
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: _getCountColor(item.secondShiftCount),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildClassroomAvatar(String roomName) {
//     final String initials = StringUtils.getInitials(roomName);
//     final Color color = ColorUtils.getColorFromName(roomName);

//     return CircleAvatar(
//       backgroundColor: color.withValues(alpha: 0.8),
//       radius: 16,
//       child: Text(
//         initials,
//         style: TextStyle(
//           color: color == Colors.white ? AppColors.primaryColor : Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   List<AvailableCount> _getSortedData(List<AvailableCount> data) {
//     final numericRooms = <AvailableCount>[];
//     final alphaRooms = <AvailableCount>[];

//     for (var item in data) {
//       final firstChar = item.roomName.trim().isNotEmpty
//           ? item.roomName.trim()[0]
//           : '';
//       if (RegExp(r'^\d').hasMatch(firstChar)) {
//         numericRooms.add(item);
//       } else {
//         alphaRooms.add(item);
//       }
//     }

//     numericRooms.sort(
//       (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
//     );
//     alphaRooms.sort(
//       (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
//     );

//     return [...numericRooms, ...alphaRooms];
//   }

//   Color _getCountColor(int count) {
//     if (count < 0) return Colors.red;
//     return Colors.teal;
//   }
// }
