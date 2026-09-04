import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// One staff member on the roster (6a), which opens in place rather than
/// navigating: the facts under a name are what the screen is usually being
/// asked for, and a phone number should not cost a screen.
///
/// In select mode the row picks instead of opening, and the checkbox takes
/// the place the chevron would have had.
class StaffRowCard extends StatelessWidget {
  const StaffRowCard({
    required this.member,
    required this.isExpanded,
    required this.onTap,
    required this.onCall,
    required this.onOpen,
    this.onMoreActions,
    this.isSelectMode = false,
    this.isSelected = false,
    super.key,
  });

  final StaffMember member;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onOpen;

  /// Null for a viewer who may not change anything, which is what takes the
  /// More actions key off the row.
  final VoidCallback? onMoreActions;

  final bool isSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(c),
          if (isExpanded && !isSelectMode) _facts(c),
        ],
      ),
    );
  }

  Widget _header(Colourway c) {
    final flag = _flag();

    return Pressable.surface(
      onTap: onTap,
      child: Padding(
        padding: AppSizes.rowPad,
        child: Row(
          spacing: AppSizes.rowGap,
          children: <Widget>[
            if (isSelectMode) AppCheckbox(checked: isSelected),
            AppAvatar(
              initials: member.initials,
              tone: AvatarTone.staff,
              attendance: member.isActive ? member.attendance : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSizes.rowTextGap,
                children: <Widget>[
                  Text(
                    member.name,
                    style: AppTextStyles.rowName.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    StaffStrings.memberSubline(member),
                    style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ?flag,
            if (!isSelectMode)
              AnimatedRotation(
                turns: isExpanded ? .5 : 0,
                duration: AppMotion.fast,
                curve: AppMotion.ease,
                child: Icon(
                  AppIcons.chevronDown,
                  size: StaffSizes.rowCaret,
                  color: c.ink3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Upcoming and inactive say so; an Admin is flagged because it changes
  /// what they can reach, not because the role has a colour of its own.
  Widget? _flag() {
    if (member.isUpcoming) {
      return StatusPill(
        label: StaffStrings.statusLabel(StaffStatus.upcoming),
        tone: PillTone.staff,
        small: true,
      );
    }
    if (member.isInactive) {
      return StatusPill(
        label: StaffStrings.statusLabel(StaffStatus.inactive),
        small: true,
      );
    }
    if (member.role == StaffRole.admin) {
      return StatusPill(
        label: StaffStrings.roleLabel(StaffRole.admin),
        small: true,
      );
    }
    return null;
  }

  Widget _facts(Colourway c) => Padding(
    padding: StaffSizes.expandedPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.expandedGap,
      children: <Widget>[
        Container(height: AppSizes.hairline, color: c.divider),
        for (final fact in _rows()) _FactRow(fact: fact),
        Row(
          spacing: StaffSizes.keyGridGap,
          children: <Widget>[
            Expanded(
              child: _RowKey(label: StaffStrings.call, onTap: onCall),
            ),
            if (onMoreActions != null)
              Expanded(
                child: _RowKey(
                  label: StaffStrings.moreActions,
                  onTap: onMoreActions!,
                ),
              ),
          ],
        ),
        _OpenKey(onTap: onOpen),
      ],
    ),
  );

  List<_Fact> _rows() => <_Fact>[
    _Fact(StaffStrings.designation, member.designation),
    _Fact(StaffStrings.primaryClassroom, StaffStrings.scopeOf(member)),
    _Fact(
      StaffStrings.allowedIn,
      member.allowedClassrooms.isEmpty
          ? StaffStrings.allClassrooms
          : member.allowedClassrooms.join(', '),
    ),
    _Fact(StaffStrings.today, _todayLine()),
    _Fact(StaffStrings.breakLabel, _breakLine()),
    _Fact(StaffStrings.phone, member.phone),
    if (onMoreActions != null)
      _Fact(StaffStrings.email, member.email, quiet: true),
  ];

  String _todayLine() {
    final shift = member.todayShift;
    if (shift == null || shift.isDayOff) return StaffStrings.notScheduled;
    return StaffStrings.signedRange(
      StaffStrings.clock(shift.startMinutes!),
      StaffStrings.clock(shift.endMinutes!),
    );
  }

  String _breakLine() {
    final shift = member.todayShift;
    if (shift == null || !shift.hasBreak) return StaffStrings.noBreak;
    return StaffStrings.signedRange(
      StaffStrings.clock(shift.breakStartMinutes!),
      StaffStrings.clock(shift.breakEndMinutes!),
    );
  }
}

/// One label and value inside an expanded row.
class _Fact {
  const _Fact(this.label, this.value, {this.quiet = false});

  final String label;
  final String value;

  /// An email is quieter than the rest, because it is the longest and the
  /// least often what the row was opened for.
  final bool quiet;
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: StaffSizes.expandedGap,
      children: <Widget>[
        SizedBox(
          width: StaffSizes.expandedLabelWidth,
          child: Text(
            fact.label,
            style: StaffTextStyles.factLabel.copyWith(color: c.ink3),
          ),
        ),
        Expanded(
          child: Text(
            fact.value,
            style: StaffTextStyles.factValue.copyWith(
              color: fact.quiet ? c.ink2 : c.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// One of the two quiet keys at the foot of an expanded row.
class _RowKey extends StatelessWidget {
  const _RowKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.keySecondary(c),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.rowActionKey.copyWith(color: c.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// The one pink key inside a row: the record itself.
class _OpenKey extends StatelessWidget {
  const _OpenKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: StaffStrings.openProfile,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyPrimary(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: StaffSizes.dockedKeyPad,
          alignment: Alignment.center,
          child: Text(
            StaffStrings.openProfile,
            style: StaffTextStyles.rowActionKey.copyWith(color: c.onPink),
          ),
        ),
      ),
    );
  }
}
