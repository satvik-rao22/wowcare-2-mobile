import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/list_row.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The question the wizard asks before it writes: somebody already enrolled
/// has this last name, is this a sibling?
///
/// It is asked here rather than afterwards because linking siblings later
/// means finding both records again, and because a family that shares a
/// pickup list should share it from day one.
class SiblingLinkSheet extends StatelessWidget {
  const SiblingLinkSheet({required this.candidates, super.key});

  final List<StudentSummary> candidates;

  /// Resolves to the sibling to link, or null when the answer is no.
  static Future<StudentSummary?> show(
    BuildContext context, {
    required List<StudentSummary> candidates,
  }) => showAppSheet<StudentSummary>(
    context,
    builder: (_) => SiblingLinkSheet(candidates: candidates),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppBottomSheet(
      title: StudentsStrings.siblingsFound(candidates.length),
      subtitle: StudentsStrings.siblingsAsk,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: StudentsSizes.actionRowGap,
          children: <Widget>[
            for (final candidate in candidates)
              SurfaceBox(
                surface: AppSurfaces.keySecondary(c),
                child: ListRow(
                  title: candidate.fullName,
                  subtitle: StudentsStrings.siblingSub(
                    candidate.classroomName,
                    candidate.status.label,
                  ),
                  leading: AppAvatar(initials: candidate.initials),
                  showChevron: false,
                  onTap: () => Navigator.of(context).pop(candidate),
                  trailing: Text(
                    StudentsStrings.siblingLink,
                    style: StudentsTextStyles.tag.copyWith(color: c.pink),
                  ),
                ),
              ),
          ],
        ),
      ),
      footer: <Widget>[
        SecondaryKey(
          label: StudentsStrings.siblingSkip,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
