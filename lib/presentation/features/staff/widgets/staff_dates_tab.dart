import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StaffDatesTab extends StatefulWidget {
  const StaffDatesTab({super.key, required this.staffCode});

  final String staffCode;

  @override
  State<StaffDatesTab> createState() => _StaffDatesTabState();
}

class _StaffDatesTabState extends State<StaffDatesTab> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, String> _datesByType = {};
  /// Full list from API/cache for passing to edit screen and Physical Checkup display.
  List<Map<String, String>> _importantDatesList = [];

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates({bool useCache = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try cache first if useCache is true
      if (useCache) {
        final repository = serviceLocator<StaffRepository>();
        if (repository is StaffRepositoryWithCache) {
          final cached = await (repository as StaffRepositoryWithCache)
              .loadCachedImportantDates(widget.staffCode);

          if (cached != null && mounted) {
            _datesByType.clear();
            _importantDatesList = List.from(cached);
            for (final date in cached) {
              final type = (date['importantDateType'] ?? '').toUpperCase();
              final dueDate = date['dueDate'] ?? '';
              if (type.isEmpty || dueDate.isEmpty) continue;
              _datesByType[type] = _formatDate(dueDate);
            }

            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });

            // Don't hit API if cache is valid - return early
            return;
          }
        }
      }

      // No cache or cache invalid - load from API
      final useCase = serviceLocator<GetImportantDatesUseCase>();
      final result = await useCase(staffCode: widget.staffCode);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message ?? 'Failed to load important dates';
            _datesByType.clear();
            _importantDatesList = [];
          });
        },
        (dates) {
          _datesByType.clear();
          _importantDatesList = List.from(dates);
          for (final date in dates) {
            final type = (date['importantDateType'] ?? '').toUpperCase();
            final dueDate = date['dueDate'] ?? '';
            if (type.isEmpty || dueDate.isEmpty) continue;
            _datesByType[type] = _formatDate(dueDate);
          }

          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
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

  Map<String, String>? _getEntryByType(String type) {
    final key = type.toUpperCase();
    for (final e in _importantDatesList) {
      if ((e['importantDateType'] ?? '').toUpperCase() == key) return e;
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
    const completedColor = Color.fromRGBO(56, 200, 32, 1);
    const completedBg = Color.fromRGBO(56, 200, 32, 0.1);
    const dueColor = Color.fromRGBO(234, 186, 0, 1);
    const dueBg = Color.fromRGBO(234, 186, 0, 0.12);
    const scheduledColor = Color.fromRGBO(30, 94, 255, 1);
    const scheduledBg = Color.fromRGBO(30, 94, 255, 0.12);

    String statusUpper = '';
    final cards = <Widget>[];

    if (physical == null) {
      cards.add(
        _PhysicalCard(
          statusLabel: '-',
          statusColor: AppColors.primaryColor.withOpacity(0.5),
          statusBg: AppColors.primaryColor.withOpacity(0.1),
          date: '-',
        ),
      );
    } else {
      statusUpper = (physical['status'] ?? '').toUpperCase();
      final dueDate = (physical['dueDate'] ?? '').trim();
      final completedDate = (physical['completedDate'] ?? '').trim();
      final bool isCompleted = statusUpper == 'COMPLETED';
      final bool showMore = !isCompleted;

      if (dueDate.isNotEmpty) {
        String dueLabel;
        Color dueLabelColor;
        Color dueLabelBg;
        switch (statusUpper) {
          case 'COMPLETED':
            dueLabel = 'Completed';
            dueLabelColor = completedColor;
            dueLabelBg = completedBg;
            break;
          case 'DUE':
          case 'OVERDUE':
            dueLabel = 'Due';
            dueLabelColor = dueColor;
            dueLabelBg = dueBg;
            break;
          default:
            dueLabel = 'Scheduled';
            dueLabelColor = scheduledColor;
            dueLabelBg = scheduledBg;
        }
        cards.add(
          _PhysicalCard(
            statusLabel: dueLabel,
            statusColor: dueLabelColor,
            statusBg: dueLabelBg,
            date: _formatDate(dueDate),
            showMore: showMore,
            onMore: showMore
                ? () => _openEditPhysicalDialog(
                      initialDateIso: dueDate,
                      initialStatusUi: dueLabel,
                    )
                : null,
          ),
        );
      }

      if (completedDate.isNotEmpty) {
        cards.add(
          _PhysicalCard(
            statusLabel: 'Completed',
            statusColor: completedColor,
            statusBg: completedBg,
            date: _formatDate(completedDate),
          ),
        );
      }

      if (cards.isEmpty) {
        cards.add(
          _PhysicalCard(
            statusLabel: '-',
            statusColor: AppColors.primaryColor.withOpacity(0.5),
            statusBg: AppColors.primaryColor.withOpacity(0.1),
            date: '-',
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Physical Checkup',
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.5),
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
      selectedDate = initialDateIso.isNotEmpty ? DateTime.parse(initialDateIso) : null;
    } catch (_) {
      selectedDate = null;
    }
    String statusUi = initialStatusUi.isNotEmpty ? initialStatusUi : 'Scheduled';

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        final bottomSafe = MediaQuery.of(context).padding.bottom;

        final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
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
                    color: Colors.white,
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
                                color: const Color(0xff573353),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: AppColors.primaryColor),
                          ),
                        ],
                      ),
                      SizedBox(height: verticalPadding),
                      if (isTablet)
                        Row(
                          children: [
                            Expanded(
                              child: _DialogField(
                                label: 'Physical Checkup Date *',
                                value: selectedDate != null
                                    ? _apiFormatter.format(selectedDate!)
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
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  final statusUpper = statusUi.trim().toUpperCase();
                                  final result = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (context) => CalendarDialog(
                                      isRangePicker: false,
                                      isTimePicker: false,
                                      initialDate: selectedDate,
                                      firstDate: statusUpper == 'COMPLETED' ? null : today,
                                      lastDate: statusUpper == 'COMPLETED' ? today : null,
                                    ),
                                  );
                                  if (result == null || result['date'] == null) return;
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
                              child: _DialogDropdown(
                                label: 'Status *',
                                value: statusUi,
                                options: const ['Due', 'Scheduled', 'Completed'],
                                onChanged: (v) {
                                  setLocalState(() => statusUi = v);
                                  if (selectedDate == null) return;
                                  final now = DateTime.now();
                                  final today =
                                      DateTime(now.year, now.month, now.day);
                                  final pickedOnly = DateTime(
                                    selectedDate!.year,
                                    selectedDate!.month,
                                    selectedDate!.day,
                                  );
                                  final statusUpper =
                                      statusUi.trim().toUpperCase();
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
                            _DialogField(
                              label: 'Physical Checkup Date *',
                              value: selectedDate != null
                                  ? _apiFormatter.format(selectedDate!)
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
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                final statusUpper = statusUi.trim().toUpperCase();
                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => CalendarDialog(
                                    isRangePicker: false,
                                    isTimePicker: false,
                                    initialDate: selectedDate,
                                    firstDate: statusUpper == 'COMPLETED' ? null : today,
                                    lastDate: statusUpper == 'COMPLETED' ? today : null,
                                  ),
                                );
                                if (result == null || result['date'] == null) return;
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
                            _DialogDropdown(
                              label: 'Status *',
                              value: statusUi,
                              options: const ['Due', 'Scheduled', 'Completed'],
                              onChanged: (v) {
                                setLocalState(() => statusUi = v);
                                if (selectedDate == null) return;
                                final now = DateTime.now();
                                final today =
                                    DateTime(now.year, now.month, now.day);
                                final pickedOnly = DateTime(
                                  selectedDate!.year,
                                  selectedDate!.month,
                                  selectedDate!.day,
                                );
                                final statusUpper =
                                    statusUi.trim().toUpperCase();
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
                          final now = DateTime.now();
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
                            final bool isCompleted =
                                statusUpper == 'COMPLETED';

                            // Enforce the status-specific constraints live in UI.
                            if (isDueScheduled && pickedOnly.isBefore(today)) {
                              validationMessage =
                                  'For Due/Scheduled status, Physical Checkup Date must be today or future';
                            } else if (isCompleted && pickedOnly.isAfter(today)) {
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
                                    color: Colors.redAccent,
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

                                        final dueIso = _apiFormatter.format(picked!);
                                        final statusApi =
                                            statusUpper == 'COMPLETED'
                                                ? 'COMPLETED'
                                                : statusUpper == 'SCHEDULED'
                                                    ? 'SCHEDULED'
                                                    : 'DUE';

                                        final payload =
                                            <String, String>{
                                          'importantDateType':
                                              'PHYSICAL_CHECKUP',
                                          'dueDate': dueIso,
                                          'status': statusApi,
                                          if (statusApi == 'COMPLETED')
                                            'completedDate': dueIso,
                                        };

                                        setLocalState(() => isSaving = true);
                                        try {
                                          final repo =
                                              serviceLocator<StaffRepository>();
                                          final msg = await repo
                                              .updateImportantDates(
                                            staffCode: widget.staffCode,
                                            dates: [payload],
                                          );
                                          if (!context.mounted) return;
                                          CoreUtils.showTopSnackBar(
                                            context: context,
                                            message: msg.isNotEmpty
                                                ? msg
                                                : 'Updated successfully',
                                            isSuccess: true,
                                          );
                                          Navigator.of(context).pop();
                                          await _loadDates(useCache: false);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          CoreUtils.logApiError(e.toString());
                                          CoreUtils.showTopSnackBar(
                                            context: context,
                                            message:
                                                'Failed to update physical checkup. Please try again.',
                                            isError: true,
                                          );
                                        } finally {
                                          if (context.mounted) {
                                            setLocalState(
                                                () => isSaving = false);
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
              color: Colors.white,
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
                    GestureDetector(
                      onTap: () {
                        final hire = _getEntryByType('HIRE_DATE');
                        final cda = _getEntryByType('CDA');
                        final firstAid = _getEntryByType('FIRST_AID_CPR');
                        final brc = _getEntryByType('BRC');
                        final physical = _getEntryByType('PHYSICAL_CHECKUP');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditImportantDatesScreen(
                              staffCode: widget.staffCode,
                              initialHireDate: _parseIsoDate(hire?['dueDate']),
                              initialCdaExaminationDate: _parseIsoDate(cda?['dueDate']),
                              initialFirstAidCprExpirationDate: _parseIsoDate(firstAid?['dueDate']),
                              initialBackgroundRecordCheckExpirationDate: _parseIsoDate(brc?['dueDate']),
                              initialPhysicalCheckupDate: _parseIsoDate(physical?['dueDate']),
                              initialPhysicalCheckupStatus: _apiStatusToDropdown(physical?['status']),
                            ),
                          ),
                        ).then((_) {
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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: PrimaryCircularLoader(
                      size: 24,
                      strokeWidth: 2,
                    ),
                  )
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  )
                else ...[
                  _DateRow(
                    label: 'Hire Date',
                    text: hireDate.isEmpty ? '' : hireDate,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'CDA Examination Date',
                    text: cdaDate.isEmpty ? 'No CDA Examination Date' : cdaDate,
                    showInfo: true,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'First Aid / CPR Expiration Date',
                    text: firstAidDate.isEmpty ? '' : firstAidDate,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'Background Record Check Expiration Date',
                    text: brcDate.isEmpty ? '' : brcDate,
                  ),
                  const SizedBox(height: 12),
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

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text, this.showInfo = false});
  final String label;
  final String text;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  fontSize: 16,
                  letterSpacing: 14 * (-3 / 100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Child Development Associate',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: true,
                waitDuration: Duration(milliseconds: 50),
                showDuration: Duration(seconds: 2),
                verticalOffset: 6,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (() {
            final t = text.trim();
            final tl = t.toLowerCase();
            if (t.isEmpty) return '-';
            if (tl.contains('no cda')) return '-';
            if (tl.contains('first aid') || tl.contains('cpr')) return '-';
            if (tl.contains('background record')) return '-';
            return text;
          })(),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PhysicalCard extends StatelessWidget {
  const _PhysicalCard({
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.date,
    this.showMore = false,
    this.onMore,
  });

  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String date;
  final bool showMore;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              const Spacer(),
              if (showMore)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz, color: AppColors.primaryColor),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkup Date',
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  letterSpacing: 14 * (-3 / 100),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.6),
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                suffix,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogDropdown extends StatelessWidget {
  const _DialogDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.6),
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

