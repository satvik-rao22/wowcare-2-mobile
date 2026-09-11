import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/scheduling/entities/scheduling_block_status_kind.dart';
import 'package:wowcare/domain/features/scheduling/services/scheduling_block_status_rules.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';

/// How a staffing-ratio kind is *rendered*: colours, icons, and labels for the
/// Week (icons) and Day (slot blocks) views.
///
/// The rules that decide WHICH kind applies live in
/// [SchedulingBlockStatusRules] in the domain layer — this file only styles the
/// answer. It also lives in `widgets/` rather than a `utils/` folder because it
/// returns `Widget`s ([weekViewIcon], [dayLegendDot]).
///
/// Colours come from [AppColors] semantic ratio tokens; none are declared here.
/// Ratio state is never signalled by colour alone — the week view pairs it with
/// a distinct icon per kind, and the day view with [dayViewLabel] text.
class SchedulingBlockStatusStyle {
  const SchedulingBlockStatusStyle._();

  // ── Colours (semantic tokens, not literals) ──────────────────────────────
  static const Color dayUnderRatioColor = AppColors.ratioUnderStaffedColor;
  static const Color dayInRatioColor = AppColors.ratioInRatioColor;
  static const Color dayExtraStaffColor = AppColors.ratioExtraStaffColor;
  static const Color dayEmptyColor = AppColors.ratioEmptyColor;

  static const Color badgeUnderRatioColor = AppColors.errorColor;
  static const Color badgeInRatioColor = AppColors.ratioInRatioBadgeColor;
  static const Color badgeExtraStaffColor = AppColors.ratioExtraStaffColor;

  // ── Rule delegation ──────────────────────────────────────────────────────
  // Thin pass-throughs to the domain rules, kept so existing call sites read
  // the same. New code should call SchedulingBlockStatusRules directly.

  /// See [SchedulingBlockStatusRules.parseKind].
  static SchedulingBlockStatusKind parseKind(
    String? blockStatus, {
    int scheduledStaff = 0,
    int requiredStaff = 0,
  }) =>
      SchedulingBlockStatusRules.parseKind(
        blockStatus,
        scheduledStaff: scheduledStaff,
        requiredStaff: requiredStaff,
      );

  /// See [SchedulingBlockStatusRules.kindFromPrdCounts].
  static SchedulingBlockStatusKind kindFromPrdCounts({
    required int scheduledStaff,
    required int requiredStaff,
    bool withinMonitoringWindow = true,
  }) =>
      SchedulingBlockStatusRules.kindFromPrdCounts(
        scheduledStaff: scheduledStaff,
        requiredStaff: requiredStaff,
        withinMonitoringWindow: withinMonitoringWindow,
      );

  // ── Domain kind <-> presentation slot enums ──────────────────────────────

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

  // ── Colours ──────────────────────────────────────────────────────────────

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

  // ── Labels ───────────────────────────────────────────────────────────────

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

  // ── Icons ────────────────────────────────────────────────────────────────
  // Each kind gets a visually distinct mark, not just a colour: a check for in
  // ratio, a warning triangle for under, a filled dot for extra staff.

  static Widget weekViewIcon(
    SchedulingBlockStatusKind kind, {
    double size = 18,
  }) {
    switch (kind) {
      case SchedulingBlockStatusKind.inRatio:
        return AppIcon(
          MediaRes.greenCheckCircleIcon,
          width: size,
          height: size,
          tone: IconTone.success,
        );
      case SchedulingBlockStatusKind.underRatio:
        return AppIcon(
          MediaRes.alertTriangleIcon,
          width: size,
          height: size,
          color: AppColors.errorColor,
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
  }) =>
      weekViewIcon(fromClassroomRatioStatus(status), size: size);

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
