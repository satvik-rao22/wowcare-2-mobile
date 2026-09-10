import 'package:flutter/material.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/availability/view_model/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/classroom/forms/date_picker_normal.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_toggle_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class FutureAvailabilityScreen extends StatefulWidget {
  const FutureAvailabilityScreen({super.key});

  static const String routeName = DashboardRoutes.futureAvailability;

  @override
  State<FutureAvailabilityScreen> createState() =>
      _FutureAvailabilityScreenState();
}

class _FutureAvailabilityScreenState extends State<FutureAvailabilityScreen> {
  DateTime _selectedAvailabilityDate = AppTime.now();
  bool _isTwoShifts = true;
  late final FutureAvailabilityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _selectedAvailabilityDate = _normalizedDate(AppTime.now());
    // Provided by the `future-availability` GoRoute's BlocProvider — the
    // route owns creation/disposal, this screen only consumes it.
    _cubit = context.read<FutureAvailabilityCubit>();
    _loadAvailability();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedAvailabilityDate = _normalizedDate(newDate);
    });
    _loadAvailability();
  }

  void _loadAvailability() {
    _cubit.load(date: _selectedAvailabilityDate, isTwoShifts: _isTwoShifts);
  }

  void _openClassroomProfile(_AvailabilityRow item) {
    if (item.roomCode.trim().isEmpty) return;
    // Pass the classroom directly via `extra` (same as the "Class profile"
    // info button on the Classrooms screen) rather than relying on the
    // `classroomCode` query param, which only matches against the staff's
    // attendance-scoped classroom list. Future Availability shows every
    // classroom school-wide, so a scoped-out match would leave the profile
    // screen blank.
    context.push(
      '/dashboard/classroom-info-screen',
      extra: Classroom(code: item.roomCode, name: item.roomName),
    );
  }

  DateTime _normalizedDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
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
                  style: AppTextStyles.futureAvailabilityTitle,
                ),
                _DateNavigator(
                  selectedDate: _selectedAvailabilityDate,
                  onDateChanged: _onDateChanged,
                ),
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
                  color: AppColors.cardColor,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.blackColor.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ShiftToggleRow(
                      isTwoShifts: _isTwoShifts,
                      onChanged: (value) {
                        setState(() => _isTwoShifts = value);
                        _loadAvailability();
                      },
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child:
                              BlocBuilder<
                                FutureAvailabilityCubit,
                                FutureAvailabilityState
                              >(
                                builder: (context, state) {
                                  if (state.isLoading) {
                                    return const Center(
                                      child: PrimaryCircularLoader(),
                                    );
                                  }

                                  final rows = _buildRowsFromGrid(
                                    state.grid,
                                    isTwoShifts: _isTwoShifts,
                                  );

                                  if (rows.isEmpty) {
                                    final msg =
                                        (state.errorMessage ?? '')
                                            .trim()
                                            .isNotEmpty
                                        ? state.errorMessage!.trim()
                                        : 'No availability data found for the selected date.';
                                    return SizedBox.expand(
                                      child: _StretchedMessage(
                                        message: msg,
                                        onRetry: state.errorMessage != null
                                            ? _loadAvailability
                                            : null,
                                      ),
                                    );
                                  }

                                  return _AvailabilityTable(
                                    rows: rows,
                                    isTwoShifts: _isTwoShifts,
                                    selectedDate: _selectedAvailabilityDate,
                                    onOpenClassroomProfile:
                                        _openClassroomProfile,
                                  );
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
    );
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEE, MMM d').format(selectedDate);

    void changeDate(int days) =>
        onDateChanged(selectedDate.add(Duration(days: days)));

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
          style: AppTextStyles.futureAvailabilityDateNavLabel,
        ),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final picked = await pickNormalDate(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(AppTime.now().year - 2),
                lastDate: DateTime(AppTime.now().year + 5),
              );
              if (picked != null) onDateChanged(picked);
            },
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: AppIcon(MediaRes.calender_icon, width: 20, height: 20),
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
}

class _ShiftToggleRow extends StatelessWidget {
  const _ShiftToggleRow({required this.isTwoShifts, required this.onChanged});

  final bool isTwoShifts;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.futureAvailabilityToggleTrackBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Full Day',
            style: AppTextStyles.futureAvailabilityShiftToggleLabel(
              isSelected: !isTwoShifts,
            ),
          ),
          const SizedBox(width: 10),
          GradientToggleButton(value: isTwoShifts, onChanged: onChanged),
          const SizedBox(width: 10),
          Text(
            '2 Shifts',
            style: AppTextStyles.futureAvailabilityShiftToggleLabel(
              isSelected: isTwoShifts,
            ),
          ),
        ],
      ),
    );
  }
}

