import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/students/view_model/student_physical_exam_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_physical_exam_screen.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

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
  bool _hasShownErrorSnackBar = false;

  // Single cubit instance for this card — the serviceLocator registers the
  // cubit as a factory, so holding one instance (rather than resolving per
  // call) is what keeps its single-flight guard effective. Closed in dispose.
  final StudentPhysicalExamCubit _examCubit =
      serviceLocator<StudentPhysicalExamCubit>();

  /// Display format for the checkup-date field in the add/edit dialog,
  /// e.g. "Jun 02, 2027". The API payload is built from the raw DateTime.
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  bool _disableAddPhysicalExam = false;

  @override
  void initState() {
    super.initState();
    _examCubit.load(widget.studentCode ?? '');
  }

  @override
  void dispose() {
    _examCubit.close();
    super.dispose();
  }

  /// Reload exams from API (bypasses cache). Use after add/edit/delete or pull-to-refresh.
  Future<void> _reloadPhysicalExams() async {
    _hasShownErrorSnackBar = false;
    await _examCubit.load(widget.studentCode ?? '', forceRefresh: true);
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
      backgroundColor: AppColors.transparentColor,
      builder: (context) {
        final responsive = ResponsiveHelper(context);
        final isTablet = responsive.isTabletCompact;
        final isLargeTablet = responsive.isWide;
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
                    color: AppColors.whiteColor,
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
                              StudentStrings.editPhysicalExamination,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
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
                              child: _DialogField(
                                label: StudentStrings.physicalCheckupDate,
                                isRequired: true,
                                value: selectedDate != null
                                    ? _displayFormatter.format(selectedDate!)
                                    : '',
                                suffix: AppIcon(
                                  MediaRes.calender_icon,
                                  height: 20.0,
                                  color: AppColors.primaryColor,
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
                            AppSpacing.gapHMd,
                            Expanded(
                              child: _DialogDropdown(
                                label: StudentStrings.status,
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
                              label: StudentStrings.physicalCheckupDate,
                              isRequired: true,
                              value: selectedDate != null
                                  ? _displayFormatter.format(selectedDate!)
                                  : '',
                              suffix: AppIcon(
                                MediaRes.calender_icon,
                                height: 20.0,
                                color: AppColors.primaryColor,
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
                            AppSpacing.gapVMd,
                            _DialogDropdown(
                              label: StudentStrings.status,
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
                        confirmButtonLabel: StudentStrings.save,
                        cancelButtonLabel: StudentStrings.cancel,
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
                                    message: StudentStrings
                                        .completedDateCannotBeAFutureDatePleaseSelectTo,
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
                                  if (examCode != null &&
                                      examCode.trim().isNotEmpty) {
                                    await _examCubit.update(
                                      studentCode: studentCode,
                                      examCode: examCode.trim(),
                                      examDate: selectedDate!,
                                      status: statusApi,
                                    );
                                  } else {
                                    await _examCubit.add(
                                      studentCode: studentCode,
                                      examDate: selectedDate!,
                                      status: statusApi,
                                    );
                                  }
                                  if (!context.mounted) return;
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: StudentStrings
                                        .physicalExamSavedSuccessfully,
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
        child: BlocBuilder<StudentPhysicalExamCubit, StudentPhysicalExamState>(
          bloc: _examCubit,
          builder: (context, state) {
            if (state.isLoading && state.exams.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: StudentExamCardsShimmer(),
              );
            }

            if (state.errorMessage != null && state.exams.isEmpty) {
              final msg = state.errorMessage!;
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
                padding: const EdgeInsets.only(top: AppSpacing.xl),
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

            final exams = state.exams;
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.none,
                vertical: AppSpacing.md,
              ),
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
                              final result = await context.push<bool>(
                                EditStudentPhysicalExamScreen.routeName,
                                extra: <String, dynamic>{'studentCode': code},
                              );
                              if (!mounted || result != true) return;
                              await _reloadPhysicalExams();
                            },
                      child: Opacity(
                        opacity: !_disableAddPhysicalExam ? 1 : 0.45,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              StudentStrings.physicalExams,
                              style: AppTextStyles.title,
                            ),
                            SkeuKeyBox(
                              variant: _disableAddPhysicalExam
                                  ? KeyVariant.disabled
                                  : KeyVariant.primary,
                              radius: AppRadius.sm,
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.edit,
                                size: 22,
                                color: AppSurfaces.keyInk(
                                  _disableAddPhysicalExam
                                      ? KeyVariant.disabled
                                      : KeyVariant.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AppSpacing.gapVMd,
                  if (exams.isEmpty)
                    Text(
                      StudentStrings.noPhysicalExamsFound,
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
                      AppSpacing.gapVLg,
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
    if (upper == 'COMPLETED') return AppColors.studentHealthGreenDark;
    // Overdue — dark red on light rose
    if (upper == 'OVERDUE') return AppColors.studentHealthRedDark;
    // Due — yellow (design reference)
    if (upper == 'DUE') return AppColors.studentHealthYellowColor;
    // Scheduled — blue on light blue
    if (upper == 'SCHEDULED') return AppColors.studentHealthBlue;
    return AppColors.primaryColor.withValues(alpha: 0.85);
  }

  Color _statusBgColor() {
    final upper = status.trim().toUpperCase();
    if (upper == 'COMPLETED') return AppColors.studentStatusActiveBgSolid;
    if (upper == 'OVERDUE') return AppColors.studentHealthRedBg;
    if (upper == 'DUE') return AppColors.studentAmberBg;
    if (upper == 'SCHEDULED') return AppColors.studentHealthBlueBg;
    return AppColors.staffBadgeInactiveBg;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.sm),
            bottomLeft: Radius.circular(AppRadius.sm),
            bottomRight: Radius.circular(AppRadius.sm),
          ),
          border: Border.fromBorderSide(
            BorderSide(
              color: AppColors.themeColor,
              width: AppDimensions.hairline,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.s14,
          ),
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
                        size: AppDimensions.iconSm,
                        color: AppColors.primaryColor,
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
              AppSpacing.gapVLg,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    StudentStrings.checkupDate,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.allSm),
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
            style: AppTextStyles.label,
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.errorColor),
                ),
            ],
          ),
        ),
        AppSpacing.gapVXs,
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.staffLightBackgroundAltColor,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: AppFonts.body,
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
            style: AppTextStyles.label,
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.errorColor),
                ),
            ],
          ),
        ),
        AppSpacing.gapVXs,
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.staffLightBackgroundAltColor,
            borderRadius: BorderRadius.circular(AppRadius.r10),
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
                          fontFamily: AppFonts.body,
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
