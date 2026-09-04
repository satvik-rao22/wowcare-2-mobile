import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One option of a pick-one row.
@immutable
class Choice<T> {
  const Choice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A row of equal pick-one keys: Status on 5b, 5d and 5e, and step two's
/// Yes / No answers.
///
/// It is not a segmented control: these are separate keys at the everyday
/// radius, and the picked one fills with the student tint rather than sliding.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    required this.choices,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<Choice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    spacing: StudentsSizes.choiceGap,
    children: <Widget>[
      for (final choice in choices)
        Expanded(
          child: _ChoiceKey(
            label: choice.label,
            isSelected: choice.value == value,
            onTap: () => onChanged(choice.value),
          ),
        ),
    ],
  );
}

class _ChoiceKey extends StatelessWidget {
  const _ChoiceKey({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isSelected
              ? AppSurfaces.tile(c, fill: c.studentBg, line: c.studentRim)
              : AppSurfaces.keySecondary(c),
          padding: StudentsSizes.choicePad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StudentsTextStyles.emphasis.copyWith(
              color: isSelected ? c.student : c.ink2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
