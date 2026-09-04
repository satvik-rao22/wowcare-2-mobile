import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/multi_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/dashed_outline_box.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_tag_chip.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The tags on a student's record, as 5e edits them: the current ones with a
/// cross each, and a dashed key that opens the school's own list.
///
/// The list is the school's, not a fixed four, which is why adding one opens
/// a searchable sheet rather than a row of chips.
class TagEditorField extends StatelessWidget {
  const TagEditorField({
    required this.tags,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final List<StudentTag> tags;

  /// Every tag the school has.
  final List<String> options;

  final ValueChanged<List<StudentTag>> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await MultiSelectSheet.show<String>(
      context,
      title: StudentsStrings.pickTags,
      selected: tags.map((t) => t.label).toSet(),
      options: <SelectOption<String>>[
        for (final option in options)
          SelectOption<String>(value: option, label: option),
      ],
    );
    if (picked == null) return;

    onChanged(<StudentTag>[
      for (final label in picked)
        tags.firstWhere(
          (t) => t.label == label,
          orElse: () => StudentTag(label: label),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: StudentsSizes.fieldGap,
    children: <Widget>[
      const FieldLabel(text: StudentsStrings.tags),
      Wrap(
        spacing: StudentsSizes.choiceGap,
        runSpacing: StudentsSizes.choiceGap,
        children: <Widget>[
          for (final tag in tags)
            StudentTagChip(
              tag: tag,
              onRemove: () => onChanged(<StudentTag>[
                for (final other in tags)
                  if (other.label != tag.label) other,
              ]),
            ),
          Semantics(
            button: true,
            label: AppStrings.add,
            child: DashedOutlineBox(
              radius: StudentsSizes.tagKeyRadius,
              padding: StudentsSizes.tagChipPad,
              onTap: () => unawaited(_pick(context)),
              child: Text(
                StudentsStrings.addTag,
                style: StudentsTextStyles.filterChip.copyWith(
                  color: context.colours.ink2,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
