import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';

import '../../../../app/theme/media_res.dart';

import '../model/scheduling_models.dart';

/// Shared AppColors, icons, and labels for Week (icons) and Day (slot blocks).

class SchedulingBlockStatusStyle {
  const SchedulingBlockStatusStyle._();

  static const Color dayUnderRatioColor = Color(0xFFF38D8D);

  static const Color dayInRatioColor = Color(0xFFACF3AA);

  static const Color dayExtraStaffColor = Color(0xFF5978F7);

  static const Color dayEmptyColor = Color(0xFFE9ECEF);

  static const Color badgeUnderRatioColor = AppColors.errorColor;

  static const Color badgeInRatioColor = Color(0xFF3D9A4A);

  static const Color badgeExtraStaffColor = dayExtraStaffColor;

  /// Maps forecast API `blockStatus` to a ratio kind. When [blockStatus] is

  /// non-empty, counts are not used (API status is authoritative).

  static SchedulingBlockStatusKind parseKind(
    String? blockStatus, {

    int scheduledStaff = 0,

    int requiredStaff = 0,
  }) {
    final raw = blockStatus?.trim().toUpperCase() ?? '';

    if (raw.isEmpty) {
      return _kindFromCounts(scheduledStaff, requiredStaff);
    }

    switch (raw) {
      case 'IN_RATIO':
      case 'IN RATIO':
      case 'INRATIO':
        return SchedulingBlockStatusKind.inRatio;

      case 'UNDER_RATIO':
      case 'UNDER RATIO':
      case 'UNDERRATIO':
      case 'NOT_IN_RATIO':
      case 'NOT IN RATIO':
        return SchedulingBlockStatusKind.underRatio;

      case 'EXTRA_STAFF':
      case 'EXTRA STAFF':
      case 'OVER_STAFF':
      case 'OVER STAFF':
      case 'OVER_RATIO':
      case 'OVER RATIO':
        return SchedulingBlockStatusKind.extraStaff;
    }

    if (_matchesUnder(raw)) return SchedulingBlockStatusKind.underRatio;

    if (_matchesExtra(raw)) return SchedulingBlockStatusKind.extraStaff;

    if (_matchesIn(raw)) return SchedulingBlockStatusKind.inRatio;

    return _kindFromCounts(scheduledStaff, requiredStaff);
  }

  static bool _matchesUnder(String raw) =>
      raw.contains('UNDER') ||
      raw.contains('BELOW') ||
      raw.contains('NOT_IN') ||
      raw.contains('NOT IN');

  /// Avoid `contains('OVER')` — it is not a substring of `IN_RATIO`, but

  /// explicit enums are matched first; fallbacks use prefixed tokens only.

  static bool _matchesExtra(String raw) =>
      raw.contains('EXTRA_STAFF') ||
      raw.contains('EXTRA STAFF') ||
      raw.contains('OVER_STAFF') ||
      raw.contains('OVER STAFF') ||
      raw.contains('OVER_RATIO') ||
      raw.contains('OVER RATIO') ||
      raw.startsWith('EXTRA_') ||
      raw.startsWith('OVER_');

  static bool _matchesIn(String raw) =>
      raw.contains('IN_RATIO') ||
      raw == 'IN' ||
      raw.contains('IN RATIO') ||
      raw.contains('OK');

  /// PRD Use Case 6: derive block colour from scheduled vs required staff.
  static SchedulingBlockStatusKind kindFromPrdCounts({
    required int scheduledStaff,
    required int requiredStaff,
    bool withinMonitoringWindow = true,
  }) {
    if (!withinMonitoringWindow) return SchedulingBlockStatusKind.empty;
    if (scheduledStaff < requiredStaff) {
      return SchedulingBlockStatusKind.underRatio;
    }
    if (scheduledStaff > requiredStaff) {
      return SchedulingBlockStatusKind.extraStaff;
    }
    return SchedulingBlockStatusKind.inRatio;
  }

  static SchedulingBlockStatusKind _kindFromCounts(
    int scheduled,
    int required,
  ) => kindFromPrdCounts(scheduledStaff: scheduled, requiredStaff: required);

