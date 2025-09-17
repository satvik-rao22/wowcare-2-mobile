// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// import '../../res/colors.dart';
// import '../../res/media_res.dart';
// import '../../util/TimeZoneConfiguration.dart';
// import '../../util/date_utils.dart';
// import 'calendar_responsive_helper.dart';

// class CustomDateTimeField extends StatefulWidget {
//   const CustomDateTimeField({
//     this.label,
//     this.hasLabel = true,
//     this.isTime = false,
//     this.isRangePicker = false,
//     this.onDateSelected,
//     this.onTimeSelected,
//     this.initialDate,
//     this.initialTime,
//     this.onHourChanged,
//     this.onMinuteChanged,
//     this.onPeriodChanged,
//     this.onRangeSelected,
//     this.fetchInitialTime = true, // New property to control fetch behavior
//     this.isDisabled = false,
//     super.key,
//   });

//   final String? label;
//   final bool hasLabel;
//   final bool isTime;
//   final bool isRangePicker;
//   final ValueChanged<DateTime>? onDateSelected;
//   final ValueChanged<TimeOfDay>? onTimeSelected;
//   final DateTime? initialDate;
//   final TimeOfDay? initialTime;
//   final bool fetchInitialTime; // Control whether to fetch current time
//   final bool isDisabled;

//   // Add callbacks for individual time components
//   final ValueChanged<String>? onHourChanged;
//   final ValueChanged<String>? onMinuteChanged;
//   final ValueChanged<String>? onPeriodChanged;

//   // Add callback for date range selection
//   final Function(DateTime, DateTime?)? onRangeSelected;

//   @override
//   State<CustomDateTimeField> createState() => _CustomDateTimeFieldState();
// }

// class _CustomDateTimeFieldState extends State<CustomDateTimeField> {
//   String? selectedValue;
//   DateTime? selectedDate;
//   DateTime? rangeEndDate;
//   TimeOfDay? selectedTime;
//   String? hour;
//   String? minute;
//   String? period;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize with provided initialDate if available
//     if (widget.initialDate != null) {
//       selectedDate = widget.initialDate;
//       _updateDisplayValue();
//     }

//     // Initialize with provided initialTime if available
//     if (widget.initialTime != null) {
//       selectedTime = widget.initialTime;
//       if (widget.isTime) {
//         _updateTimeComponents(selectedTime!);
//       }
//       _updateDisplayValue();
//     }

//     // Only fetch current date/time if fetchInitialTime is true
//     if (widget.fetchInitialTime) {
//       setCurrentDateTime().then((_) {
//         // If it's a range picker, default to current month's range based on adjusted date
//         if (widget.isRangePicker) {
//           if (selectedDate != null) {
//             // Set to first day of current month from the timezone-adjusted date
//             selectedDate = DateTime(selectedDate!.year, selectedDate!.month, 1);

//             // Calculate last day of month based on timezone-adjusted date
//             final lastDayOfMonth = DateTime(
//               selectedDate!.year,
//               selectedDate!.month + 1,
//               0,
//               23,
//               59,
//               59,
//             );
//             rangeEndDate = lastDayOfMonth;
//           }
//         }

//         // Update display after timezone adjustment
//         _updateDisplayValue();

//         // If time component is needed, update time components
//         if (widget.isTime && selectedTime != null) {
//           _updateTimeComponents(selectedTime!);
//         }
//       });
//     }
//   }

//   // Modified to return Future so we can await it

//   Future<void> setCurrentDateTime() async {
//     String dateformated = await convertDateTimeNowToTimeZoneOne(context);
//     String formattedDate = '$dateformated';
//     DateTime dateTime = DateTime.parse(formattedDate);
//     setState(() {
//       selectedDate = dateTime; // Store the entire dateTime object
//       selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
//     });
//   }

//   @override
//   void didUpdateWidget(covariant CustomDateTimeField oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (widget.isTime && widget.initialTime != oldWidget.initialTime) {
//       setState(() {
//         selectedTime = widget.initialTime!;
//         _updateTimeComponents(selectedTime!);
//         _updateDisplayValue();
//       });
//     }

//     if (!widget.isTime &&
//         widget.initialDate != null &&
//         widget.initialDate != oldWidget.initialDate) {
//       setState(() {
//         selectedDate = widget.initialDate!;
//         _updateDisplayValue();
//       });
//     }
//   }

//   void _updateTimeComponents(TimeOfDay time) {
//     hour = time.hourOfPeriod == 0 ? '12' : time.hourOfPeriod.toString();
//     minute = time.minute.toString().padLeft(2, '0');
//     period = time.period == DayPeriod.am ? 'AM' : 'PM';

