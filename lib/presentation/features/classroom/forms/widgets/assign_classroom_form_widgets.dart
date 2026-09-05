import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Shared chrome for [AssignStudentToClassroomForm]/[AssignStaffToClassroomForm]
/// and their confirmation-step siblings — these two forms are otherwise
/// near-identical (search + Classroom/secondary-filter dropdowns +
/// select-all + submit), differing only in the roster entity type
/// (`StudentEntity` vs `Staff`) and its type-specific fetch/filter logic,
/// which Dart's lack of structural typing across those two entities means
/// stays duplicated by design (same call made for the student/staff
/// attendance sign-in forms) rather than forced into one generic form.

/// "Assign to {room}" title row + close button, identical on every screen
/// of both flows.
class AssignFormHeader extends StatelessWidget {
  const AssignFormHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// The search field styling shared by both roster-selection screens.
class AssignFormSearchBar extends StatelessWidget {
  const AssignFormSearchBar({
    required this.controller,
    required this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      constraints: const BoxConstraints(minHeight: 44),
      hintText: hintText,
      hintStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Manrope',
          color: AppColors.classroomSearchFieldHintColor,
        ),
      ),
      backgroundColor: const WidgetStatePropertyAll<Color>(
        AppColors.cardColor,
      ),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(
        AppColors.cardColor,
      ),
      elevation: const WidgetStatePropertyAll<double>(0),
      side: const WidgetStatePropertyAll(
        BorderSide(width: 1, color: AppColors.classroomBorderColor),
      ),
      leading: const Icon(Icons.search, color: AppColors.classroomMutedIconColor),
    );
  }
}

/// The "Select All" checkbox + label row shared by both roster screens.
class SelectAllCheckboxRow extends StatelessWidget {
  const SelectAllCheckboxRow({
    required this.value,
    required this.onChanged,
    required this.checkboxBuilder,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  /// Callers pass the app's `CustomCheckbox` through so this shared widget
  /// doesn't need its own import of it (kept out to avoid coupling this
  /// file to a specific checkbox implementation).
  final Widget Function(bool value, ValueChanged<bool?> onChanged)
  checkboxBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: checkboxBuilder(value, onChanged),
        ),
        const Text('Select All', style: TextStyle(fontFamily: 'Manrope')),
      ],
    );
  }
}

/// The loading / error+retry / content switch shared by both roster
/// screens' main results area. [content] is the caller's already-built
/// `GridView.builder` (entity-specific itemBuilder stays with the caller).
class AssignFormResultsArea extends StatelessWidget {
  const AssignFormResultsArea({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.content,
    super.key,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: PrimaryCircularLoader());
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.classroomNegativeStatusColor,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    return content;
  }
}

/// The confirmation-step's "nothing selected" placeholder.
class AssignFormEmptySelection extends StatelessWidget {
  const AssignFormEmptySelection({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.classroomTextColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Runs [submit] and handles the identical success/error boilerplate both
/// confirmation forms wrap their assign-cubit call in. [submit] is the
/// entity-specific cubit call (`AssignStaffConfirmationCubit.submit` /
/// `AssignStudentConfirmationCubit.submit`), which already owns resolving
/// the school code and the submitting-flag state; this helper only turns its
/// result into UI feedback.
Future<void> submitClassroomAssignment({
  required BuildContext context,
  required bool isSelectionEmpty,
  required String emptySelectionMessage,
  required Future<String> Function() submit,
  required VoidCallback onSuccess,
}) async {
  if (isSelectionEmpty) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: emptySelectionMessage,
      isWarning: true,
    );
    return;
  }

  try {
    final message = await submit();

    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message.isEmpty ? 'Assigned successfully' : message,
      isSuccess: true,
    );
    onSuccess();
    Navigator.pop(context);
  } catch (e) {
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: e.toString(),
      isError: true,
    );
  }
}
