import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/alt_well_tile.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// Who is arriving in this classroom and who is leaving it (7f).
///
/// Read-only. These are moves already booked in Movements; nothing on this
/// screen books one, which is what the module's costly list rules out.
class MovementsCard extends StatelessWidget {
  const MovementsCard({
    required this.movements,
    required this.arriving,
    required this.leaving,
    super.key,
  });

  final List<ClassroomMovement> movements;
  final int arriving;
  final int leaving;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.profileCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.profileCardGap,
        children: <Widget>[
          SectionEyebrow(
            label: ClassroomsStrings.movements,
            trailing: Flexible(
              child: Text(
                ClassroomsStrings.movementsMeta(arriving, leaving),
                style: ClassroomsTextStyles.cardMeta.copyWith(color: c.ink3),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (movements.isEmpty)
            Text(
              ClassroomsStrings.noMovements,
              style: ClassroomsTextStyles.movementSub.copyWith(color: c.ink3),
            )
          else
            for (final movement in movements) _MovementRow(movement: movement),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final ClassroomMovement movement;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AltWellTile(
      subtle: true,
      padding: ClassroomsSizes.movementRowPad,
      child: Row(
        spacing: ClassroomsSizes.movementGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: movement.isArriving ? c.studentBg : c.well,
              radius: ClassroomsSizes.movementTileRadius,
            ),
            width: ClassroomsSizes.movementTile,
            height: ClassroomsSizes.movementTile,
            alignment: Alignment.center,
            child: Icon(
              movement.isArriving ? AppIcons.arrowRight : AppIcons.arrowLeft,
              size: ClassroomsSizes.movementGlyph,
              color: movement.isArriving ? c.student : c.ink2,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  movement.isArriving
                      ? ClassroomsStrings.movesIn(movement.name)
                      : ClassroomsStrings.movesOut(movement.name),
                  style: ClassroomsTextStyles.movementTitle.copyWith(
                    color: c.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  movement.detail,
                  style: ClassroomsTextStyles.movementSub.copyWith(
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
