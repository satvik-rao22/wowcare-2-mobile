import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/student_tag.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One of a student's tags, in the colour its meaning earns: red for anything
/// a room has to act on, teal for an everyday note, quiet grey for the rest.
///
/// [onRemove] is the cross the edit form puts on a tag (5e).
class StudentTagChip extends StatelessWidget {
  const StudentTagChip({required this.tag, this.onRemove, super.key});

  final StudentTag tag;
  final VoidCallback? onRemove;

  Color _fill(Colourway c) => switch (tag.tone) {
    TagTone.allergy => c.dangerBg,
    TagTone.student => c.studentBg,
    TagTone.neutral => c.neutralBg,
  };

  Color _ink(Colourway c) => switch (tag.tone) {
    TagTone.allergy => c.dangerFg,
    TagTone.student => c.student,
    TagTone.neutral => c.neutralFg,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = _ink(c);

    return SurfaceBox(
      // A pill rather than the frame's own 9px corner: 9 is not on the radius
      // ladder, and at this height a pill reads as the same shape.
      surface: AppSurfaces.pill(fill: _fill(c)),
      padding: onRemove == null
          ? StudentsSizes.tagPad
          : StudentsSizes.tagChipPad,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: StudentsSizes.tagGap,
        children: <Widget>[
          Text(tag.label, style: StudentsTextStyles.tag.copyWith(color: ink)),
          if (onRemove != null)
            Semantics(
              button: true,
              label: tag.label,
              child: Pressable.surface(
                onTap: onRemove,
                child: Icon(
                  AppIcons.close,
                  size: StudentsSizes.tagRemoveGlyph,
                  color: ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
