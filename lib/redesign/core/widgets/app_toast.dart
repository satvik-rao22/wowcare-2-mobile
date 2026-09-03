import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_durations.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// What a toast reports. Only the leading dot changes colour: the slab is
/// always navy.
enum ToastTone { ok, error }

/// A toast. Components page `.toast`: navy, never a coloured slab, with a
/// green or red dot before the line.
class AppToast extends StatelessWidget {
  const AppToast({required this.message, this.tone = ToastTone.ok, super.key});

  final String message;
  final ToastTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.toast(c),
      padding: AppSizes.toastPad,
      child: Row(
        spacing: AppSizes.toastGap,
        children: <Widget>[
          Container(
            width: AppSizes.toastDot,
            height: AppSizes.toastDot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone == ToastTone.ok ? c.success : c.danger,
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: c.onImpact),
            ),
          ),
        ],
      ),
    );
  }
}

OverlayEntry? _current;
Timer? _timer;

void _dismiss() {
  _timer?.cancel();
  _timer = null;
  _current?.remove();
  _current = null;
}

/// Shows [message] as a toast at the top of the screen, just under where the
/// header bar sits, for `AppDurations.toast` (or `toastError` for an error).
///
/// One toast at a time: a new one replaces whatever is up. Tapping it
/// dismisses it early.
void showAppToast(
  BuildContext context,
  String message, {
  ToastTone tone = ToastTone.ok,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _dismiss();

  final entry = OverlayEntry(
    builder: (context) =>
        _ToastLayer(message: message, tone: tone, onTap: _dismiss),
  );
  _current = entry;
  overlay.insert(entry);

  _timer = Timer(
    tone == ToastTone.error ? AppDurations.toastError : AppDurations.toast,
    _dismiss,
  );
}

class _ToastLayer extends StatelessWidget {
  const _ToastLayer({
    required this.message,
    required this.tone,
    required this.onTap,
  });

  final String message;
  final ToastTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Under the header bar: the top inset, then the bar's own pad and key.
    final top =
        context.safeArea.top +
        AppSizes.headerBarPad.vertical +
        AppSizes.iconKey;

    return Positioned(
      top: top,
      left: AppSizes.toastMargin.left,
      right: AppSizes.toastMargin.right,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMotion.base,
        curve: AppMotion.spring,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -AppSizes.space3 * (1 - t)),
            child: child,
          ),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AppToast(message: message, tone: tone),
        ),
      ),
    );
  }
}
