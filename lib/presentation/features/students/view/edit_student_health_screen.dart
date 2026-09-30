import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';
import 'package:wowcare/presentation/features/students/view_model/student_health_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
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
        message: StudentStrings.healthDetailsUpdatedSuccessfully,
        isSuccess: true,
      );
      context.pop(true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.failedToUpdateHealthDetails,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return StaffFormLayout(
      title: StudentStrings.editHealthDetails,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildLabeledField(
            label: StudentStrings.allergies,
            hint: StudentStrings.egPeanutsDairy,
            controller: _allergyController,
          ),
          AppSpacing.gapVMd,
          _buildLabeledField(
            label: StudentStrings.medications,
            hint: StudentStrings.egInhalerEpipen,
            controller: _medicationsController,
          ),
          AppSpacing.gapVMd,
          _buildLabeledField(
            label: StudentStrings.dietRestriction,
            hint: StudentStrings.egVegetarianNutFree,
            controller: _dietRestrictionsController,
          ),
          AppSpacing.gapVMd,
        ],
      ),
      bottomBar: BlocBuilder<StudentHealthCubit, StudentHealthState>(
        bloc: _healthCubit,
        buildWhen: (p, c) => p.mutationInProgress != c.mutationInProgress,
        builder: (context, state) => CustomButtonLayout(
          confirmButtonLabel: StudentStrings.save,
          onPressedConfirm: state.mutationInProgress ? null : _save,
          showCancelButton: false,
          isForm: false,
          isLoading: state.mutationInProgress,
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
            fontFamily: AppFonts.body,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
            borderRadius: AppRadius.allSm,
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s'))],
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.attendanceMutedTextColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.s10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
