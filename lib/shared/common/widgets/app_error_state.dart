import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_press.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

/// The one way a screen, a list or a section says it could not load.
///
/// Calm and on-palette: the error glyph sits in a recessed well, the title is
/// ink, the reason is secondary ink, and Retry is a secondary key. The ground
/// is never tinted red; the glyph alone carries the tone. Every full-area
/// error state in the app renders this widget, so a change here changes all
/// of them.
///
/// ```dart
/// AppErrorState(
///   title: StudentStrings.errorLoadingStudents,
///   message: state.errorMessage,
///   onRetry: cubit.refresh,
/// )
/// ```
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = AppStrings.retry,
    this.compact = false,
    super.key,
  });

  /// What failed, in a few words: "Couldn't load students". Sanitized like
  /// [message], because some screens only have the raw error to show.
  final String title;

  /// Why, if there is a reason worth showing. It goes through
  /// [ApiErrorHandler.sanitizeMessage], so a raw exception string passed
  /// straight in is never shown to the user.
  final String? message;

  /// Shows a Retry key when set.
  final VoidCallback? onRetry;

  final String retryLabel;

  /// For a section inside a card rather than a whole screen: a smaller well
  /// and less padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String heading = ApiErrorHandler.sanitizeMessage(title);
    final String? reason = message == null || message!.trim().isEmpty
        ? null
        : ApiErrorHandler.sanitizeMessage(message);
    final double well = compact ? 48 : 64;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: well,
              height: well,
              decoration: AppSurfaces.emptyIcon(),
              child: Icon(
                Icons.error_outline_rounded,
                size: well * 0.45,
                color: AppPalette.statusError,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppPalette.textPrimary,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (reason != null && reason != heading) ...[
              const SizedBox(height: 6),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 16),
              _RetryKey(label: retryLabel, onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetryKey extends StatelessWidget {
  const _RetryKey({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SkeuKeyBox(
      variant: KeyVariant.secondary,
      radius: 10,
      padding: const EdgeInsets.all(1),
      child: TextButton.icon(
        onPressed: () {
          AppHaptics.tap();
          onPressed();
        },
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: AppSurfaces.keyInk(KeyVariant.secondary),
          backgroundColor: AppColors.transparentColor,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
