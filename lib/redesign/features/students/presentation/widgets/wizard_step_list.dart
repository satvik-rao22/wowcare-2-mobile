import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One step of the add-a-student wizard, as the list at the top draws it.
@immutable
class WizardStep {
  const WizardStep({
    required this.title,
    required this.note,
    this.isOptional = false,
  });

  final String title;
  final String note;
  final bool isOptional;
}

/// The three steps of 5d, always all three, so the shape of the job is on
/// screen before any of it is done.
///
/// A step already passed can be gone back to; one not reached yet cannot be
/// jumped to, because step one has to validate first.
class WizardStepList extends StatelessWidget {
  const WizardStepList({
    required this.steps,
    required this.current,
    required this.onSelect,
    super.key,
  });

  final List<WizardStep> steps;

  /// 1-based, matching the numbers on the dots.
  final int current;

  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StudentsSizes.stepGap,
    children: <Widget>[
      for (final (i, step) in steps.indexed)
        _StepRow(
          step: step,
          number: i + 1,
          isCurrent: current == i + 1,
          isDone: current > i + 1,
          onTap: current > i + 1 ? () => onSelect(i + 1) : null,
        ),
    ],
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.isCurrent,
    required this.isDone,
    this.onTap,
  });

  final WizardStep step;
  final int number;
  final bool isCurrent;
  final bool isDone;
  final VoidCallback? onTap;

  Color _dotFill(Colourway c) {
    if (isCurrent) return c.pink;
    if (isDone) return c.success;
    return c.well;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: onTap != null,
      selected: isCurrent,
      label: step.title,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isCurrent
              ? AppSurfaces.keySecondary(c)
              : AppSurfaces.subtle(c),
          padding: StudentsSizes.stepPad,
          child: Row(
            spacing: AppSizes.rowGap,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.pill(fill: _dotFill(c)),
                width: StudentsSizes.stepDot,
                height: StudentsSizes.stepDot,
                alignment: Alignment.center,
                child: isDone
                    ? Icon(
                        AppIcons.check,
                        size: AppSizes.checkGlyph,
                        color: c.onPink,
                      )
                    : Text(
                        '$number',
                        style: StudentsTextStyles.stepNumber.copyWith(
                          color: isCurrent ? c.onPink : c.ink3,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: StudentsTextStyles.stepTitle.copyWith(
                        color: isCurrent ? c.ink : c.ink2,
                      ),
                    ),
                    Text(
                      step.note,
                      style: StudentsTextStyles.footnote.copyWith(
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              if (step.isOptional)
                const StatusPill(label: StudentsStrings.optional, small: true),
            ],
          ),
        ),
      ),
    );
  }
}
