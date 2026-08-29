import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/presentation/features/students/cubit/student_health_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

class EditStudentHealthScreen extends StatefulWidget {
  const EditStudentHealthScreen({
    super.key,
    required this.studentCode,
    this.initialHealth,
  });

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
  bool _photoPermission = true;
  bool _isSaving = false;

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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final body = {
        'allergy': _allergyController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'dietRestrictions': _dietRestrictionsController.text.trim(),
        'photoPermission': _photoPermission,
      };

      // Route the write through the cubit → use case → repository.
      await _healthCubit.updateHealth(
        studentCode: widget.studentCode,
        body: body,
      );

      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Health details updated successfully',
        isSuccess: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to update health details',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
            controller: _allergyController,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Medications',
            controller: _medicationsController,
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Diet Restriction',
            controller: _dietRestrictionsController,
          ),
          const SizedBox(height: 16),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     const Text(
          //       'Photo Permission',
          //       style: TextStyle(
          //         fontFamily: 'Manrope',
          //         fontSize: 15,
          //         fontWeight: FontWeight.w400,
          //         color: Color(0xff573353),
          //       ),
          //     ),
          //     Switch(
          //       value: _photoPermission,
          //       onChanged: (v) {
          //         setState(() => _photoPermission = v);
          //       },
          //       activeColor: AppColors.primaryColor,
          //     ),
          //   ],
          // ),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Save',
          onPressedConfirm: _isSaving ? null : _save,
          showCancelButton: false,
          isForm: false,
          isLoading: _isSaving,
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'^\s'))],
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff573353),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
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
