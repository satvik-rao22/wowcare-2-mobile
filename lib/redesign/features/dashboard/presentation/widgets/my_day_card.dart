import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/day_key.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/dot_pill.dart';

/// My day, on an Admin's dashboard (3A1) and a Staff member's (3S1).
///
/// The same card either way. The difference is that an Admin collapses it,
/// because their day is not the screen, and a Staff member's is: Mark absent
/// and Sign Out are gated on standing inside the school geofence, and the
/// geofence line says so rather than the key failing silently.
class MyDayCard extends StatelessWidget {
  const MyDayCard({
    required this.day,
    required this.isOpen,
    required this.onScanQr,
    required this.onTransfer,
    required this.onMarkAbsent,
    required this.onSignOut,
    this.onToggle,
    this.showGeofence = false,
    super.key,
  });

  final MyDay day;

  /// Collapsed, only the title row and the status pill show.
  final bool isOpen;

  /// Null on a card that does not collapse.
  final VoidCallback? onToggle;

  /// Staff see the geofence line; an Admin's actions are not gated on it.
  final bool showGeofence;

  final VoidCallback onScanQr;
  final VoidCallback onTransfer;
  final VoidCallback onMarkAbsent;
  final VoidCallback onSignOut;

  bool get _canAct => day.isSignedIn && (!showGeofence || day.isInsideGeofence);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.cardContentGap,
        children: <Widget>[
          _title(c),
          if (isOpen) ...<Widget>[
            _tiles(c),
            _PinStrip(pin: day.signInPin),
            if (showGeofence) _geofence(c),
            _keys(),
          ],
        ],
      ),
    );
  }

  Widget _title(Colourway c) {
    final row = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            DashboardStrings.myDay,
            style: AppTextStyles.cardTitle.copyWith(color: c.ink),
          ),
        ),
        DotPill(
          label: _statusWord,
          fill: _statusFill(c),
          ink: _statusInk(c),
          dot: day.status.colour(c),
        ),
        if (onToggle != null) ...<Widget>[
          const SizedBox(width: AppSizes.space2),
          AnimatedRotation(
            duration: AppMotion.base,
            curve: AppMotion.ease,
            turns: isOpen ? .5 : 0,
            child: Icon(
              AppIcons.chevronDown,
              size: DashboardSizes.cardChevron,
              color: c.ink3,
            ),
          ),
        ],
      ],
    );

    if (onToggle == null) return row;
    return Semantics(
      button: true,
      expanded: isOpen,
      label: DashboardStrings.myDay,
      child: Pressable.surface(onTap: onToggle, child: row),
    );
  }

  Widget _tiles(Colourway c) => Row(
    spacing: DashboardSizes.dayTileGap,
    children: <Widget>[
      Expanded(
        child: _Tile(
          label: DashboardStrings.since,
          value: day.sinceLabel ?? AppStrings.notMarked,
          valueColor: day.isSignedIn ? c.successFg : c.ink3,
          isTime: true,
        ),
      ),
      Expanded(
        child: _Tile(
          label: DashboardStrings.workTime,
          value: day.workWindow,
          valueColor: c.ink,
        ),
      ),
      if (day.breakWindow != null)
        Expanded(
          child: _Tile(
            label: DashboardStrings.breakTime,
            value: day.breakWindow!,
            valueColor: c.staffFg,
            fill: c.staffBg,
          ),
        ),
    ],
  );

  Widget _geofence(Colourway c) {
    final inside = day.isInsideGeofence;
    return Container(
      padding: DashboardSizes.pinStripPad,
      decoration: BoxDecoration(
        color: inside ? c.successBg : c.dangerBg,
        borderRadius: AppRadii.innerR,
        border: Border.all(color: inside ? c.successLine : c.dangerLine),
      ),
      child: Row(
        spacing: DashboardSizes.pinStripGap,
        children: <Widget>[
          Icon(
            AppIcons.mapPin,
            size: DashboardSizes.pinStripGlyph,
            color: inside ? c.successFg : c.dangerFg,
          ),
          Expanded(
            child: Text(
              inside
                  ? DashboardStrings.insideGeofence
                  : DashboardStrings.outsideGeofence,
              style: DashboardTextStyles.reminderTitle.copyWith(
                color: inside ? c.successFg : c.dangerFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keys() => Column(
    spacing: DashboardSizes.dayKeyGap,
    children: <Widget>[
      Row(
        spacing: DashboardSizes.dayKeyGap,
        children: <Widget>[
          Expanded(
            child: DayKey(
              label: AppStrings.scanQr,
              icon: AppIcons.scanQr,
              onTap: onScanQr,
            ),
          ),
          Expanded(
            child: DayKey(
              label: DashboardStrings.transfer,
              onTap: _canAct ? onTransfer : null,
            ),
          ),
        ],
      ),
      Row(
        spacing: DashboardSizes.dayKeyGap,
        children: <Widget>[
          Expanded(
            child: DayKey(
              label: day.isAbsent
                  ? DashboardStrings.undoAbsent
                  : DashboardStrings.markAbsent,
              onTap: _canAct || day.isAbsent ? onMarkAbsent : null,
            ),
          ),
          Expanded(
            child: DayKey(
              label: AppStrings.signOut,
              isPrimary: true,
              onTap: _canAct ? onSignOut : null,
            ),
          ),
        ],
      ),
    ],
  );

  String get _statusWord => switch (day.status) {
    AttendanceStatus.signedIn => AppStrings.signedIn,
    AttendanceStatus.signedOut => AppStrings.signedOut,
    AttendanceStatus.absent => AppStrings.absent,
    AttendanceStatus.notMarked => AppStrings.notMarked,
  };

  Color _statusFill(Colourway c) => switch (day.status) {
    AttendanceStatus.signedIn => c.successBg,
    AttendanceStatus.absent => c.dangerBg,
    _ => c.altWell,
  };

  Color _statusInk(Colourway c) => switch (day.status) {
    AttendanceStatus.signedIn => c.successFg,
    AttendanceStatus.absent => c.dangerFg,
    _ => c.ink2,
  };
}

/// One of the three wells across the top of My day.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.fill,
    this.isTime = false,
  });

  final String label;
  final String value;
  final Color valueColor;

  /// Set, the tile is a tint rather than a well: the break, which is sun.
  final Color? fill;

  /// The Since tile prints a clock time, which is a size up from a window.
  final bool isTime;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: DashboardSizes.dayTileTextGap,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: DashboardTextStyles.dayTileLabel.copyWith(color: c.ink3),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (isTime
                      ? DashboardTextStyles.dayTileTime
                      : DashboardTextStyles.dayTileRange)
                  .copyWith(color: valueColor),
        ),
      ],
    );

    if (fill != null) {
      return Container(
        padding: DashboardSizes.dayTilePad,
        decoration: BoxDecoration(color: fill, borderRadius: AppRadii.innerR),
        child: child,
      );
    }
    return SurfaceBox(
      surface: AppSurfaces.well(c),
      padding: DashboardSizes.dayTilePad,
      child: child,
    );
  }
}

/// The sun strip that carries the four digits the kiosk pad wants.
class _PinStrip extends StatelessWidget {
  const _PinStrip({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: DashboardSizes.pinStripPad,
      decoration: BoxDecoration(
        color: c.staffBg,
        borderRadius: AppRadii.innerR,
        border: Border.all(color: c.staffLine),
      ),
      child: Row(
        spacing: DashboardSizes.pinStripGap,
        children: <Widget>[
          Icon(
            AppIcons.lock,
            size: DashboardSizes.pinStripGlyph,
            color: c.staffFg,
          ),
          Expanded(
            child: Text(
              DashboardStrings.signInPin,
              style: DashboardTextStyles.reminderTitle.copyWith(
                color: c.staffFg,
              ),
            ),
          ),
          Text(pin, style: DashboardTextStyles.pin.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
