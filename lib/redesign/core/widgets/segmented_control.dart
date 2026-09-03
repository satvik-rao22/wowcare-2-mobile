import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A well track with one raised segment that slides to the selection.
/// Components page `.segmented`, and 4a's Students / Staff switch.
///
/// [sublabels], when given, sit under each label in `tileLabel` (4a's
/// counts). The raised segment moves on `AppMotion.spring`.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    required this.segments,
    required this.index,
    required this.onChanged,
    this.sublabels,
    super.key,
  }) : assert(
         sublabels == null || sublabels.length == segments.length,
         'One sublabel per segment.',
       );

  final List<String> segments;
  final List<String>? sublabels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.track(c, radius: AppRadii.innerR),
      padding: AppSizes.segmentedPad,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = segments.length;
          final width =
              (constraints.maxWidth - AppSizes.segmentGap * (n - 1)) / n;

          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: AppMotion.base,
                curve: AppMotion.spring,
                left: index * (width + AppSizes.segmentGap),
                top: 0,
                bottom: 0,
                width: width,
                child: SurfaceBox(surface: AppSurfaces.segmentSelected(c)),
              ),
              Row(
                spacing: AppSizes.segmentGap,
                children: <Widget>[
                  for (final (i, label) in segments.indexed)
                    Expanded(
                      child: _Segment(
                        label: label,
                        sublabel: sublabels?[i],
                        isSelected: i == index,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Pressable(
        sink: AppSizes.segmentSink,
        scale: 1,
        onTap: onTap,
        child: Padding(
          padding: AppSizes.segmentPad,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSizes.hairline,
            children: <Widget>[
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.ease,
                style: AppTextStyles.segmentLabel.copyWith(
                  color: isSelected ? c.ink : c.ink3,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: AppTextStyles.tileLabel.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
