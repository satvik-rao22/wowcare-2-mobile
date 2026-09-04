import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// What "More actions" offers on a roster row (6a).
///
/// The frame also draws "Change the Sign-In PIN". It is not here: the PIN
/// endpoint is read only, so resetting one from the app is on the module's
/// costly list and the app must not offer a key that cannot work.
enum StaffAction {
  /// Mark them in when they could not do it themselves. The record says who
  /// did it, which is why the note under the label says so.
  signInForThem,

  editShifts,
  changeClassrooms,
  deactivate,
  reactivate,
}

/// The sheet a roster row's More actions key opens, and 6c's own action list.
///
/// It resolves to the [StaffAction] that was picked, or to null when it is
/// dismissed; the caller does the work, because half of these leave the
/// screen and the sheet should not know where to.
class StaffActionsSheet extends StatelessWidget {
  const StaffActionsSheet({required this.member, super.key});

  final StaffMember member;

  static Future<StaffAction?> show(
    BuildContext context, {
    required StaffMember member,
  }) => showAppSheet<StaffAction>(
    context,
    builder: (_) => StaffActionsSheet(member: member),
  );

  List<StaffAction> get _actions => <StaffAction>[
    if (member.isActive) StaffAction.signInForThem,
    StaffAction.editShifts,
    StaffAction.changeClassrooms,
    if (member.isInactive) StaffAction.reactivate else StaffAction.deactivate,
  ];

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    header: _Header(member: member),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.actionRowGap,
      children: <Widget>[
        for (final action in _actions)
          _ActionRow(
            action: action,
            onTap: () => Navigator.of(context).pop(action),
          ),
      ],
    ),
    footer: <Widget>[
      PrimaryKey(
        label: StaffStrings.openProfile,
        padding: StaffSizes.sheetKeyPad,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: StaffSizes.sheetSectionGap,
      children: <Widget>[
        AppAvatar(
          initials: member.initials,
          size: StaffSizes.sheetAvatar,
          tone: AvatarTone.staff,
          textStyle: StaffTextStyles.sheetInitials,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                member.name,
                style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                StaffStrings.memberSubline(member),
                style: StaffTextStyles.sheetSub.copyWith(color: c.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One action: a two-letter tile, a label, and the line that says what it
/// really does.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});

  final StaffAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isDanger = action == StaffAction.deactivate;

    return Semantics(
      button: true,
      label: _label(action),
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.keySecondary(c),
          padding: StaffSizes.actionRowPad,
          child: Row(
            spacing: StaffSizes.sheetSectionGap,
            children: <Widget>[
              Container(
                width: StaffSizes.actionGlyphTile,
                height: StaffSizes.actionGlyphTile,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tileFill(action, c),
                  borderRadius: AppRadii.chipR,
                ),
                child: Text(
                  _glyph(action),
                  style: StaffTextStyles.actionGlyph.copyWith(
                    color: _tileInk(action, c),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _label(action),
                      style: StaffTextStyles.actionLabel.copyWith(
                        color: isDanger ? c.dangerFg : c.ink,
                      ),
                    ),
                    Text(
                      _note(action),
                      style: StaffTextStyles.actionNote.copyWith(color: c.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(StaffAction action) => switch (action) {
    StaffAction.signInForThem => StaffStrings.signInForThem,
    StaffAction.editShifts => StaffStrings.editWeekShifts,
    StaffAction.changeClassrooms => StaffStrings.changeClassrooms,
    StaffAction.deactivate => StaffStrings.deactivate,
    StaffAction.reactivate => StaffStrings.reactivate,
  };

  static String _note(StaffAction action) => switch (action) {
    StaffAction.signInForThem => StaffStrings.signInForThemNote,
    StaffAction.editShifts => StaffStrings.editWeekShiftsNote,
    StaffAction.changeClassrooms => StaffStrings.changeClassroomsNote,
    StaffAction.deactivate => StaffStrings.deactivateNote,
    StaffAction.reactivate => StaffStrings.reactivateNote,
  };

  /// Two letters rather than a glyph, exactly as the frame draws it: these
  /// five actions have no icon anybody would read the same way.
  static String _glyph(StaffAction action) => switch (action) {
    StaffAction.signInForThem => 'IN',
    StaffAction.editShifts => 'SH',
    StaffAction.changeClassrooms => 'RM',
    StaffAction.deactivate => 'OFF',
    StaffAction.reactivate => 'ON',
  };

  static Color _tileFill(StaffAction action, Colourway c) => switch (action) {
    StaffAction.signInForThem || StaffAction.reactivate => c.successBg,
    StaffAction.editShifts => c.staffBg,
    StaffAction.changeClassrooms => c.neutralBg,
    StaffAction.deactivate => c.dangerBg,
  };

  static Color _tileInk(StaffAction action, Colourway c) => switch (action) {
    StaffAction.signInForThem || StaffAction.reactivate => c.successFg,
    StaffAction.editShifts => c.staffFg,
    StaffAction.changeClassrooms => c.neutralFg,
    StaffAction.deactivate => c.dangerFg,
  };
}
