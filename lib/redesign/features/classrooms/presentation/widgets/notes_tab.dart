import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The classroom's own thread (7c's third tab): what the room needs to know,
/// oldest first, with a rule where the unread ones start.
class NotesTab extends StatelessWidget {
  const NotesTab({required this.notes, required this.newCount, super.key});

  final List<ClassroomNote> notes;

  /// How many arrived since the last visit. Zero draws no rule.
  final int newCount;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const EmptyState(
        icon: AppIcons.fileText,
        title: ClassroomsStrings.noNotesTitle,
        subtitle: ClassroomsStrings.noNotesBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClassroomsSizes.noteGap,
      children: <Widget>[
        const _DayPill(label: ClassroomsStrings.today),
        for (final note in notes) ...<Widget>[
          if (note.isFirstUnread && newCount > 0) _NewRule(count: newCount),
          _NoteBubble(note: note),
        ],
      ],
    );
  }
}

/// The day this stretch of notes belongs to, sunk into the tray.
class _DayPill extends StatelessWidget {
  const _DayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Center(
      child: SurfaceBox(
        surface: AppSurfaces.track(c),
        padding: ClassroomsSizes.dayPillPad,
        child: Text(
          label,
          style: ClassroomsTextStyles.dayPill.copyWith(color: c.ink2),
        ),
      ),
    );
  }
}

/// The pink rule that says how many notes arrived since the last visit.
class _NewRule extends StatelessWidget {
  const _NewRule({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final line = Expanded(
      child: Container(height: AppSizes.hairline, color: c.pinkGlow),
    );

    return Row(
      spacing: ClassroomsSizes.newRuleGap,
      children: <Widget>[
        line,
        Text(
          ClassroomsStrings.newCount(count).toUpperCase(),
          style: ClassroomsTextStyles.newRule.copyWith(color: c.pink),
        ),
        line,
      ],
    );
  }
}

/// One note. Somebody else's sits left on a card; your own sits right on the
/// navy, which is the only place a message changes material.
class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note});

  final ClassroomNote note;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = note.isMine ? c.onImpact : c.ink;
    final meta = note.isMine ? c.onImpactSub : c.ink3;

    return Align(
      alignment: note.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: ClassroomsSizes.noteMaxWidthFactor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ClassroomsSizes.noteBubbleGap,
          children: <Widget>[
            SurfaceBox(
              surface: AppSurfaces.avatar(
                c,
                fill: note.isMine ? c.well : c.staffBg,
                size: ClassroomsSizes.noteAvatar,
              ),
              width: ClassroomsSizes.noteAvatar,
              height: ClassroomsSizes.noteAvatar,
              alignment: Alignment.center,
              child: Text(
                note.initials,
                style: ClassroomsTextStyles.noteInitials.copyWith(
                  color: note.isMine ? c.ink2 : c.staffFg,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: ClassroomsSizes.notePad,
                decoration: BoxDecoration(
                  color: note.isMine ? c.impact : c.card,
                  borderRadius: _radius,
                  border: Border.all(color: c.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ClassroomsSizes.noteTextGap,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: ClassroomsSizes.noteMetaGap,
                      children: <Widget>[
                        Text(
                          note.author,
                          style: ClassroomsTextStyles.noteAuthor.copyWith(
                            color: ink,
                          ),
                        ),
                        Text(
                          note.timeLabel,
                          style: ClassroomsTextStyles.noteTime.copyWith(
                            color: meta,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      note.text,
                      style: ClassroomsTextStyles.noteText.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The bubble's tail: square on the corner nearest whoever wrote it.
  BorderRadius get _radius {
    const round = Radius.circular(ClassroomsSizes.noteBubbleRadius);
    const tail = Radius.circular(ClassroomsSizes.noteBubbleTail);
    return note.isMine
        ? const BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: round,
            bottomRight: tail,
          )
        : const BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: tail,
            bottomRight: round,
          );
  }
}
