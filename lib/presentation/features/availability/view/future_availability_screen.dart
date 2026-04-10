import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/color_utils.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class FutureAvailabilityScreen extends StatefulWidget {
  const FutureAvailabilityScreen({super.key});

  static const String routeName = '/future-availability';

  @override
  State<FutureAvailabilityScreen> createState() =>
      _FutureAvailabilityScreenState();
}

class _FutureAvailabilityScreenState extends State<FutureAvailabilityScreen> {
  static const double _cellHeightRow = 40;
  DateTime _selectedAvailabilityDate = DateTime.now();
  bool _isTwoShifts = true;

  final List<_AvailabilityRow> _availabilityData = <_AvailabilityRow>[
    _AvailabilityRow(roomName: '1-Blue-D', firstShiftCount: 8, secondShiftCount: 8),
    _AvailabilityRow(roomName: '2-Green-D', firstShiftCount: 6, secondShiftCount: 6),
    _AvailabilityRow(roomName: '3-Purple-D', firstShiftCount: 2, secondShiftCount: 2),
    _AvailabilityRow(roomName: '4-Yellow-D', firstShiftCount: 5, secondShiftCount: 5),
    _AvailabilityRow(roomName: '5-Green-P', firstShiftCount: -2, secondShiftCount: -2),
    _AvailabilityRow(roomName: '6-Pink-P', firstShiftCount: -1, secondShiftCount: -1),
    _AvailabilityRow(roomName: '7-Yellow-P', firstShiftCount: 3, secondShiftCount: 3),
    _AvailabilityRow(roomName: '8-Blue-P', firstShiftCount: 2, secondShiftCount: 2),
  ];

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedAvailabilityDate = newDate;
    });
  }

  Widget _buildAvailabilityDateNavigator() {
    final String formattedDate =
        DateFormat('EEE, MMM d').format(_selectedAvailabilityDate);

    void changeDate(int days) {
      final DateTime newDate = _selectedAvailabilityDate.add(Duration(days: days));
      _onDateChanged(newDate);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => changeDate(-1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.chevron_left,
                size: 24,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          formattedDate,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final Map<String, dynamic>? result =
                  await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => CalendarDialog(
                  isTimePicker: false,
                  initialDate: _selectedAvailabilityDate,
                ),
              );

              if (result != null && result['date'] != null) {
                _onDateChanged(result['date'] as DateTime);
              }
            },
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: SvgPicture.asset(
                MediaRes.calender_icon,
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => changeDate(1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.chevron_right,
                size: 24,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Availability',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildAvailabilityDateNavigator(),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(246, 244, 248, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Full Day',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryColor.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomToggle(
                      label: '',
                      isToggled: _isTwoShifts,
                      onToggle: (bool value) {
                        setState(() {
                          _isTwoShifts = value;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '2 Shifts',
                      style: TextStyle(
                        fontSize: 15,
                        color: _isTwoShifts
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withValues(alpha: 0.65),
                        fontWeight:
                            _isTwoShifts ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final List<_AvailabilityRow> data = _getSortedData(_availabilityData);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: _isTwoShifts
            ? const <int, TableColumnWidth>{
                0: FlexColumnWidth(1.7),
                1: FlexColumnWidth(0.9),
                2: FlexColumnWidth(0.9),
              }
            : const <int, TableColumnWidth>{
                0: FlexColumnWidth(1.7),
                1: FlexColumnWidth(1.2),
              },
        border: TableBorder(
          horizontalInside: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            width: 0.8,
          ),
          verticalInside: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        children: <TableRow>[
          _buildHeaderRow(),
          ...List<TableRow>.generate(
            data.length,
            (int index) => _buildDataRow(data[index]),
          ),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    if (_isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _buildHeaderCell(
            mainText: 'Classroom',
            backgroundColor: const Color.fromRGBO(245, 243, 247, 1),
            align: TextAlign.left,
          ),
          _buildHeaderCell(
            mainText: 'Morning',
            backgroundColor: const Color.fromRGBO(237, 230, 244, 1),
          ),
          _buildHeaderCell(
            mainText: 'Afternoon',
            backgroundColor: const Color.fromRGBO(237, 230, 244, 1),
          ),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _buildHeaderCell(
          mainText: 'Classroom',
          backgroundColor: const Color.fromRGBO(245, 243, 247, 1),
          align: TextAlign.left,
        ),
        _buildHeaderCell(
          mainText: DateFormat('MMM d').format(_selectedAvailabilityDate),
          backgroundColor: const Color.fromRGBO(237, 230, 244, 1),
        ),
      ],
    );
  }

  Widget _buildHeaderCell({
    required String mainText,
    required Color backgroundColor,
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      color: backgroundColor,
      padding: align == TextAlign.left
          ? const EdgeInsets.only(left: 12)
          : EdgeInsets.zero,
      child: Text(
        mainText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.primaryColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  TableRow _buildDataRow(_AvailabilityRow item) {
    if (_isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _buildClassroomCell(item.roomName),
          _buildValueCell(item.firstShiftCount),
          _buildValueCell(item.secondShiftCount),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _buildClassroomCell(item.roomName),
        _buildValueCell(item.firstShiftCount),
      ],
    );
  }

  Widget _buildClassroomCell(String roomName) {
    return Container(
      height: _cellHeightRow,
      color: const Color.fromRGBO(247, 245, 249, 1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          _buildClassroomAvatar(roomName),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              roomName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.primaryColor.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCell(int value) {
    return Container(
      height: _cellHeightRow,
      color: const Color.fromRGBO(237, 230, 244, 1),
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _getCountColor(value),
        ),
      ),
    );
  }

  Widget _buildClassroomAvatar(String roomName) {
    final String initials = StringUtils.getInitials(roomName);
    final Color color = ColorUtils.getColorFromName(roomName);

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.85),
      radius: 10,
      child: Text(
        initials,
        style: TextStyle(
          color: color == Colors.white ? AppColors.primaryColor : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 8,
        ),
      ),
    );
  }

  List<_AvailabilityRow> _getSortedData(List<_AvailabilityRow> data) {
    final List<_AvailabilityRow> numericRooms = <_AvailabilityRow>[];
    final List<_AvailabilityRow> alphaRooms = <_AvailabilityRow>[];

    for (final _AvailabilityRow item in data) {
      final String firstChar =
          item.roomName.trim().isNotEmpty ? item.roomName.trim()[0] : '';
      if (RegExp(r'^\d').hasMatch(firstChar)) {
        numericRooms.add(item);
      } else {
        alphaRooms.add(item);
      }
    }

    numericRooms.sort(
      (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
    );
    alphaRooms.sort(
      (a, b) => a.roomName.toLowerCase().compareTo(b.roomName.toLowerCase()),
    );

    return <_AvailabilityRow>[...numericRooms, ...alphaRooms];
  }

  Color _getCountColor(int count) {
    if (count < 0) return const Color.fromRGBO(236, 99, 99, 1);
    return const Color.fromRGBO(0, 145, 94, 1);
  }
}

class _AvailabilityRow {
  const _AvailabilityRow({
    required this.roomName,
    required this.firstShiftCount,
    required this.secondShiftCount,
  });

  final String roomName;
  final int firstShiftCount;
  final int secondShiftCount;
}
