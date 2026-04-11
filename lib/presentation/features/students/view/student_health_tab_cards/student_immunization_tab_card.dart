import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';


class StudentImmunizationTabCard extends StatefulWidget {
  const StudentImmunizationTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;


  @override
  State<StudentImmunizationTabCard> createState() =>
      _StudentImmunizationTabCardState();
}

class _StudentImmunizationTabCardState extends State<StudentImmunizationTabCard> {
  late Future<List<StudentImmunizationModel>> _immunizationFuture;
  bool _hasShownErrorSnackBar = false;
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _immunizationFuture = _buildImmunizationFuture();
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
    required StudentImmunizationModel model,
  }) async {
    DateTime? selectedDate = _parseIsoDate(model.administeredDate) ??
        _parseIsoDate(model.dueDate);
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

        final horizontalPadding =
            isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final verticalPadding =
            isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
        final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

        return StatefulBuilder(
          builder: (context, setLocalState) {
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
                                  if (result == null || result['date'] == null) {
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
                                  'Completed',
                                  'Missed',
                                  'Exempt',
                                ],
                                onChanged: (v) =>
                                    setLocalState(() => statusUi = v),
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
                                if (result == null || result['date'] == null) {
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
                                'Completed',
                                'Missed',
                                'Exempt',
                              ],
                              onChanged: (v) => setLocalState(() => statusUi = v),
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
                          controller: TextEditingController(text: exemptionReason),
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
                                  final repo =
                                      serviceLocator<StudentRepository>()
                                          as StudentRepositoryImpl;
                                  await repo.updateStudentImmunizationRecord(
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
                                  setState(() {
                                    _immunizationFuture =
                                        (serviceLocator<StudentRepository>()
                                                as StudentRepositoryImpl)
                                            .getStudentImmunizations(
                                      studentCode: model.studentCode,
                                      forceRefresh: true,
                                    );
                                    _hasShownErrorSnackBar = false;
                                  });
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

  Future<List<StudentImmunizationModel>> _buildImmunizationFuture() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return const <StudentImmunizationModel>[];
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    try {
      return await repo.getStudentImmunizations(studentCode: code);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>();
    final canMutateStudent =
        ModuleAccess.mayWrite(role, StudentAccessModules.student);

    return CustomRefreshIndicator(
      onRefresh: () async {
        setState(() {
          _immunizationFuture =
              serviceLocator<StudentRepository>() is StudentRepositoryImpl
                  ? (serviceLocator<StudentRepository>() as StudentRepositoryImpl)
                      .getStudentImmunizations(
                      studentCode: widget.studentCode ?? '',
                      forceRefresh: true,
                    )
                  : _buildImmunizationFuture();
          _hasShownErrorSnackBar = false;
        });
        try {
          await _immunizationFuture;
        } catch (_) {
          // handled in FutureBuilder
        }
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: FutureBuilder<List<StudentImmunizationModel>>(
          future: _immunizationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: PrimaryCircularLoader()),
              );
            }

            if (snapshot.hasError) {
              final message = snapshot.error.toString();
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

            final items = snapshot.data ?? const <StudentImmunizationModel>[];
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
            final Map<String, List<StudentImmunizationModel>> grouped = {};
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
                      ..sort(
                      (a, b) => a.doseNumber.compareTo(b.doseNumber),
                    ),
                    onMore: (m) {
                      if (!canMutateStudent) {
                        ModuleAccess.showWriteRestricted(context);
                        return;
                      }
                      _openEditImmunizationBottomSheet(model: m);
                    },
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
  });

  final String vaccineName;
  final List<StudentImmunizationModel> doses;
  final ValueChanged<StudentImmunizationModel> onMore;

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
                  IconButton(
                    onPressed: doses.isEmpty ? null : () => onMore(doses.first),
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: Color(0xFF573353),
                      ),
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final dose in doses)
                _DoseRow(
                  model: dose,
                  onMore: () => onMore(dose),
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
  final StudentImmunizationModel model;
  final VoidCallback onMore;

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
                color: AppColors.primaryColor.withOpacity(0.5),
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
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                  ),
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
    return upper.isEmpty
        ? '-'
        : upper[0] + upper.substring(1).toLowerCase();
  }

  Color _statusLabelColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return const Color(0xFF38C820);
    if (upper == 'DUE') return const Color(0xFFEABA00);
    if (upper == 'EXEMPT') return const Color(0xFF6C6377);
    if (upper == 'MISSED') return const Color(0xFFD32F2F);
    if (upper == 'OVERDUE') return const Color(0xFFEF6C00);
    return AppColors.primaryColor.withOpacity(0.8);
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

  String _doseDateText(StudentImmunizationModel model) {
    if ((model.administeredDate ?? '').isNotEmpty) {
      return model.administeredDate!;
    }
    if ((model.dueDate ?? '').isNotEmpty) {
      return model.dueDate!;
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


class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color});
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






