import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/radio_ring.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// One choice of a few, as a card (1b "Choose organization").
///
/// Selected, it fills with the student tint, takes the student hairline, and
/// its ring gets a dot. It sinks as a surface.
class RadioCard extends StatelessWidget {
  const RadioCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.radioCard(c, selected: selected),
          padding: AppSizes.radioCardPad,
          child: Row(
            spacing: AppSizes.radioCardGap,
            children: <Widget>[
              RadioRing(selected: selected),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.subLine.copyWith(color: c.ink3),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
