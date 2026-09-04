import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_immunization.dart';
import 'package:wowcare/presentation/features/students/cubit/student_health_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

class StudentImmunizationTabCard extends StatefulWidget {
  const StudentImmunizationTabCard({
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
  State<StudentImmunizationTabCard> createState() =>
      _StudentImmunizationTabCardState();
}

class _StudentImmunizationTabCardState
    extends State<StudentImmunizationTabCard> {
  bool _hasShownErrorSnackBar = false;
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  /// One cubit instance for this card so its single-flight guard spans taps
  /// (serviceLocator registers it as a factory — a fresh call would not dedupe).
  final StudentHealthCubit _healthCubit = serviceLocator<StudentHealthCubit>();

  @override
  void initState() {
    super.initState();
    _healthCubit.loadImmunizations(widget.studentCode ?? '');
  }

  @override
  void dispose() {
    _healthCubit.close();
    super.dispose();
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
    String exemptionReason = (model.exemptionReason ?? '').trim();

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
            final bool canSave = selectedDate != null;

            // Web auto-fills today's date when the status is set to
            // Completed/Missed so staff aren't left with a stale due date
            // (e.g. a future due date rejected as "cannot be in the future").
            // Only kicks in when the current date is unset or still in the
            // future — an already-entered past date is left alone.
            void onStatusChanged(String v) {
              setLocalState(() {
                statusUi = v;
                if ((v == 'Completed' || v == 'Missed') &&
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
                    color: Colors.white,
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
                                  fontFamily: 'Manrope',
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff573353),
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
                                  label: 'Date *',
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
                                  label: 'Status *',
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
                                label: 'Date *',
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
                              const SizedBox(height: 16),
                              _DialogDropdown(
                                label: 'Status *',
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
                        if (statusUi == 'Exempt') ...[
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Exemption Reason *',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: exemptionReason,
                            ),
                            minLines: 1,
                            maxLines: 3,
                            onChanged: (v) =>
                                setLocalState(() => exemptionReason = v.trim()),
                          ),
                        ],
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
                                  final statusApi = _statusApiFromUi(statusUi);
                                  setLocalState(() => isSaving = true);
                                  try {
                                    await _healthCubit.updateImmunization(
                                      studentCode: model.studentCode,
                                      record: model,
                                      date: selectedDate!,
                                      status: statusApi,
                                      exemptionReason: statusApi == 'EXEMPT'
                                          ? exemptionReason
                                          : null,
                                    );
                                    if (!context.mounted) return;
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message:
                                          'Immunization updated successfully',
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
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No immunization records found',
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
                  if (i != sortedKeys.length - 1) const SizedBox(height: 20),
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
                        size: 20,
                        color: Color(0xFF573353),
                      ),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
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
                  borderRadius: BorderRadius.circular(8),
                  child: _Chip(
                    label: _statusLabel(model.status),
                    labelColor: _statusLabelColor(model.status),
                    color: _statusBgColor(model.status),
                  ),
                ),
                const SizedBox(width: 10),
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
    if (upper == 'COMPLETED') return const Color(0xFF38C820);
    if (upper == 'DUE') return const Color(0xFFEABA00);
    if (upper == 'EXEMPT') return const Color(0xFF6C6377);
    if (upper == 'MISSED') return const Color(0xFFD32F2F);
    if (upper == 'OVERDUE') return const Color(0xFFEF6C00);
    return AppColors.primaryColor.withValues(alpha: 0.8);
  }

  Color _statusBgColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return const Color(0x1A38C820);
    if (upper == 'DUE') return const Color(0x1AEABA00);
    if (upper == 'EXEMPT') return const Color(0xFFECEFF1);
    if (upper == 'MISSED') return const Color(0x1AD32F2F);
    if (upper == 'OVERDUE') return const Color(0x1AEF6C00);
    return const Color(0xFFF3F4FB);
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