class _StretchedMessage extends StatelessWidget {
  const _StretchedMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.futureAvailabilityColumnTint,
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
                style: AppTextStyles.futureAvailabilityEmptyMessage,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 10),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityTable extends StatelessWidget {
  const _AvailabilityTable({
    required this.rows,
    required this.isTwoShifts,
    required this.selectedDate,
    required this.onOpenClassroomProfile,
  });

  final List<_AvailabilityRow> rows;
  final bool isTwoShifts;
  final DateTime selectedDate;
  final ValueChanged<_AvailabilityRow> onOpenClassroomProfile;

  static const double _cellHeightRow = 48;
  static const double _headerHeight = 36;
  static const double _avatarRadius = 14;

  List<_AvailabilityRow> _sorted(List<_AvailabilityRow> data) {
    final List<_AvailabilityRow> numericRooms = <_AvailabilityRow>[];
    final List<_AvailabilityRow> alphaRooms = <_AvailabilityRow>[];

    for (final _AvailabilityRow item in data) {
      final String firstChar = item.roomName.trim().isNotEmpty
          ? item.roomName.trim()[0]
          : '';
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

  TableRow _headerRow() {
    if (isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _HeaderCell(
            mainText: 'Classroom',
            backgroundColor: AppColors.cardColor,
            align: TextAlign.left,
            height: _headerHeight,
          ),
          _HeaderCell(
            mainText: 'Morning',
            backgroundColor: AppColors.futureAvailabilityHeaderTint,
            height: _headerHeight,
          ),
          _HeaderCell(
            mainText: 'Afternoon',
            backgroundColor: AppColors.futureAvailabilityHeaderTint,
            height: _headerHeight,
          ),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _HeaderCell(
          mainText: 'Classroom',
          backgroundColor: AppColors.cardColor,
          align: TextAlign.left,
          height: _headerHeight,
        ),
        _HeaderCell(
          mainText: DateFormat('MMM d').format(selectedDate),
          backgroundColor: AppColors.futureAvailabilityHeaderTint,
          height: _headerHeight,
        ),
      ],
    );
  }

  TableRow _dataRow(_AvailabilityRow item) {
    if (isTwoShifts) {
      return TableRow(
        children: <Widget>[
          _ClassroomCell(
            item: item,
            height: _cellHeightRow,
            avatarSize: _avatarRadius * 2,
            onTap: () => onOpenClassroomProfile(item),
          ),
          _ValueCell(value: item.firstShiftCount, height: _cellHeightRow),
          _ValueCell(value: item.secondShiftCount, height: _cellHeightRow),
        ],
      );
    }

    return TableRow(
      children: <Widget>[
        _ClassroomCell(
          item: item,
          height: _cellHeightRow,
          avatarSize: _avatarRadius * 2,
          onTap: () => onOpenClassroomProfile(item),
        ),
        _ValueCell(value: item.firstShiftCount, height: _cellHeightRow),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _sorted(rows);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: isTwoShifts
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
          children: <TableRow>[_headerRow(), ...data.map(_dataRow)],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.mainText,
    required this.backgroundColor,
    required this.height,
    this.align = TextAlign.center,
  });

  final String mainText;
  final Color backgroundColor;
  final double height;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
        style: AppTextStyles.futureAvailabilityHeaderCellText,
      ),
    );
  }
}

class _ClassroomCell extends StatelessWidget {
  const _ClassroomCell({
    required this.item,
    required this.height,
    required this.avatarSize,
    required this.onTap,
  });

  final _AvailabilityRow item;
  final double height;
  final double avatarSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              DocumentImageWidget(
                fileUuid: item.roomCode.isNotEmpty
                    ? item.roomCode
                    : item.roomName,
                name: item.roomName,
                mediaAssetCode: item.logoAssetCode.trim().isEmpty
                    ? null
                    : item.logoAssetCode,
                classroomCode: item.roomCode.isEmpty ? null : item.roomCode,
                size: avatarSize,
                fontSize: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.roomName,
                  style: AppTextStyles.futureAvailabilityClassroomName,
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
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value, required this.height});

  final int value;
  final double height;

  Color get _countColor => value < 0
      ? AppColors.futureAvailabilityNegativeCountColor
      : AppColors.futureAvailabilityPositiveCountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.futureAvailabilityColumnTint,
      alignment: Alignment.center,
      child: Text(
        value.toString(),
        style: AppTextStyles.futureAvailabilityCountValue(color: _countColor),
      ),
    );
  }
}

List<_AvailabilityRow> _buildRowsFromGrid(
  FutureAvailabilityGrid? grid, {
  required bool isTwoShifts,
}) {
  if (grid == null || grid.classrooms.isEmpty)
    return const <_AvailabilityRow>[];

  final Map<String, List<FutureAvailabilityEntry>> groupedEntries =
      <String, List<FutureAvailabilityEntry>>{};
  for (final entry in grid.availability) {
    groupedEntries
        .putIfAbsent(entry.classroomCode, () => <FutureAvailabilityEntry>[])
        .add(entry);
  }

  return grid.classrooms.map((classroom) {
    final entries =
        groupedEntries[classroom.code] ?? const <FutureAvailabilityEntry>[];

    final morning =
        _findByShift(
          entries,
          FutureAvailabilityShift.morning,
        )?.availableSpots ??
        0;
    final afternoon =
        _findByShift(
          entries,
          FutureAvailabilityShift.afternoon,
        )?.availableSpots ??
        0;
    final fullDay =
        _findByShift(
          entries,
          FutureAvailabilityShift.fullDay,
        )?.availableSpots ??
        _findByShift(entries, FutureAvailabilityShift.all)?.availableSpots ??
        morning + afternoon;

    return _AvailabilityRow(
      roomCode: classroom.code,
      roomName: classroom.name.trim().isEmpty ? classroom.code : classroom.name,
      logoAssetCode: classroom.logoAssetCode,
      firstShiftCount: isTwoShifts ? morning : fullDay,
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
