import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/classroom/forms/date_picker_normal.dart';
import 'package:wowcare/presentation/features/classroom/views/screens/classroom_info_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_toggle_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class FutureAvailabilityScreen extends StatefulWidget {
  const FutureAvailabilityScreen({super.key});

  static const String routeName = '/dashboard/future-availability';

  @override
  State<FutureAvailabilityScreen> createState() =>
      _FutureAvailabilityScreenState();
}

class _FutureAvailabilityScreenState extends State<FutureAvailabilityScreen> {
  static const double _cellHeightRow = 48;
  static const double _headerHeight = 36;
  static const double _avatarRadius = 14;

  static const Color _tintOtherColumns = Color.fromRGBO(247, 245, 249, 1);
  static const Color _tintHeaderOtherColumns = Color.fromRGBO(245, 243, 247, 1);
  static const Color _classroomColumnBg = Colors.white;
  DateTime _selectedAvailabilityDate = AppTime.now();
  bool _isTwoShifts = true;
  late final FutureAvailabilityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _selectedAvailabilityDate = _normalizedDate(AppTime.now());
    _cubit = serviceLocator<FutureAvailabilityCubit>();
    _loadAvailability();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedAvailabilityDate = _normalizedDate(newDate);
    });
    _loadAvailability();
  }

  void _loadAvailability() {
    _cubit.load(
      date: _selectedAvailabilityDate,
      isTwoShifts: _isTwoShifts,
    );
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
              final picked = await pickNormalDate(
                context: context,
                initialDate: _selectedAvailabilityDate,
                firstDate: DateTime(AppTime.now().year - 2),
                lastDate: DateTime(AppTime.now().year + 5),
              );
              if (picked != null) _onDateChanged(picked);
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
    return BlocProvider<FutureAvailabilityCubit>.value(
      value: _cubit,
      child: GlobalScaffold(
        hasBackButton: false,
        showCustomNavigationBar: true,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(246, 244, 248, 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Full Day',
                              style: TextStyle(
                                fontSize: 15,
                                color: !_isTwoShifts
                                    ? AppColors.primaryColor
                                    : AppColors.primaryColor.withValues(alpha: 0.55),
                                fontWeight:
                                    !_isTwoShifts ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GradientToggleButton(
                              value: _isTwoShifts,
                              onChanged: (value) {
                                setState(() => _isTwoShifts = value);
                                _loadAvailability();
                              },
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '2 Shifts',
                              style: TextStyle(
                                fontSize: 15,
                                color: _isTwoShifts
                                    ? AppColors.primaryColor
                                    : AppColors.primaryColor.withValues(alpha: 0.55),
                                fontWeight:
                                    _isTwoShifts ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: BlocBuilder<FutureAvailabilityCubit,
                                FutureAvailabilityState>(
                              builder: (context, state) {
                                if (state.isLoading) {
                                  return const Center(
                                    child: PrimaryCircularLoader(),
                                  );
                                }

                                final rows = _buildRowsFromGrid(state.grid);

                                if (rows.isEmpty) {
                                  final msg = (state.errorMessage ?? '')
                                      .trim()
                                      .isNotEmpty
                                      ? state.errorMessage!.trim()
                                      : 'No availability data found for the selected date.';
                                  return SizedBox.expand(
                                    child: _buildStretchedMessage(
                                      message: msg,
                                      showRetry: state.errorMessage != null,
                                    ),
                                  );
                                }

                                return _buildTable(rows);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStretchedMessage({
    required String message,
    required bool showRetry,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(247, 245, 249, 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showRetry) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loadAvailability,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<_AvailabilityRow> rows) {
    final List<_AvailabilityRow> data = _getSortedData(rows);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
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
              color: AppColors.primaryColor.withValues(alpha: 0.07),
              width: 0.8,
            ),
            verticalInside: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.07),
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
      ),
    );
  }

  TableRow _buildHeaderRow() {
    if (_isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _buildHeaderCell(
            mainText: 'Classroom',
            backgroundColor: _classroomColumnBg,
            align: TextAlign.left,
          ),
          _buildHeaderCell(
            mainText: 'Morning',
            backgroundColor: _tintHeaderOtherColumns,
          ),
          _buildHeaderCell(
            mainText: 'Afternoon',
            backgroundColor: _tintHeaderOtherColumns,
          ),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _buildHeaderCell(
          mainText: 'Classroom',
          backgroundColor: _classroomColumnBg,
          align: TextAlign.left,
        ),
        _buildHeaderCell(
          mainText: DateFormat('MMM d').format(_selectedAvailabilityDate),
          backgroundColor: _tintHeaderOtherColumns,
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
      height: _headerHeight,
      alignment: Alignment.center,
      color: backgroundColor,
      padding: align == TextAlign.left
          ? const EdgeInsets.only(left: 14)
          : EdgeInsets.zero,
      child: Text(
        mainText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.primaryColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  TableRow _buildDataRow(_AvailabilityRow item) {
    if (_isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _buildClassroomCell(item),
          _buildValueCell(item.firstShiftCount),
          _buildValueCell(item.secondShiftCount),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _buildClassroomCell(item),
        _buildValueCell(item.firstShiftCount),
      ],
    );
  }

  void _openClassroomProfile(_AvailabilityRow item) {
    if (item.roomCode.trim().isEmpty) return;
    // Pass the classroom directly as route arguments (same as the "Class
    // profile" info button on the Classrooms screen) rather than relying on
    // `initialClassroomCode`, which only matches against the staff's
    // attendance-scoped classroom list. Future Availability shows every
    // classroom school-wide, so a scoped-out match would leave the profile
    // screen blank.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClassroomInfoScreen(),
        settings: RouteSettings(
          arguments: Classroom(code: item.roomCode, name: item.roomName),
        ),
      ),
    );
  }

  Widget _buildClassroomCell(_AvailabilityRow item) {
    return Material(
      color: _classroomColumnBg,
      child: InkWell(
        onTap: () => _openClassroomProfile(item),
        child: Container(
          height: _cellHeightRow,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              _buildClassroomAvatar(item),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.roomName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.primaryColor.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCell(int value) {
    return Container(
      height: _cellHeightRow,
      color: _tintOtherColumns,
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _getCountColor(value),
        ),
      ),
    );
  }

  Widget _buildClassroomAvatar(_AvailabilityRow item) {
    return DocumentImageWidget(
      fileUuid: item.roomCode.isNotEmpty ? item.roomCode : item.roomName,
      name: item.roomName,
      mediaAssetCode:
          item.logoAssetCode.trim().isEmpty ? null : item.logoAssetCode,
      classroomCode: item.roomCode.isEmpty ? null : item.roomCode,
      size: _avatarRadius * 2,
      fontSize: 10,
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

  List<_AvailabilityRow> _buildRowsFromGrid(FutureAvailabilityGrid? grid) {
    if (grid == null || grid.classrooms.isEmpty) return const <_AvailabilityRow>[];

    final Map<String, List<FutureAvailabilityEntry>> groupedEntries = <String, List<FutureAvailabilityEntry>>{};
    for (final entry in grid.availability) {
      groupedEntries.putIfAbsent(entry.classroomCode, () => <FutureAvailabilityEntry>[]).add(entry);
    }

    return grid.classrooms.map((classroom) {
      final entries = groupedEntries[classroom.code] ?? const <FutureAvailabilityEntry>[];

      final morning = _findByShift(entries, FutureAvailabilityShift.morning)?.availableSpots ?? 0;
      final afternoon = _findByShift(entries, FutureAvailabilityShift.afternoon)?.availableSpots ?? 0;
      final fullDay =
          _findByShift(entries, FutureAvailabilityShift.fullDay)?.availableSpots ??
          _findByShift(entries, FutureAvailabilityShift.all)?.availableSpots ??
          morning + afternoon;

      return _AvailabilityRow(
        roomCode: classroom.code,
        roomName: classroom.name.trim().isEmpty ? classroom.code : classroom.name,
        logoAssetCode: classroom.logoAssetCode,
        firstShiftCount: _isTwoShifts ? morning : fullDay,
        secondShiftCount: afternoon,
      );
    }).toList();
  }

  FutureAvailabilityEntry? _findByShift(
    List<FutureAvailabilityEntry> entries,
    FutureAvailabilityShift shift,
  ) {
    for (final entry in entries) {
      if (entry.shift == shift) return entry;
    }
    return null;
  }

  DateTime _normalizedDate(DateTime date) => DateTime(date.year, date.month, date.day);
}

class _AvailabilityRow {
  const _AvailabilityRow({
    required this.roomCode,
    required this.roomName,
    required this.logoAssetCode,
    required this.firstShiftCount,
    required this.secondShiftCount,
  });

  final String roomCode;
  final String roomName;
  final String logoAssetCode;
  final int firstShiftCount;
  final int secondShiftCount;
}
