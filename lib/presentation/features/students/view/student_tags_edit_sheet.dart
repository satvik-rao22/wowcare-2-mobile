import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/students/cubit/student_tags_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Bottom sheet that lets a STAFF persona edit only a student's tags.
///
/// Staff don't have access to the full profile editor (admin-only), but they
/// are allowed to manage tags — this provides a focused editor in the same
/// bottom-sheet style as the physical-checkup date editor. Calls [onSaved]
/// after a successful update so the caller can refresh.
Future<void> showStudentTagsEditSheet({
  required BuildContext context,
  required String studentCode,
  String? schoolCode,
  required List<String> initialTagNames,
  required Future<void> Function() onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparentColor,
    builder: (_) => _StudentTagsEditSheet(
      studentCode: studentCode,
      schoolCode: schoolCode,
      initialTagNames: initialTagNames,
      onSaved: onSaved,
    ),
  );
}

class _StudentTagsEditSheet extends StatefulWidget {
  const _StudentTagsEditSheet({
    required this.studentCode,
    required this.schoolCode,
    required this.initialTagNames,
    required this.onSaved,
  });

  final String studentCode;
  final String? schoolCode;
  final List<String> initialTagNames;
  final Future<void> Function() onSaved;

  @override
  State<_StudentTagsEditSheet> createState() => _StudentTagsEditSheetState();
}

class _StudentTagsEditSheetState extends State<_StudentTagsEditSheet> {
  final StudentTagsCubit _tagsCubit = serviceLocator<StudentTagsCubit>();

  @override
  void initState() {
    super.initState();
    // Show the loader from the first frame, then resolve the school + fetch.
    _tagsCubit.beginLoading();
    _load();
  }

  @override
  void dispose() {
    _tagsCubit.close();
    super.dispose();
  }

  Future<void> _load() async {
    // School resolution stays widget-side (StorageService); the cubit owns the
    // fetch + the loaded tag state.
    var school = (widget.schoolCode ?? '').trim();
    if (school.isEmpty) {
      school =
          (await serviceLocator<StorageService>().getString(
                    StorageKeys.schoolCode,
                  ) ??
                  '')
              .trim();
    }

    await _tagsCubit.load(
      schoolCode: school,
      initialTagNames: widget.initialTagNames,
    );
    if (!mounted) return;
    final error = _tagsCubit.state.errorMessage;
    if (error != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isError: true,
      );
    }
  }

  Future<void> _save() async {
    if (_tagsCubit.state.mutationInProgress) return;
    if (_tagsCubit.state.schoolCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'School could not be resolved. Please try again.',
        isError: true,
      );
      return;
    }

    try {
      final message = await _tagsCubit.saveTags(
        studentCode: widget.studentCode,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      CoreUtils.showTopSnackBar(
        context: context,
        message: message.isNotEmpty ? message : 'Tags updated successfully',
        isSuccess: true,
      );
      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocBuilder<StudentTagsCubit, StudentTagsState>(
      bloc: _tagsCubit,
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Tags',
                      style: TextStyle(
                        fontFamily: Fonts.manrope,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
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
                const SizedBox(height: 8),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: PrimaryCircularLoader()),
                  )
                else ...[
                  CustomMultiSelectDropdown(
                    label: 'Tags',
                    hintText: 'Select',
                    items: state.availableTagNames,
                    selectedItems: state.selectedTags,
                    isField: true,
                    enableSearch: true,
                    onChanged: (tags) => _tagsCubit.setSelectedTags(tags),
                  ),
                  const SizedBox(height: 20),
                  CustomButtonLayout(
                    confirmButtonLabel: 'Save',
                    cancelButtonLabel: 'Cancel',
                    isForm: false,
                    isLoading: state.mutationInProgress,
                    onPressedConfirm: _save,
                    onPressedCancel: () => Navigator.of(context).pop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
