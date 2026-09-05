import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';
import 'package:wowcare/presentation/features/students/cubit/student_health_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

class EditStudentHealthScreen extends StatefulWidget {
  const EditStudentHealthScreen({
    super.key,
    required this.studentCode,
    this.initialHealth,
  });

  static const String routeName = '/edit-student-health';

  final String studentCode;
  final StudentHealth? initialHealth;

  @override
  State<EditStudentHealthScreen> createState() =>
      _EditStudentHealthScreenState();
}

class _EditStudentHealthScreenState extends State<EditStudentHealthScreen> {
  late final TextEditingController _allergyController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _dietRestrictionsController;
  // Photo-permission switch is currently disabled (commented out below), so this
  // stays a local value seeded from the initial health record. If the switch is
  // re-enabled it becomes editable form model and moves into the cubit state.
  bool _photoPermission = true;

  /// One cubit instance for this screen so its single-flight guard spans taps
  /// (serviceLocator registers it as a factory — a fresh call would not dedupe).
  final StudentHealthCubit _healthCubit = serviceLocator<StudentHealthCubit>();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHealth;
    _allergyController = TextEditingController(
      text: (initial?.allergy ?? '').trim(),
    );
    _medicationsController = TextEditingController(
      text: (initial?.medications ?? '').trim(),
    );
    _dietRestrictionsController = TextEditingController(
      text: (initial?.dietRestrictions ?? '').trim(),
    );
    _photoPermission = initial?.photoPermission ?? true;
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _medicationsController.dispose();
    _dietRestrictionsController.dispose();
    _healthCubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    // Re-entry guard reads the cubit's own in-flight flag (the cubit also
    // single-flights identical updateHealth calls) — no local submit bool.
    if (_healthCubit.state.mutationInProgress) return;

    try {
      final request = StudentHealthUpdateRequest(
        allergy: _allergyController.text.trim(),
        medications: _medicationsController.text.trim(),
        dietRestrictions: _dietRestrictionsController.text.trim(),
        photoPermission: _photoPermission,
      );

      // Route the write through the cubit → use case → repository.
      await _healthCubit.updateHealth(
        studentCode: widget.studentCode,
        request: request,
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Health details updated successfully',
        isSuccess: true,
      );
      context.pop(true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to update health details',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom == 0 ? 16.0 : media.padding.bottom;

    return StaffFormLayout(
      title: 'Edit Health Details',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildLabeledField(
            label: 'Allergies',
            hint: 'Eg. Peanuts, Dairy',
            controller: _allergyController,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Medications',
            hint: 'Eg. Inhaler, EpiPen',
            controller: _medicationsController,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Diet Restriction',
            hint: 'Eg. Vegetarian, Nut-free',
            controller: _dietRestrictionsController,
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomBar: Container(
        padding: EdgeInsets.only(
          bottom: bottomSafe,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BlocBuilder<StudentHealthCubit, StudentHealthState>(
          bloc: _healthCubit,
          buildWhen: (p, c) => p.mutationInProgress != c.mutationInProgress,
          builder: (context, state) => CustomButtonLayout(
            confirmButtonLabel: 'Save',
            onPressedConfirm: state.mutationInProgress ? null : _save,
            showCancelButton: false,
            isForm: false,
            isLoading: state.mutationInProgress,
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: Fonts.manrope,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s'))],
            style: const TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: Fonts.manrope,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.attendanceMutedTextColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
