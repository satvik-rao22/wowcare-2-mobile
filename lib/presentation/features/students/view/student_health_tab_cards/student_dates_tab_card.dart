import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_physical_exam_screen.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StudentDatesTabCard extends StatefulWidget {
  const StudentDatesTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.canEdit = false,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  /// Whether the current persona may edit health records (from student-settings).
  final bool canEdit;

  @override
  State<StudentDatesTabCard> createState() => _StudentDatesTabCardState();
}

class _StudentDatesTabCardState extends State<StudentDatesTabCard> {
  late Future<List<StudentPhysicalExam>> _physicalExamFuture;
  bool _hasShownErrorSnackBar = false;

  /// Display format for the checkup-date field in the add/edit dialog,
  /// e.g. "Jun 02, 2027". The API payload is built from the raw DateTime.
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  bool _disableAddPhysicalExam = false;

  @override
  void initState() {
    super.initState();
    _physicalExamFuture = _buildPhysicalExamFuture();
  }

  Future<List<StudentPhysicalExam>> _buildPhysicalExamFuture({
    bool forceRefresh = false,
  }) async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return const <StudentPhysicalExam>[];
    }

    final repo = serviceLocator<StudentRepository>();
    return repo.getStudentPhysicalExams(
      studentCode: code,
      forceRefresh: forceRefresh,
    );
  }

  /// Reload exams from API (bypasses cache). Use after add/edit/delete or pull-to-refresh.
  Future<void> _reloadPhysicalExams() async {
    setState(() {
      _physicalExamFuture = _buildPhysicalExamFuture(forceRefresh: true);
      _hasShownErrorSnackBar = false;
    });
    try {
      await _physicalExamFuture;
    } catch (_) {
      // Errors surface via FutureBuilder.
    }
  }

  String _formatExamDate(String? isoDate) {
    final raw = (isoDate ?? '').trim();
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _prettyStatus(String? status) {
    final raw = (status ?? '').trim();
    if (raw.isEmpty) return '';
    final upper = raw.toUpperCase();
    switch (upper) {
      case 'COMPLETED':
        return 'Completed';
      case 'DUE':
        return 'Due';
      case 'OVERDUE':
        return 'Overdue';
      default:
        final lower = raw.toLowerCase();
        return lower.isEmpty
            ? raw
            : lower[0].toUpperCase() + lower.substring(1);
    }
  }

  bool _isCompletedStatus(String? status) {
    final upper = (status ?? '').trim().toUpperCase();
    return upper == 'COMPLETED';
  }

  DateTime? _parseIsoDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      return DateTime.parse(iso.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _openEditPhysicalBottomSheet({
    DateTime? initialDate,
    String? initialStatusUi,
    String? examCode,
  }) async {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) return;

    DateTime? selectedDate = initialDate;
    final initialStatusTrim = (initialStatusUi ?? '').trim();
    final initialIsOverdue =
        initialStatusTrim.toUpperCase() == 'OVERDUE' ||
        initialStatusTrim.toLowerCase() == 'overdue';

    // "Overdue" can be returned by API and should be displayed, but it should
    // not be a selectable option in the edit dropdown.
    String statusUi = initialStatusTrim.isNotEmpty
        ? initialStatusTrim
        : 'Scheduled';
    bool didChangeStatus = false;
    if (initialIsOverdue) {
      statusUi = 'Due';
    }
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

        final horizontalPadding = isLargeTablet
            ? 32.0
            : (isTablet ? 24.0 : 16.0);
        final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
        final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            // Let the backend enforce detailed date/status rules.
            // On the client we only require that a date is selected.
            final bool canSave = selectedDate != null;

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
                                color: const Color(0xFF0A1C5D),
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
                              child: _DialogField(
                                label: 'Physical Checkup Date',
                                isRequired: true,
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
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                        context: context,
                                        builder: (context) => CalendarDialog(
                                          isRangePicker: false,
                                          isTimePicker: false,
                                          initialDate: selectedDate,
                                        ),
                                      );
                                  if (result == null ||
                                      result['date'] == null) {
                                    return;
                                  }
                                  final picked = result['date'] as DateTime;
                                  setLocalState(() => selectedDate = picked);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DialogDropdown(
                                label: 'Status',
                                isRequired: true,
                                value: statusUi,
                                options: const [
                                  'Due',
                                  'Scheduled',
                                  'Completed',
                                ],
                                onChanged: (v) => setLocalState(() {
                                  didChangeStatus = true;
                                  statusUi = v;
                                }),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _DialogField(
                              label: 'Physical Checkup Date',
                              isRequired: true,
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
                                final result =
                                    await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => CalendarDialog(
                                        isRangePicker: false,
                                        isTimePicker: false,
                                        initialDate: selectedDate,
                                      ),
                                    );
                                if (result == null || result['date'] == null) {
                                  return;
                                }
                                final picked = result['date'] as DateTime;
                                setLocalState(() => selectedDate = picked);
                              },
                            ),
                            const SizedBox(height: 16),
                            _DialogDropdown(
                              label: 'Status',
                              isRequired: true,
                              value: statusUi,
                              options: const ['Due', 'Scheduled', 'Completed'],
                              onChanged: (v) => setLocalState(() {
                                didChangeStatus = true;
                                statusUi = v;
                              }),
                            ),
                          ],
                        ),
                      SizedBox(height: verticalPadding),
                      CustomButtonLayout(
                        confirmButtonLabel: 'Save',
                        cancelButtonLabel: 'Cancel',
                        isForm: false,
                        isLoading: isSaving,
                        onPressedCancel: () => Navigator.of(context).pop(),
                        onPressedConfirm: canSave
                            ? () async {
                                if (selectedDate == null) return;
                                final statusApi =
                                    (!didChangeStatus && initialIsOverdue)
                                    ? 'OVERDUE'
                                    : switch (statusUi) {
                                        'Completed' => 'COMPLETED',
                                        'Scheduled' => 'SCHEDULED',
                                        _ => 'DUE',
                                      };

                                // Validate the date against the chosen status on
                                // the client so we can show a friendly warning
                                // instead of the raw backend error. Today is
                                // always allowed for every status.
                                final now = AppTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final picked = DateTime(
                                  selectedDate!.year,
                                  selectedDate!.month,
                                  selectedDate!.day,
                                );
                                if (statusApi == 'COMPLETED' &&
                                    picked.isAfter(today)) {
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        'Completed date cannot be a future date. Please select today or a past date.',
                                    isWarning: true,
                                  );
                                  return;
                                }
                                if ((statusApi == 'SCHEDULED' ||
                                        statusApi == 'DUE') &&
                                    picked.isBefore(today)) {
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        '$statusUi date cannot be a past date. Please select today or a future date.',
                                    isWarning: true,
                                  );
                                  return;
                                }

                                setLocalState(() => isSaving = true);
                                try {
                                  final repo =
                                      serviceLocator<StudentRepository>();
                                  if (examCode != null &&
                                      examCode.trim().isNotEmpty) {
                                    await repo.updateStudentPhysicalExam(
                                      studentCode: studentCode,
                                      examCode: examCode.trim(),
                                      examDate: selectedDate!,
                                      status: statusApi,
                                    );
                                  } else {
                                    await repo.addStudentPhysicalExam(
                                      studentCode: studentCode,
                                      examDate: selectedDate!,
                                      status: statusApi,
                                    );
                                  }
                                  if (!context.mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: 'Physical exam saved successfully',
                                    isSuccess: true,
                                  );
                                  Navigator.of(context).pop();
                                  if (!mounted) return;
                                  await _reloadPhysicalExams();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  CoreUtils.logApiError(e.toString());
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        ApiErrorHandler.extractErrorMessage(e),
                                    isError: true,
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setLocalState(() => isSaving = false);
                                  }
                                }
                              }
                            : null,
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
    final canMutateStudent = widget.canEdit;

    return CustomRefreshIndicator(
      onRefresh: _reloadPhysicalExams,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: FutureBuilder<List<StudentPhysicalExam>>(
          future: _physicalExamFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: StudentExamCardsShimmer(),
              );
            }

            if (snapshot.hasError) {
              final msg = ApiErrorHandler.extractErrorMessage(snapshot.error);
              if (!_hasShownErrorSnackBar) {
                _hasShownErrorSnackBar = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: msg,
                    isError: true,
                  );
                });
              }
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    msg,
                    style: AppTextStyles.value.copyWith(
                      color: AppColors.primaryColor.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final exams = snapshot.data ?? const <StudentPhysicalExam>[];
            final bool hasCompletedExam = exams.any(
              (e) => _isCompletedStatus(e.status),
            );
            if (_disableAddPhysicalExam != hasCompletedExam) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _disableAddPhysicalExam = hasCompletedExam);
              });
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (canMutateStudent)
                    GestureDetector(
                      onTap: _disableAddPhysicalExam
                          ? null
                          : () async {
                              final code = widget.studentCode;
                              if (code == null || code.isEmpty) return;
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditStudentPhysicalExamScreen(
                                            studentCode: code,
                                          ),
                                    ),
                                  );
                              if (!mounted || result != true) return;
                              await _reloadPhysicalExams();
                            },
                      child: Opacity(
                        opacity: !_disableAddPhysicalExam ? 1 : 0.45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Physical Exams', style: AppTextStyles.title),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: _disableAddPhysicalExam
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFC9C5CE),
                                          Color(0xFFB8B3BE),
                                        ],
                                      )
                                    : AppColors.buildPrimaryGradient(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (exams.isEmpty)
                    Text(
                      'No physical exams found',
                      style: AppTextStyles.value.copyWith(
                        color: AppColors.primaryColor.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    for (final e in exams) ...[
                      _PhysicalExamCard(
                        status: _prettyStatus(e.status),
                        checkupDate: _formatExamDate(e.examDate),
                        showMore:
                            canMutateStudent && !_isCompletedStatus(e.status),
                        onMore:
                            !canMutateStudent || _isCompletedStatus(e.status)
                            ? null
                            : () {
                                _openEditPhysicalBottomSheet(
                                  initialDate: _parseIsoDate(e.examDate),
                                  initialStatusUi: _prettyStatus(e.status),
                                  examCode: e.code,
                                );
                              },
                      ),
                      const SizedBox(height: 20),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhysicalExamCard extends StatelessWidget {
  const _PhysicalExamCard({
    required this.status,
    required this.checkupDate,
    required this.onMore,
    this.showMore = true,
  });
  final String status;
  final String checkupDate;
  final bool showMore;
  final VoidCallback? onMore;

  Color _statusLabelColor() {
    final upper = status.trim().toUpperCase();
    // Completed — dark forest green on mint (design reference)
    if (upper == 'COMPLETED') return const Color(0xFF1B5E20);
    // Overdue — dark red on light rose
    if (upper == 'OVERDUE') return const Color(0xFFC62828);
    // Due — yellow (design reference)
    if (upper == 'DUE') return const Color(0xFFEABA00);
    // Scheduled — blue on light blue
    if (upper == 'SCHEDULED') return const Color(0xFF3B82F6);
    return AppColors.primaryColor.withValues(alpha: 0.85);
  }

  Color _statusBgColor() {
    final upper = status.trim().toUpperCase();
    if (upper == 'COMPLETED') return const Color(0xFFE8F5E9);
    if (upper == 'OVERDUE') return const Color(0xFFFFEBEE);
    if (upper == 'DUE') return const Color(0xFFFFF8E1);
    if (upper == 'SCHEDULED') return const Color(0xFFE8F1FE);
    return const Color(0xFFF4F5FA);
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.themeColor, width: 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Chip(
                    label: status,
                    labelColor: _statusLabelColor(),
                    color: _statusBgColor(),
                  ),
                  if (showMore)
                    IconButton(
                      onPressed: onMore,
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: Color(0xFF0A1C5D),
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    )
                  else
                    const SizedBox(width: 36, height: 36),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Checkup Date',
                    style: AppTextStyles.value.copyWith(
                      color: AppColors.primaryColor.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    checkupDate.isEmpty ? '-' : checkupDate,
                    style: AppTextStyles.value.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.labelColor,
    required this.color,
  });
  final String label;
  final Color labelColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.value.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: labelColor,
            ),
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
    this.isRequired = false,
  });

  final String label;
  final String value;
  final Widget suffix;
  final VoidCallback onTap;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0A1C5D),
              height: 16 / 13,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
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
              color: const Color(0xFFF4F5FA),
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
    this.isRequired = false,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0A1C5D),
              height: 16 / 13,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryColor,
              ),
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
