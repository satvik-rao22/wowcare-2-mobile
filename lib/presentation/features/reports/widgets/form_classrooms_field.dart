import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// Renders [child] once the form's classroom list has loaded, and an inline
/// error with a retry affordance when the fetch failed.
///
/// Before this existed, each of the seven report forms fetched its own
/// classroom list and swallowed the failure, so a failed fetch left the
/// dropdown showing a reduced (or empty) list with nothing on screen to say
/// so — and the report was generated against it anyway.
class FormClassroomsField extends StatelessWidget {
  const FormClassroomsField({
    super.key,
    required this.includeNonClassroomTypes,
    required this.child,
  });

  /// Must match the flag the screen loaded with, so Retry re-requests the
  /// same classroom set.
  final bool includeNonClassroomTypes;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      buildWhen: (p, c) =>
          p.formClassroomsStatus != c.formClassroomsStatus ||
          p.formClassroomsError != c.formClassroomsError,
      builder: (context, state) {
        if (state.formClassroomsStatus != FormClassroomsStatus.failure) {
          return child;
        }
        return _FormClassroomsError(
          message:
              state.formClassroomsError ??
              ReportsStrings.couldNotLoadClassroomsTapToRetry,
          onRetry: () => context.read<ReportsCubit>().loadFormClassrooms(
            includeNonClassroomTypes: includeNonClassroomTypes,
          ),
        );
      },
    );
  }
}

class _FormClassroomsError extends StatelessWidget {
  const _FormClassroomsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.reportsInlineErrorBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.reportsInlineErrorBorderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.reportsInlineErrorBorderColor,
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.reportsFieldValue(
                  fontSize: 12,
                ).copyWith(color: AppColors.reportsInlineErrorTextColor),
              ),
            ),
            const Icon(
              Icons.refresh,
              size: 18,
              color: AppColors.reportsInlineErrorTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
