import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The two steps of an assign flow (7g, 7h): pick, then review and submit.
///
/// The step you are on is pink; the other is quiet. It is a marker, not a
/// control: you move through it with the keys at the foot of the screen.
class AssignStepRail extends StatelessWidget {
  const AssignStepRail({
    required this.firstLabel,
    required this.secondLabel,
    required this.isSecond,
    super.key,
  });

  final String firstLabel;
  final String secondLabel;

  /// The review step is the one you are on.
  final bool isSecond;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: ClassroomsSizes.railStepGap,
      children: <Widget>[
        Expanded(
          child: _Step(index: 1, label: firstLabel, isCurrent: !isSecond),
        ),
        Container(
          width: ClassroomsSizes.railLine,
          height: ClassroomsSizes.railLineHeight,
          color: c.keyBorder,
        ),
        Expanded(
          child: _Step(index: 2, label: secondLabel, isCurrent: isSecond),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: ClassroomsSizes.railGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.avatar(
            c,
            fill: isCurrent ? c.pink : c.well,
            size: ClassroomsSizes.railDot,
          ),
          width: ClassroomsSizes.railDot,
          height: ClassroomsSizes.railDot,
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: ClassroomsTextStyles.railNumber.copyWith(
              color: isCurrent ? c.onPink : c.ink3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: ClassroomsTextStyles.railLabel.copyWith(
              color: isCurrent ? c.ink : c.ink3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
