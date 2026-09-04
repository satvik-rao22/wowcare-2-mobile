import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6d's three steps, listed rather than dotted, so the wizard says what it is
/// going to ask before it asks it.
///
/// A step that has been passed is tickable back to; a step ahead is not, and
/// does not respond to a tap.
class WizardSteps extends StatelessWidget {
  const WizardSteps({
    required this.currentStep,
    required this.onSelect,
    super.key,
  });

  /// 1, 2 or 3.
  final int currentStep;

  final ValueChanged<int> onSelect;

  static const List<_Step> _steps = <_Step>[
    _Step(1, StaffStrings.step1Title, StaffStrings.step1Note),
    _Step(2, StaffStrings.step2Title, StaffStrings.step2Note),
    _Step(
      3,
      StaffStrings.step3Title,
      StaffStrings.step3Note,
      isSkippable: true,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StaffSizes.stepGap,
    children: <Widget>[
      for (final step in _steps)
        _StepRow(
          step: step,
          isActive: step.number == currentStep,
          isDone: step.number < currentStep,
          onTap: step.number < currentStep ? () => onSelect(step.number) : null,
        ),
    ],
  );
}

@immutable
class _Step {
  const _Step(this.number, this.title, this.note, {this.isSkippable = false});

  final int number;
  final String title;
  final String note;
  final bool isSkippable;
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isActive,
    required this.isDone,
    required this.onTap,
  });

  final _Step step;
  final bool isActive;
  final bool isDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final row = SurfaceBox(
      surface: isActive ? AppSurfaces.cardRaised(c) : AppSurfaces.subtle(c),
      padding: StaffSizes.stepPad,
      child: Row(
        spacing: StaffSizes.expandedGap,
        children: <Widget>[
          _Dot(
            label: isDone ? StaffStrings.stepDone : '${step.number}',
            fill: _dotFill(c),
            ink: isActive || isDone ? c.onPink : c.ink3,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  step.title,
                  style: StaffTextStyles.stepTitle.copyWith(
                    color: isActive ? c.ink : c.ink2,
                  ),
                ),
                Text(
                  step.note,
                  style: StaffTextStyles.stepNote.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
          if (step.isSkippable)
            const StatusPill(label: StaffStrings.optional, small: true),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: isActive,
      label: step.title,
      child: onTap == null ? row : Pressable.surface(onTap: onTap, child: row),
    );
  }

  /// Pink is the step being asked, green is a step answered, and a step still
  /// to come is nothing at all.
  Color _dotFill(Colourway c) {
    if (isActive) return c.pink;
    return isDone ? c.success : c.well;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.fill, required this.ink});

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    width: StaffSizes.stepDot,
    height: StaffSizes.stepDot,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
    child: Text(label, style: StaffTextStyles.stepNumber.copyWith(color: ink)),
  );
}