  static TimeSlotStatus toTimeSlotStatus(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return TimeSlotStatus.underRatio;

      case SchedulingBlockStatusKind.extraStaff:
        return TimeSlotStatus.overRatio;

      case SchedulingBlockStatusKind.inRatio:
        return TimeSlotStatus.inRatio;

      case SchedulingBlockStatusKind.empty:
        return TimeSlotStatus.empty;
    }
  }

  static ClassroomRatioStatus toClassroomRatioStatus(
    SchedulingBlockStatusKind kind,
  ) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return ClassroomRatioStatus.underRatio;

      case SchedulingBlockStatusKind.extraStaff:
        return ClassroomRatioStatus.overRatio;

      case SchedulingBlockStatusKind.inRatio:
      case SchedulingBlockStatusKind.empty:
        return ClassroomRatioStatus.inRatio;
    }
  }

  static SchedulingBlockStatusKind fromTimeSlotStatus(TimeSlotStatus status) {
    switch (status) {
      case TimeSlotStatus.underRatio:
        return SchedulingBlockStatusKind.underRatio;

      case TimeSlotStatus.overRatio:
        return SchedulingBlockStatusKind.extraStaff;

      case TimeSlotStatus.inRatio:
        return SchedulingBlockStatusKind.inRatio;

      case TimeSlotStatus.empty:
        return SchedulingBlockStatusKind.empty;
    }
  }

  static SchedulingBlockStatusKind fromClassroomRatioStatus(
    ClassroomRatioStatus status,
  ) {
    switch (status) {
      case ClassroomRatioStatus.underRatio:
        return SchedulingBlockStatusKind.underRatio;

      case ClassroomRatioStatus.overRatio:
        return SchedulingBlockStatusKind.extraStaff;

      case ClassroomRatioStatus.inRatio:
        return SchedulingBlockStatusKind.inRatio;
    }
  }

  static Color daySlotColor(TimeSlotStatus status) =>
      daySlotColorForKind(fromTimeSlotStatus(status));

  static Color daySlotColorForKind(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return dayUnderRatioColor;

      case SchedulingBlockStatusKind.extraStaff:
        return dayExtraStaffColor;

      case SchedulingBlockStatusKind.inRatio:
        return dayInRatioColor;

      case SchedulingBlockStatusKind.empty:
        return dayEmptyColor;
    }
  }

  static Color badgeColorForKind(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return badgeUnderRatioColor;

      case SchedulingBlockStatusKind.extraStaff:
        return badgeExtraStaffColor;

      case SchedulingBlockStatusKind.inRatio:
        return badgeInRatioColor;

      case SchedulingBlockStatusKind.empty:
        return AppColors.primaryColor.withValues(alpha: 0.7);
    }
  }

  static String weekViewLabel(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return 'Not In Ratio';

      case SchedulingBlockStatusKind.extraStaff:
        return 'Extra Staff';

      case SchedulingBlockStatusKind.inRatio:
        return 'In Ratio';

      case SchedulingBlockStatusKind.empty:
        return 'No Schedule';
    }
  }

  static String dayViewLabel(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return 'Not in Ratio/Break Time';
      case SchedulingBlockStatusKind.extraStaff:
        return 'Extra staff';
      case SchedulingBlockStatusKind.inRatio:
        return 'In Ratio/Work Time';
      case SchedulingBlockStatusKind.empty:
        return 'No Schedule';
    }
  }

  /// Short badge text for classroom slot dialogs (matches design mockups).
  static String ratioBadgeLabel(SchedulingBlockStatusKind kind) {
    switch (kind) {
      case SchedulingBlockStatusKind.underRatio:
        return 'Not in Ratio/Break Time';
      case SchedulingBlockStatusKind.extraStaff:
        return 'Extra Staff';
      case SchedulingBlockStatusKind.inRatio:
        return 'In Ratio/Work Time';
      case SchedulingBlockStatusKind.empty:
        return 'No Schedule';
    }
  }

  static String labelFromBlockStatus(
    String? blockStatus, {

    int scheduledStaff = 0,

    int requiredStaff = 0,

    bool dayView = false,
  }) {
    final kind = parseKind(
      blockStatus,

      scheduledStaff: scheduledStaff,

      requiredStaff: requiredStaff,
    );

    return dayView ? dayViewLabel(kind) : weekViewLabel(kind);
  }

  static Widget weekViewIcon(
    SchedulingBlockStatusKind kind, {

    double size = 18,
  }) {
    switch (kind) {
      case SchedulingBlockStatusKind.inRatio:
        return SvgPicture.asset(
          MediaRes.greenCheckCircleIcon,

          width: size,

          height: size,
        );

      case SchedulingBlockStatusKind.underRatio:
        return SvgPicture.asset(
          MediaRes.alertTriangleIcon,

          width: size,

          height: size,

          colorFilter: const ColorFilter.mode(
            AppColors.errorColor,

            BlendMode.srcIn,
          ),
        );

      case SchedulingBlockStatusKind.extraStaff:
        return Container(
          width: size,

          height: size,

          decoration: const BoxDecoration(
            color: dayExtraStaffColor,

            shape: BoxShape.circle,
          ),
        );

      case SchedulingBlockStatusKind.empty:
        return SizedBox(width: size, height: size);
    }
  }

  static Widget weekViewIconForClassroomStatus(
    ClassroomRatioStatus status, {

    double size = 18,
  }) => weekViewIcon(fromClassroomRatioStatus(status), size: size);

  static Widget dayLegendDot(SchedulingBlockStatusKind kind) {
    return Container(
      width: 9,

      height: 9,

      decoration: BoxDecoration(
        color: daySlotColorForKind(kind),

        shape: BoxShape.circle,
      ),
    );
  }
}

extension ForecastSlotDetailStyle on ForecastSlotDetail {
  /// Grid colour: grey outside monitoring when all counts are zero.
  TimeSlotStatus get displaySlotStatus {
    if (!withinMonitoringWindow &&
        expectedStudents == 0 &&
        requiredStaff == 0 &&
        scheduledStaff == 0) {
      return TimeSlotStatus.empty;
    }
    return slotStatus;
  }

  SchedulingBlockStatusKind get statusKind =>
      SchedulingBlockStatusStyle.parseKind(
        blockStatus,
        scheduledStaff: scheduledStaff,
        requiredStaff: requiredStaff,
      );

  TimeSlotStatus get slotStatus =>
      SchedulingBlockStatusStyle.toTimeSlotStatus(statusKind);

  String get statusLabel => SchedulingBlockStatusStyle.labelFromBlockStatus(
    blockStatus,

    scheduledStaff: scheduledStaff,

    requiredStaff: requiredStaff,
  );

  String get dayViewStatusLabel =>
      SchedulingBlockStatusStyle.dayViewLabel(statusKind);

  String get ratioBadgeLabel =>
      SchedulingBlockStatusStyle.ratioBadgeLabel(statusKind);
}
