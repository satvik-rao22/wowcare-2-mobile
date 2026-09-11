import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/staff/entities/staff_important_date.dart';
import 'package:wowcare/presentation/features/staff/view_model/important_dates_cubit.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_dates_tab_widgets.dart';
import 'package:wowcare/core/router/app_routes.dart' show StaffRoutes;
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';

class StaffDatesTab extends StatelessWidget {
  const StaffDatesTab({
    super.key,
    required this.staffCode,
    this.canEdit = false,
  });

  final String staffCode;

  /// Whether the current persona may edit this staff member's important dates
  /// (resolved by the parent screen from STAFF module write access; a staff
  /// persona is additionally scoped to their own profile). When false, no edit
  /// affordance is rendered at all.
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    // Cubits are created by the route builder (§1.6), not here.
    return _StaffDatesTabView(staffCode: staffCode, canEdit: canEdit);
  }
}

class _StaffDatesTabView extends StatefulWidget {
  const _StaffDatesTabView({required this.staffCode, this.canEdit = false});

  final String staffCode;
  final bool canEdit;

  @override
  State<_StaffDatesTabView> createState() => _StaffDatesTabViewState();
}

class _StaffDatesTabViewState extends State<_StaffDatesTabView> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, String> _datesByType = {};

  /// Full list from API/cache for passing to edit screen and Physical Checkup display.
  List<StaffImportantDate> _importantDatesList = [];

  late final ImportantDatesCubit _importantDatesCubit;

  @override
  void initState() {
    super.initState();
    _importantDatesCubit = context.read<ImportantDatesCubit>();
    _loadDates();
  }

  Future<void> _loadDates({bool useCache = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cache-first read routed through the cubit (cached list when available,
      // otherwise the API). Same transform for both sources, as before.
      final dates = await _importantDatesCubit.fetchImportantDates(
        widget.staffCode,
        useCache: useCache,
      );

      if (!mounted) return;

      _datesByType.clear();
      _importantDatesList = List.of(dates);
      for (final date in dates) {
        final type = date.importantDateType.toUpperCase();
        final dueDate = date.dueDate;
        if (type.isEmpty || dueDate.isEmpty) continue;
        _datesByType[type] = _formatDate(dueDate);
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = failure.message ?? 'Failed to load important dates';
        _datesByType.clear();
        _importantDatesList = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load important dates';
        _datesByType.clear();
        _importantDatesList = [];
      });
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _displayFormatter.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _getDateForType(String type) {
    return _datesByType[type.toUpperCase()] ?? '';
  }

  StaffImportantDate? _getEntryByType(String type) {
    final key = type.toUpperCase();
    for (final e in _importantDatesList) {
      if (e.importantDateType.toUpperCase() == key) return e;
    }
    return null;
  }

  DateTime? _parseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  /// Maps API status (OVERDUE, SCHEDULED, COMPLETED) to edit-screen dropdown value.
  String? _apiStatusToDropdown(String? apiStatus) {
    if (apiStatus == null) return null;
    switch (apiStatus.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'OVERDUE':
      case 'SCHEDULED':
        return 'Scheduled';
      default:
        return 'Scheduled';
    }
  }

  Widget _buildPhysicalCheckupSection() {
    final physical = _getEntryByType('PHYSICAL_CHECKUP');
    if (physical == null) {
      return const SizedBox.shrink();
    }

    const completedColor = Color.fromRGBO(56, 200, 32, 1);
    const completedBg = Color.fromRGBO(56, 200, 32, 0.1);
    const dueColor = Color.fromRGBO(234, 186, 0, 1);
    const dueBg = Color.fromRGBO(234, 186, 0, 0.12);
    const overdueColor = Color.fromRGBO(232, 45, 45, 1);
    const overdueBg = Color.fromRGBO(232, 45, 45, 0.12);
    const scheduledColor = Color.fromRGBO(30, 94, 255, 1);
    const scheduledBg = Color.fromRGBO(30, 94, 255, 0.12);

    final statusUpper = (physical.status ?? '').toUpperCase();
    final dueDate = physical.dueDate.trim();
    final completedDate = (physical.completedDate ?? '').trim();
    final bool isCompleted = statusUpper == 'COMPLETED';
    // The "more" action only opens the edit dialog, so it follows the same
    // write gate as the Important Dates pencil.
    final bool showMore = !isCompleted && widget.canEdit;
    final cards = <Widget>[];

    if (dueDate.isNotEmpty) {
      String dueLabel;
      String editStatusUi;
      Color dueLabelColor;
      Color dueLabelBg;
      switch (statusUpper) {
        case 'COMPLETED':
          dueLabel = 'Completed';
          editStatusUi = 'Completed';
          dueLabelColor = completedColor;
          dueLabelBg = completedBg;
          break;
        case 'DUE':
          dueLabel = 'Due';
          editStatusUi = 'Due';
          dueLabelColor = dueColor;
          dueLabelBg = dueBg;
          break;
        case 'OVERDUE':
          dueLabel = 'Overdue';
          // Keep edit dropdown compatible (it doesn't have "Overdue").
          editStatusUi = 'Due';
          dueLabelColor = overdueColor;
          dueLabelBg = overdueBg;
          break;
        default:
          dueLabel = 'Scheduled';
          editStatusUi = 'Scheduled';
          dueLabelColor = scheduledColor;
          dueLabelBg = scheduledBg;
      }
      cards.add(
        PhysicalCard(
          statusLabel: dueLabel,
          statusColor: dueLabelColor,
          statusBg: dueLabelBg,
          date: _formatDate(dueDate),
          showMore: showMore,
          onMore: showMore
              ? () => _openEditPhysicalDialog(
                  initialDateIso: dueDate,
                  initialStatusUi: editStatusUi,
                )
              : null,
        ),
      );
    }

    if (completedDate.isNotEmpty) {
      cards.add(
        PhysicalCard(
          statusLabel: 'Completed',
          statusColor: completedColor,
          statusBg: completedBg,
          date: _formatDate(completedDate),
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Physical Checkup',
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.5),
            fontSize: 16,
            letterSpacing: 14 * (-3 / 100),
          ),
        ),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Future<void> _openEditPhysicalDialog({
    required String initialDateIso,
    required String initialStatusUi,
  }) async {
    if (!mounted) return;

    DateTime? selectedDate;
    try {
      selectedDate = initialDateIso.isNotEmpty
          ? DateTime.parse(initialDateIso)
          : null;
    } catch (_) {
      selectedDate = null;
    }
    String statusUi = initialStatusUi.isNotEmpty
        ? initialStatusUi
        : 'Scheduled';

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (context) {
        final isTablet = ResponsiveHelper(context).isTabletCompact;
        final isLargeTablet = ResponsiveHelper(context).isWide;
        final bottomSafe = MediaQuery.of(context).padding.bottom;

        final horizontalPadding = isLargeTablet
            ? 32.0
            : (isTablet ? 24.0 : 16.0);
        final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
        final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeTablet ? 1200.0 : double.infinity,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: verticalPadding,
                    bottom: verticalPadding + bottomSafe,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Physical Examination',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: verticalPadding),
                      if (isTablet)
                        Row(
                          children: [
                            Expanded(
                              child: DialogField(
                                label: 'Physical Checkup Date *',
                                value: selectedDate != null
                                    ? _displayFormatter.format(selectedDate!)
                                    : '',
                                suffix: SvgPicture.asset(
                                  MediaRes.calender_icon,
                                  height: 20.0,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.primaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () async {
                                  final now = AppTime.now();
                                  final today = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  );
                                  final statusUpper = statusUi
                                      .trim()
                                      .toUpperCase();
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) => CalendarDialog(
                                          isRangePicker: false,
                                          isTimePicker: false,
                                          initialDate: selectedDate,
                                          firstDate: statusUpper == 'COMPLETED'
                                              ? null
                                              : today,
                                          lastDate: statusUpper == 'COMPLETED'
                                              ? today
                                              : null,
                                        ),
                                      );
                                  if (result == null || result['date'] == null)
                                    return;
                                  final picked = result['date'] as DateTime;
                                  final pickedOnly = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                  );
                                  if ((statusUpper == 'DUE' ||
                                          statusUpper == 'SCHEDULED' ||
                                          statusUpper == 'OVERDUE') &&
                                      pickedOnly.isBefore(today)) {
                                    if (!context.mounted) return;
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          'For Due/Scheduled status, Physical Checkup Date must be today or future',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  if (statusUpper == 'COMPLETED' &&
                                      pickedOnly.isAfter(today)) {
                                    if (!context.mounted) return;
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          'For Completed status, Physical Checkup Date must be today or past',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  setLocalState(() => selectedDate = picked);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DialogDropdown(
                                label: 'Status *',
                                value: statusUi,
                                options: const [
                                  'Due',
                                  'Scheduled',
                                  'Completed',
                                ],
                                onChanged: (v) {
                                  setLocalState(() => statusUi = v);
                                  if (selectedDate == null) return;
                                  final now = AppTime.now();
                                  final today = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                  );
                                  final pickedOnly = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                  );
                                  final statusUpper = statusUi
                                      .trim()
                                      .toUpperCase();
                                  final isDueScheduled =
                                      statusUpper == 'DUE' ||
                                      statusUpper == 'SCHEDULED' ||
                                      statusUpper == 'OVERDUE';

                                  if (isDueScheduled &&
                                      pickedOnly.isBefore(today)) {
                                    setLocalState(() => selectedDate = null);
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          'For Due/Scheduled status, Physical Checkup Date must be today or future',
                                      isError: true,
                                    );
                                    return;
                                  }
                                  if (statusUpper == 'COMPLETED' &&
                                      pickedOnly.isAfter(today)) {
                                    setLocalState(() => selectedDate = null);
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          'For Completed status, Physical Checkup Date must be today or past',
                                      isError: true,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            DialogField(
                              label: 'Physical Checkup Date *',
                              value: selectedDate != null
                                  ? _displayFormatter.format(selectedDate!)
                                  : '',
                              suffix: SvgPicture.asset(
                                MediaRes.calender_icon,
                                height: 20.0,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onTap: () async {
                                final now = AppTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final statusUpper = statusUi
                                    .trim()
                                    .toUpperCase();
                                final result =
                                    await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => CalendarDialog(
                                        isRangePicker: false,
                                        isTimePicker: false,
                                        initialDate: selectedDate,
                                        firstDate: statusUpper == 'COMPLETED'
                                            ? null
                                            : today,
                                        lastDate: statusUpper == 'COMPLETED'
                                            ? today
                                            : null,
                                      ),
                                    );
                                if (result == null || result['date'] == null)
                                  return;
                                final picked = result['date'] as DateTime;
                                final pickedOnly = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                                if ((statusUpper == 'DUE' ||
                                        statusUpper == 'SCHEDULED' ||
                                        statusUpper == 'OVERDUE') &&
                                    pickedOnly.isBefore(today)) {
                                  if (!context.mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        'For Due/Scheduled status, Physical Checkup Date must be today or future',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (statusUpper == 'COMPLETED' &&
                                    pickedOnly.isAfter(today)) {
                                  if (!context.mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        'For Completed status, Physical Checkup Date must be today or past',
                                    isError: true,
                                  );
                                  return;
                                }
                                setLocalState(() => selectedDate = picked);
                              },
                            ),
                            const SizedBox(height: 16),
                            DialogDropdown(
                              label: 'Status *',
                              value: statusUi,
                              options: const ['Due', 'Scheduled', 'Completed'],
                              onChanged: (v) {
                                setLocalState(() => statusUi = v);
                                if (selectedDate == null) return;
                                final now = AppTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final pickedOnly = DateTime(
                                  selectedDate!.year,
                                  selectedDate!.month,
                                  selectedDate!.day,
                                );
                                final statusUpper = statusUi
                                    .trim()
                                    .toUpperCase();
                                final isDueScheduled =
                                    statusUpper == 'DUE' ||
                                    statusUpper == 'SCHEDULED' ||
                                    statusUpper == 'OVERDUE';

                                if (isDueScheduled &&
                                    pickedOnly.isBefore(today)) {
                                  setLocalState(() => selectedDate = null);
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        'For Due/Scheduled status, Physical Checkup Date must be today or future',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (statusUpper == 'COMPLETED' &&
                                    pickedOnly.isAfter(today)) {
                                  setLocalState(() => selectedDate = null);
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        'For Completed status, Physical Checkup Date must be today or past',
                                    isError: true,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      SizedBox(height: verticalPadding),
                      Builder(
                        builder: (_) {
                          final now = AppTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final hasDate = selectedDate != null;
                          final picked = selectedDate;
                          final currentStatus = statusUi.trim();
                          final statusUpper = currentStatus.toUpperCase();

                          String? validationMessage;
                          if (hasDate) {
                            final pickedOnly = DateTime(
                              picked!.year,
                              picked.month,
                              picked.day,
                            );

                            final bool isDueScheduled =
                                statusUpper == 'DUE' ||
                                statusUpper == 'OVERDUE' ||
                                statusUpper == 'SCHEDULED';
                            final bool isCompleted = statusUpper == 'COMPLETED';

                            // Enforce the status-specific constraints live in UI.
                            if (isDueScheduled && pickedOnly.isBefore(today)) {
                              validationMessage =
                                  'For Due/Scheduled status, Physical Checkup Date must be today or future';
                            } else if (isCompleted &&
                                pickedOnly.isAfter(today)) {
                              validationMessage =
                                  'For Completed status, Physical Checkup Date must be today or past';
                            }
                          }

                          final canSave = hasDate && validationMessage == null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (validationMessage != null) ...[
                                Text(
                                  validationMessage,
                                  style: const TextStyle(
                                    color: AppColors.errorColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              CustomButtonLayout(
                                confirmButtonLabel: 'Save',
                                cancelButtonLabel: 'Cancel',
                                isForm: false,
                                isLoading: isSaving,
                                onPressedCancel: () =>
                                    Navigator.of(context).pop(),
                                onPressedConfirm: canSave
                                    ? () async {
                                        if (!canSave) return;

                                        final dueIso = _apiFormatter.format(
                                          picked!,
                                        );
                                        final statusApi =
                                            statusUpper == 'COMPLETED'
                                            ? 'COMPLETED'
                                            : statusUpper == 'SCHEDULED'
                                            ? 'SCHEDULED'
                                            : 'DUE';

                                        // Preserve any existing completed date
                                        // (the read-only "Completed" card) when
                                        // this edit isn't itself marking the
                                        // checkup completed — otherwise the
                                        // backend nulls it and that card vanishes.
                                        final existingCompleted =
                                            (_getEntryByType(
                                                      'PHYSICAL_CHECKUP',
                                                    )?.completedDate ??
                                                    '')
                                                .trim();
                                        final payload = StaffImportantDate(
                                          importantDateType: 'PHYSICAL_CHECKUP',
                                          dueDate: dueIso,
                                          status: statusApi,
                                          completedDate:
                                              statusApi == 'COMPLETED'
                                              ? dueIso
                                              : (existingCompleted.isNotEmpty
                                                    ? existingCompleted
                                                    : null),
                                        );

                                        setLocalState(() => isSaving = true);
                                        try {
                                          await _importantDatesCubit
                                              .updateImportantDates(
                                                staffCode: widget.staffCode,
                                                dates: [payload],
                                              );
                                          if (!context.mounted) return;
                                          final cubitState =
                                              _importantDatesCubit.state;
                                          if (cubitState.isSuccess) {
                                            final msg =
                                                cubitState.message ?? '';
                                            CoreUtils.showTopSnackBar(
                                              context: context,
                                              message: msg.isNotEmpty
                                                  ? msg
                                                  : 'Updated successfully',
                                              isSuccess: true,
                                            );
                                            Navigator.of(context).pop();
                                            await _loadDates(useCache: false);
                                          } else {
                                            CoreUtils.logApiError(
                                              cubitState.message ?? '',
                                            );
                                            CoreUtils.showTopSnackBar(
                                              context: context,
                                              message:
                                                  'Failed to update physical checkup. Please try again.',
                                              isError: true,
                                            );
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setLocalState(
                                              () => isSaving = false,
                                            );
                                          }
                                        }
                                      }
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hireDate = _getDateForType('HIRE_DATE');
    final cdaDate = _getDateForType('CDA');
    final firstAidDate = _getDateForType('FIRST_AID_CPR');
    final brcDate = _getDateForType('BRC');

    return CustomRefreshIndicator(
      onRefresh: () => _loadDates(useCache: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.themeColor),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(16),
              ),
              color: AppColors.cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Important Dates',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.canEdit)
                      GestureDetector(
                        onTap: () {
                          final hire = _getEntryByType('HIRE_DATE');
                          final cda = _getEntryByType('CDA');
                          final firstAid = _getEntryByType('FIRST_AID_CPR');
                          final brc = _getEntryByType('BRC');
                          final physical = _getEntryByType('PHYSICAL_CHECKUP');
                          context
                              .push(
                                StaffRoutes.editImportantDates,
                                extra: EditImportantDatesArgs(
                                  staffCode: widget.staffCode,
                                  initialHireDate: _parseIsoDate(hire?.dueDate),
                                  initialCdaExaminationDate: _parseIsoDate(
                                    cda?.dueDate,
                                  ),
                                  initialFirstAidCprExpirationDate:
                                      _parseIsoDate(firstAid?.dueDate),
                                  initialBackgroundRecordCheckExpirationDate:
                                      _parseIsoDate(brc?.dueDate),
                                  initialPhysicalCheckupDate: _parseIsoDate(
                                    physical?.dueDate,
                                  ),
                                  initialPhysicalCheckupStatus:
                                      _apiStatusToDropdown(physical?.status),
                                ),
                              )
                              .then((_) {
                                if (mounted) _loadDates(useCache: false);
                              });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppColors.buildPrimaryGradient(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.edit,
                            size: 22,
                            color: AppColors.cardColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const StaffDatesShimmer()
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 14,
                    ),
                  )
                else ...[
                  DateRow(
                    label: 'Hire Date',
                    text: hireDate.isEmpty ? '' : hireDate,
                  ),
                  const SizedBox(height: 16),
                  DateRow(
                    label: 'CDA Examination Date',
                    text: cdaDate.isEmpty ? 'No CDA Examination Date' : cdaDate,
                    showInfo: true,
                  ),
                  const SizedBox(height: 16),
                  DateRow(
                    label: 'First Aid / CPR Expiration Date',
                    text: firstAidDate.isEmpty ? '' : firstAidDate,
                  ),
                  const SizedBox(height: 16),
                  DateRow(
                    label: 'Background Record Check Expiration Date',
                    text: brcDate.isEmpty ? '' : brcDate,
                  ),
                  _buildPhysicalCheckupSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
