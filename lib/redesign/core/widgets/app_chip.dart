import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A filter chip. Components page `.chip`: a card-faced capsule that goes
/// navy with warm-white text when selected.
///
/// [count] is the tally 4a and 7a put after the label; [onRemove] adds the
/// small cross of an applied filter (5a).
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.onRemove,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? count;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = selected ? c.onImpact : c.ink;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: selected ? AppSurfaces.chipSelected(c) : AppSurfaces.chip(c),
          padding: AppSizes.chipPad,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSizes.chipInnerGap,
            children: <Widget>[
              Text(label, style: AppTextStyles.chipLabel.copyWith(color: ink)),
              if (count != null)
                Text(
                  count!,
                  style: AppTextStyles.chipCount.copyWith(
                    color: selected ? c.onImpact : c.ink3,
                  ),
                ),
              if (onRemove != null)
                Pressable.surface(
                  onTap: onRemove,
                  child: Icon(
                    AppIcons.close,
                    size: AppSizes.chipRemoveGlyph,
                    color: ink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
