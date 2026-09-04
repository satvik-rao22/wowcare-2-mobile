import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// A quiet explanation set into the page: what this person may change (6c),
/// and why a break matters to the classroom (6c Schedule).
///
/// A well rather than a card, because there is nothing to press: it is a note
/// about what is above it, not a thing of its own.
class NoteWell extends StatelessWidget {
  const NoteWell({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppWell(
      padding: StaffSizes.notePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: StaffSizes.noteGap,
        children: <Widget>[
          Text(title, style: StaffTextStyles.noteTitle.copyWith(color: c.ink)),
          Text(body, style: StaffTextStyles.noteBody.copyWith(color: c.ink2)),
        ],
      ),
    );
  }
}
