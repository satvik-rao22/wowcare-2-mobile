import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// Which tint the big blank state wears (6e).
enum StaffStateTone { denied, offline }

/// 6e's blank states: a 78px tinted tile carrying one mark, a title, a line
/// of explanation, and at most one key.
///
/// Bigger than the core `EmptyState` and tinted rather than well-grey,
/// because these are the screen rather than a gap in it.
class StaffStateView extends StatelessWidget {
  const StaffStateView({
    required this.mark,
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a handler.',
       );

  /// The one character in the tile: an em dash where there is nothing to
  /// show, an exclamation where something is waiting.
  final String mark;

  final String title;
  final String message;
  final StaffStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final fill = tone == StaffStateTone.denied ? c.dangerBg : c.staffBg;
    final ink = tone == StaffStateTone.denied ? c.dangerFg : c.staffFg;

    return Padding(
      padding: StaffSizes.blankPad,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        spacing: StaffSizes.stateGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: fill,
              radius: StaffSizes.stateIconRadius,
            ),
            width: StaffSizes.stateIcon,
            height: StaffSizes.stateIcon,
            alignment: Alignment.center,
            child: Text(
              mark,
              style: StaffTextStyles.stateMark.copyWith(color: ink),
            ),
          ),
          Column(
            spacing: StaffSizes.stateTextGap,
            children: <Widget>[
              Text(
                title,
                style: StaffTextStyles.stateTitle.copyWith(color: c.ink),
                textAlign: TextAlign.center,
              ),
              Text(
                message,
                style: StaffTextStyles.stateBody.copyWith(color: c.ink2),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (onAction != null)
            _ActionKey(label: actionLabel!, onTap: onAction!),
        ],
      ),
    );
  }
}

/// The one key a blank state gets: pink, hugging its label rather than
/// stretching, because it is an offer and not the width of the screen.
class _ActionKey extends StatelessWidget {
  const _ActionKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyPrimary(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: StaffSizes.stateKeyPad,
          child: Text(
            label,
            style: StaffTextStyles.stateKey.copyWith(color: c.onPink),
          ),
        ),
      ),
    );
  }
}