//     // Call the callbacks if provided
//     widget.onHourChanged?.call(hour!);
//     widget.onMinuteChanged?.call(minute!);
//     widget.onPeriodChanged?.call(period!);
//   }

//   void _updateDisplayValue() {
//     if (widget.isRangePicker) {
//       if (selectedDate != null) {
//         if (rangeEndDate != null) {
//           selectedValue =
//               "${DateUtilsNew.formatToReadableDate(selectedDate!)} - ${DateUtilsNew.formatToReadableDate(rangeEndDate!)}";
//         } else {
//           selectedValue = DateUtilsNew.formatToReadableDate(selectedDate!);
//         }
//       }
//     } else if (widget.isTime) {
//       if (selectedTime != null) {
//         final hourDisplay = selectedTime!.hourOfPeriod == 0
//             ? '12'
//             : selectedTime!.hourOfPeriod.toString();
//         selectedValue =
//             "$hourDisplay:${selectedTime!.minute.toString().padLeft(2, '0')} ${selectedTime!.period == DayPeriod.am ? 'AM' : 'PM'}";
//       }
//     } else {
//       if (selectedDate != null) {
//         selectedValue = DateUtilsNew.formatToReadableDate(selectedDate!);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final calHelper = CalendarResponsiveHelper(context);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (widget.hasLabel && widget.label != null)
//           Text(
//             widget.label!,
//             style: TextStyle(
//               color: AppColors.primaryColor.withValues(alpha: 0.5),
//               fontSize: calHelper.headerFontSize * 0.7,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         if (widget.hasLabel && widget.label != null)
//           SizedBox(height: calHelper.calendarPadding * 0.75),
//         GestureDetector(
//           onTap: () async {
//             if (widget.isDisabled == true) {
//               return; // Prevent interaction if disabled
//             }
//             final result = await showDialog(
//               context: context,
//               builder: (_) => CalendarDialog(
//                 isRangePicker: widget.isRangePicker,
//                 isTimePicker: widget.isTime,
//                 initialDate: selectedDate,
//                 initialTime: selectedTime,
//                 initialEndDate: rangeEndDate,
//               ),
//             );
//             if (result != null) {
//               setState(() {
//                 if (widget.isRangePicker) {
//                   // Handle range selection
//                   if (result['startDate'] != null &&
//                       result['startDate'] is DateTime) {
//                     selectedDate = result['startDate'];
//                     rangeEndDate = result['endDate'] is DateTime
//                         ? result['endDate']
//                         : null;
//                     widget.onRangeSelected?.call(selectedDate!, rangeEndDate);
//                   }
//                 } else if (widget.isTime) {
//                   // Handle time selection
//                   final time = result['time'] as TimeOfDay;
//                   selectedTime = time;

//                   // Update time components and notify parent
//                   _updateTimeComponents(time);
//                   widget.onTimeSelected?.call(selectedTime!);
//                 } else {
//                   // Handle single date selection
//                   if (result['date'] != null && result['date'] is DateTime) {
//                     selectedDate = result['date'];
//                     widget.onDateSelected?.call(selectedDate!);
//                   }
//                 }

//                 // Update the display value
//                 _updateDisplayValue();
//               });
//             }
//           },
//           child: Container(
//             constraints: BoxConstraints(minHeight: calHelper.dayCellSize * 1.2),
//             padding: EdgeInsets.symmetric(
//               horizontal: calHelper.calendarPadding,
//             ),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: widget.isDisabled == true
//                   ? const Color(0xFFF8F7FA).withValues(alpha: 0.5)
//                   : AppColors.fieldBackgroundColor,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     selectedValue ??
//                         (widget.isTime
//                             ? 'Select Time'
//                             : widget.isRangePicker
//                             ? 'Select Date Range'
//                             : 'Select Date'),
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: calHelper.dayFontSize,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 SvgPicture.asset(
//                   widget.isTime ? MediaRes.clock_icon : MediaRes.calender_icon,
//                   width: calHelper.dayCellSize * 0.7,
//                   height: calHelper.dayCellSize * 0.7,
//                   colorFilter: ColorFilter.mode(
//                     AppColors.primaryColor.withValues(
//                       alpha: widget.isDisabled == true ? 0.5 : 1.0,
//                     ),
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // Getter methods to access selected date and time
//   DateTime? get date => selectedDate;
//   DateTime? get endDate => rangeEndDate;
//   TimeOfDay? get time => selectedTime;
//   String get getHour => hour ?? '';
//   String get getMinute => minute ?? '';
//   String get getPeriod => period ?? '';
// }
