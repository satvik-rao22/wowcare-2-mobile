import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/date_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_immunization.dart';
import 'package:wowcare/presentation/features/students/view_model/student_health_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class StudentImmunizationTabCard extends StatefulWidget {
  const StudentImmunizationTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.healthCubit,
    this.studentCode,
    this.canEdit = false,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  /// Owned by the parent health tab so the "exempt from all immunizations"
  /// toggle rendered above the TabBar shares this list's state (and the cubit's
  /// single-flight guard). The parent creates and closes it — not this card.
  final StudentHealthCubit healthCubit;

  /// Whether the current persona may edit health records (from student-settings).
  final bool canEdit;

  @override
  State<StudentImmunizationTabCard> createState() =>
      _StudentImmunizationTabCardState();
}

class _StudentImmunizationTabCardState
    extends State<StudentImmunizationTabCard> {
  bool _hasShownErrorSnackBar = false;

  /// Single cubit instance shared with the parent health tab so its
  /// single-flight guard spans taps and the bulk-exempt toggle sees this list.
  StudentHealthCubit get _healthCubit => widget.healthCubit;

  @override
  void initState() {
    super.initState();
    _healthCubit.loadImmunizations(widget.studentCode ?? '');
  }

  DateTime? _parseIsoDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      return DateTime.parse(iso.trim());
    } catch (_) {
      return null;
    }
  }

  String _statusUiFromApi(String rawStatus) {
    final upper = rawStatus.trim().toUpperCase();
    switch (upper) {
      case 'COMPLETED':
        return 'Completed';
      case 'DUE':
        return 'Due';
      case 'MISSED':
        return 'Missed';
      case 'EXEMPT':
        return 'Exempt';
      case 'OVERDUE':
        return 'Overdue';
      case 'SCHEDULED':
        // Backend enum no longer allows SCHEDULED; treat as Due in UI.
        return 'Due';
      default:
        if (rawStatus.trim().isEmpty) return 'Due';
        final lower = rawStatus.trim().toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
    }
  }

  String _statusApiFromUi(String ui) {
    switch (ui.trim()) {
      case 'Completed':
        return 'COMPLETED';
      case 'Missed':
        return 'MISSED';
      case 'Exempt':
        return 'EXEMPT';
      case 'Overdue':
        return 'OVERDUE';
      case 'Due':
      default:
        return 'DUE';
    }
  }

  Future<void> _openEditImmunizationBottomSheet({
    required StudentImmunization model,
  }) async {
    DateTime? selectedDate =
        _parseIsoDate(model.administeredDate) ?? _parseIsoDate(model.dueDate);
    String statusUi = _statusUiFromApi(model.status);
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
            // Missed/Overdue can't legitimately be a future date — matches
            // web, which rejects it. Guards both against the date picker
            // (lastDate below) and against a future date left over from
            // switching status after already picking one.
            final bool isPastOnlyStatus =
                statusUi == 'Missed' || statusUi == 'Overdue';
            final bool hasInvalidFutureDate =
                isPastOnlyStatus &&
                selectedDate != null &&
                selectedDate!.isAfter(DateTime.now());
            final bool canSave = selectedDate != null && !hasInvalidFutureDate;

            // Web auto-fills today's date when the status is set to
            // Completed/Missed/Overdue so staff aren't left with a stale due
            // date (e.g. a future due date rejected as "cannot be in the
            // future"). Only kicks in when the current date is unset or
            // still in the future — an already-entered past date is left
            // alone.
            void onStatusChanged(String v) {
              setLocalState(() {
                statusUi = v;
                if ((v == 'Completed' || v == 'Missed' || v == 'Overdue') &&
                    (selectedDate == null ||
                        selectedDate!.isAfter(DateTime.now()))) {
                  selectedDate = DateTime.now();
                }
              });
            }

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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dose ${model.doseNumber}',
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
                                  label: StudentStrings.date,
                                  value: selectedDate != null
                                      ? DateUtilsNew.formatToReadableDate(
                                          selectedDate!,
                                        )
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
                                            lastDate: isPastOnlyStatus
                                                ? DateTime.now()
                                                : null,
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
                                  label: StudentStrings.status2,
                                  value: statusUi,
                                  options: const [
                                    'Due',
                                    'Overdue',
                                    'Completed',
                                    'Missed',
                                    'Exempt',
                                  ],
                                  onChanged: onStatusChanged,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _DialogField(
                                label: StudentStrings.date,
                                value: selectedDate != null
                                    ? DateUtilsNew.formatToReadableDate(
                                        selectedDate!,
                                      )
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
                                          lastDate: isPastOnlyStatus
                                              ? DateTime.now()
                                              : null,
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
                              AppSpacing.gapVMd,
                              _DialogDropdown(
                                label: StudentStrings.status2,
                                value: statusUi,
                                options: const [
                                  'Due',
                                  'Overdue',
                                  'Completed',
                                  'Missed',
                                  'Exempt',
                                ],
                                onChanged: onStatusChanged,
                              ),
                            ],
                          ),
                        if (hasInvalidFutureDate) ...[
                          SizedBox(height: verticalPadding / 2),
                          Text(
                            '$statusUi cannot have a future date.',
                            style: TextStyle(
                              fontFamily: Fonts.manrope,
                              fontSize: isTablet ? 14.0 : 12.0,
                              color: AppColors.errorColor,
                            ),
                          ),
                        ],
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
                                  final statusApi = _statusApiFromUi(statusUi);
                                  setLocalState(() => isSaving = true);
                                  try {
                                    await _healthCubit.updateImmunization(
                                      studentCode: model.studentCode,
                                      record: model,
                                      date: selectedDate!,
                                      status: statusApi,
                                    );
                                    if (!context.mounted) return;
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message: StudentStrings
                                          .immunizationUpdatedSuccessfully,
                                      isSuccess: true,
                                    );
                                    Navigator.of(context).pop();
                                    if (!mounted) return;
                                    await _reloadImmunizations(
                                      model.studentCode,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    CoreUtils.logApiError(e.toString());
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          ApiErrorHandler.extractErrorMessage(
                                            e,
                                          ),
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reloadImmunizations(String studentCode) async {
    _hasShownErrorSnackBar = false;
    await _healthCubit.loadImmunizations(studentCode, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final canMutateStudent = widget.canEdit;

    return CustomRefreshIndicator(
      onRefresh: () => _reloadImmunizations(widget.studentCode ?? ''),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: BlocBuilder<StudentHealthCubit, StudentHealthState>(
          bloc: _healthCubit,
          builder: (context, state) {
            if (state.immunizationsLoading && state.immunizations.isEmpty) {
              return const StudentImmunizationShimmer();
            }

            if (state.errorMessage != null && state.immunizations.isEmpty) {
              final message = state.errorMessage!;
              CoreUtils.logApiError(message);
              if (!_hasShownErrorSnackBar) {
                _hasShownErrorSnackBar = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: message,
                    isError: true,
                  );
                });
              }
              return const SizedBox.shrink();
            }

            final items = state.immunizations;
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text(
                  StudentStrings.noImmunizationRecordsFound,
                  style: AppTextStyles.value.copyWith(fontSize: 16),
                ),
              );
            }

            // Group by vaccine name
            final Map<String, List<StudentImmunization>> grouped = {};
            for (final m in items) {
              grouped.putIfAbsent(m.vaccineName, () => []).add(m);
            }

            final sortedKeys = grouped.keys.toList()..sort();

            return Column(
              children: [
                for (int i = 0; i < sortedKeys.length; i++) ...[
                  _ImmunizationCard(
                    vaccineName: sortedKeys[i],
                    doses: grouped[sortedKeys[i]]!
                      ..sort((a, b) => a.doseNumber.compareTo(b.doseNumber)),
                    onMore: canMutateStudent
                        ? (m) => _openEditImmunizationBottomSheet(model: m)
                        : (_) {},
                    showActions: canMutateStudent,
                  ),
                  if (i != sortedKeys.length - 1) AppSpacing.gapVLg,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ImmunizationCard extends StatelessWidget {
  const _ImmunizationCard({
    required this.vaccineName,
    required this.doses,
    required this.onMore,
    this.showActions = true,
  });

  final String vaccineName;
  final List<StudentImmunization> doses;
  final ValueChanged<StudentImmunization> onMore;
  final bool showActions;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vaccineName,
                      style: AppTextStyles.value.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showActions)
                    IconButton(
                      onPressed: doses.isEmpty
                          ? null
                          : () => onMore(doses.first),
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
                    ),
                ],
              ),
              AppSpacing.gapVXs,
              for (final dose in doses)
                _DoseRow(
                  model: dose,
                  onMore: showActions ? () => onMore(dose) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.model, required this.onMore});
  final StudentImmunization model;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dose ${model.doseNumber}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 14 * (-3 / 100),
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: onMore,
                  borderRadius: AppRadius.allSm,
                  child: _Chip(
                    label: _statusLabel(model.status),
                    labelColor: _statusLabelColor(model.status),
                    color: _statusBgColor(model.status),
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Text(
                  _doseDateText(model),
                  style: AppTextStyles.value.copyWith(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return 'Completed';
    if (upper == 'DUE') return 'Due';
    if (upper == 'EXEMPT') return 'Exempt';
    if (upper == 'MISSED') return 'Missed';
    if (upper == 'OVERDUE') return 'Overdue';
    return upper.isEmpty ? '-' : upper[0] + upper.substring(1).toLowerCase();
  }

  Color _statusLabelColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return AppColors.studentStatusActiveColor;
    if (upper == 'DUE') return AppColors.studentHealthYellowColor;
    if (upper == 'EXEMPT') return AppColors.studentMutedText;
    if (upper == 'MISSED') return AppColors.errorColor;
    if (upper == 'OVERDUE') return AppColors.studentHealthOrangeColor;
    return AppColors.primaryColor.withValues(alpha: 0.8);
  }

  Color _statusBgColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return AppColors.studentStatusActiveBg;
    if (upper == 'DUE') return AppColors.studentHealthYellowBg;
    if (upper == 'EXEMPT') return AppColors.studentDividerGrey;
    if (upper == 'MISSED') return AppColors.studentErrorBg;
    if (upper == 'OVERDUE') return AppColors.studentHealthOrangeBg;
    return AppColors.staffBadgeInactiveBg;
  }

  DateTime? _parseIsoDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      return DateTime.parse(iso.trim());
    } catch (_) {
      return null;
    }
  }

  String _doseDateText(StudentImmunization model) {
    final administered = _parseIsoDate(model.administeredDate);
    if (administered != null) {
      return DateUtilsNew.formatToReadableDate(administered);
    }
    final due = _parseIsoDate(model.dueDate);
    if (due != null) {
      return DateUtilsNew.formatToReadableDate(due);
    }
    return '-';
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
            color: AppColors.primaryColor.withValues(alpha: 0.6),
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.gapVXs,
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: AppSurfaces.well(radius: AppRadius.r10),
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
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Defensive: DropdownButton crashes unless `value` matches EXACTLY one
    // item. `options` is a curated list that can drift out of sync with
    // whatever status string the API actually sends (that's what happened
    // with "Overdue" — see the caller's comment); deduping guards against
    // accidental duplicate entries, and appending `value` when it's missing
    // guards against a not-yet-curated/unexpected status instead of crashing.
    final dedupedOptions = {...options}.toList();
    final effectiveOptions = dedupedOptions.contains(value)
        ? dedupedOptions
        : [...dedupedOptions, value];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.6),
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.gapVXs,
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: AppSurfaces.well(radius: AppRadius.r10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryColor,
              ),
              items: effectiveOptions
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
