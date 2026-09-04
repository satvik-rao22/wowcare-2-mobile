import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The four classrooms nobody designs (7j): nobody on the roll, a search that
/// found nobody, a role that may look but not change, and a screen showing
/// what it last reached.
///
/// One shape for all four: a well-backed glyph, a title, a line, and at most
/// one pink key. A view-only screen keeps its key visible and dead, so the
/// classroom does not look broken.
class ClassroomStateView extends StatelessWidget {
  const ClassroomStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.deadKeyLabel,
    this.hint,
    this.iconSize = ClassroomsSizes.stateIcon,
    this.glyphSize = ClassroomsSizes.stateGlyph,
    super.key,
  });

  /// Nobody on the roll yet, with the key that fixes it.
  ClassroomStateView.noStudents({
    required String classroomName,
    required int places,
    required int unassigned,
    VoidCallback? onAssign,
    super.key,
  }) : icon = AppIcons.users,
       title = ClassroomsStrings.nobodyHereTitle,
       message = ClassroomsStrings.nobodyHereBody(
         classroomName,
         places,
         unassigned,
       ),
       primaryLabel = ClassroomsStrings.assignStudents,
       onPrimary = onAssign,
       secondaryLabel = null,
       onSecondary = null,
       deadKeyLabel = onAssign == null
           ? ClassroomsStrings.assignStudents
           : null,
       hint = null,
       iconSize = ClassroomsSizes.stateIcon,
       glyphSize = ClassroomsSizes.stateGlyph;

  /// A search inside one classroom that found nobody.
  ClassroomStateView.noResults({
    required String query,
    required String classroomName,
    required VoidCallback onClearSearch,
    IconData glyph = AppIcons.search,
    bool isStaff = false,
    super.key,
  }) : icon = glyph,
       title = isStaff
           ? ClassroomsStrings.noStaffCalled(query)
           : ClassroomsStrings.noStudentCalled(query),
       message = ClassroomsStrings.searchOnlyHere(classroomName),
       primaryLabel = null,
       onPrimary = null,
       secondaryLabel = ClassroomsStrings.clearSearch,
       onSecondary = onClearSearch,
       deadKeyLabel = null,
       hint = null,
       iconSize = ClassroomsSizes.stateIcon,
       glyphSize = ClassroomsSizes.stateGlyph;

  /// The role may open a classroom and change nothing in it.
  const ClassroomStateView.viewOnly({super.key})
    : icon = AppIcons.lock,
      title = ClassroomsStrings.lookNotChangeTitle,
      message = ClassroomsStrings.lookNotChangeBody,
      primaryLabel = null,
      onPrimary = null,
      secondaryLabel = null,
      onSecondary = null,
      deadKeyLabel = ClassroomsStrings.assignStudents,
      hint = ClassroomsStrings.deadKeysHint,
      iconSize = ClassroomsSizes.stateIcon,
      glyphSize = ClassroomsSizes.stateGlyph;

  final IconData icon;
  final String title;
  final String message;

  final String? primaryLabel;
  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// A key that stays visible and does not move, because the role behind it
  /// cannot press it.
  final String? deadKeyLabel;

  /// The quiet line under a dead key, explaining why it is there.
  final String? hint;

  final double iconSize;
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: ClassroomsSizes.stateGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.emptyIcon(c),
            width: iconSize,
            height: iconSize,
            alignment: Alignment.center,
            child: Icon(icon, size: glyphSize, color: c.ink3),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: ClassroomsSizes.stateTextGap,
            children: <Widget>[
              Text(
                title,
                style: ClassroomsTextStyles.stateTitle.copyWith(color: c.ink),
                textAlign: TextAlign.center,
              ),
              Text(
                message,
                style: ClassroomsTextStyles.stateBody.copyWith(color: c.ink2),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (primaryLabel != null && onPrimary != null)
            PrimaryKey(
              label: primaryLabel!,
              onTap: onPrimary,
              expand: false,
              padding: ClassroomsSizes.tryAgainKeyPad,
            ),
          if (secondaryLabel != null && onSecondary != null)
            SecondaryKey(
              label: secondaryLabel!,
              onTap: onSecondary,
              expand: false,
              padding: ClassroomsSizes.tryAgainKeyPad,
            ),
          if (deadKeyLabel != null) _DeadKey(label: deadKeyLabel!),
          if (hint != null)
            Text(
              hint!,
              style: ClassroomsTextStyles.stateHint.copyWith(color: c.ink3),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

/// A key with no permission behind it: recessed into the tray, ink3 label,
/// still in its place, and it does not move.
class _DeadKey extends StatelessWidget {
  const _DeadKey({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: SurfaceBox(
        surface: AppSurfaces.keyDisabled(c),
        padding: ClassroomsSizes.deadKeyPad,
        alignment: Alignment.center,
        child: Text(
          label,
          style: ClassroomsTextStyles.deadKey.copyWith(color: c.ink3),
        ),
      ),
    );
  }
}
