import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class ShimmerLoader extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color? cardColor;
  final EdgeInsets? margin;

  const ShimmerLoader({
    this.child,
    this.height,
    this.width,
    this.borderRadius,
    this.cardColor,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        height: height,
        width: width,
        margin: margin ?? const EdgeInsets.all(0),
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          color: AppColors.whiteColor,
        ),
      ),
    );
  }
}

class AttendanceCardShimmer extends StatelessWidget {
  final EdgeInsets? margin;

  const AttendanceCardShimmer({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            // Name and details placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.4,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Duration placeholder
            Container(
              height: 15,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCardShimmer extends StatelessWidget {
  final EdgeInsets? margin;

  const SummaryCardShimmer({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Number placeholder
                Container(
                  height: 22,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                // Progress bar placeholder
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title placeholder
            Container(
              height: 15,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Legend placeholders
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 13,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  height: 13,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching MovementsCard — header + 3 movement rows.
/// Each row mirrors the date-column / divider-bar / details / avatar-stack layout.
class MovementsCardShimmer extends StatelessWidget {
  const MovementsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          3,
          (i) => _MovementRowShimmer(key: ValueKey(i)),
        ),
      ),
    );
  }
}

class _MovementRowShimmer extends StatelessWidget {
  const _MovementRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Date column placeholder
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 36,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Coloured bar
          Container(
            width: 3,
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Details column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 15,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Avatar stack placeholder
          Container(
            width: 45,
            height: 45,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching AvailabilityCard table layout:
/// header row (Classroom | Morning | Afternoon) + skeleton data rows.
class AvailabilityCardShimmer extends StatelessWidget {
  const AvailabilityCardShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header row skeleton
            Container(
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 16,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: MaterialHues.grey200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: MaterialHues.grey200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: MaterialHues.grey200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Data rows skeleton
            ...List.generate(
              rowCount,
              (i) => _AvailabilityRowShimmer(key: ValueKey(i)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityRowShimmer extends StatelessWidget {
  const _AvailabilityRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Classroom cell
          Expanded(
            flex: 16,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.whiteColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Morning cell
          Expanded(
            flex: 8,
            child: Center(
              child: Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Afternoon cell
          Expanded(
            flex: 8,
            child: Center(
              child: Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder specifically matching the collapsed StaffCard layout.
class StaffCardShimmer extends StatelessWidget {
  final EdgeInsets? margin;

  const StaffCardShimmer({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.blackColor.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox placeholder
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar placeholder
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Name and classroom placeholders
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Classroom
                  Container(
                    height: 14,
                    width: MediaQuery.of(context).size.width * 0.18,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching the billing transaction card header
/// (avatar + name/badge column + amount/date column). Mirrors [StaffCardShimmer]
/// so billing lists show the card structure while loading.
class BillingTransactionShimmer extends StatelessWidget {
  final EdgeInsets? margin;

  const BillingTransactionShimmer({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaterialHues.grey200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar placeholder (matches the 50px card avatar).
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // Name + status badge.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  bar(double.infinity, 14),
                  const SizedBox(height: 8),
                  bar(96, 18),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + date.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                bar(70, 14),
                const SizedBox(height: 8),
                bar(96, 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching the Staff Scheduling profile card:
/// avatar + name/designation/classroom header, three hour tiles, and a
/// day timeline placeholder. Used for the first-time load so the user sees
/// the card structure instead of a blank area or spinner.
class StaffSchedulingShimmer extends StatelessWidget {
  const StaffSchedulingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border.all(
          color: const Color.fromARGB(255, 232, 234, 234),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: MaterialHues.grey300,
        highlightColor: MaterialHues.grey100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 22,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i < 2 ? 16 : 20),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for the hour-tiles + day timeline portion only — used when a
/// staff member is already selected and we're refreshing day-specific data
/// (so the profile header stays put and only the body skeletons animate).
class StaffShiftsBodyShimmer extends StatelessWidget {
  const StaffShiftsBodyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Column(
        children: [
          ...List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? 16 : 20),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching the Classroom Schedule table card:
/// header row plus classroom/staff rows with left entity column and right
/// time/status column (week pills or day Gantt blocks).
class ClassroomSchedulingShimmer extends StatelessWidget {
  const ClassroomSchedulingShimmer({
    super.key,
    this.rowCount = 4,
    this.showDayTimelineBlocks = false,
  });

  final int rowCount;
  final bool showDayTimelineBlocks;

  static const double _statusColumnWidth = 140;
  static const double _leftColumnWidth = 152;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border.all(color: const Color(0x33162831)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ShimmerTableRow(
                left: Container(
                  height: 16,
                  width: 90,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                right: Container(
                  height: 16,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                headerBackground: true,
              ),
              for (int i = 0; i < rowCount; i++) ...[
                _ShimmerTableRow(
                  left: _EntityCellPlaceholder(width: _leftColumnWidth),
                  right: showDayTimelineBlocks
                      ? _TimelineBlocksPlaceholder()
                      : _TimePillPlaceholder(),
                ),
                if (i == 0)
                  _ShimmerTableRow(
                    left: _EntityCellPlaceholder(
                      width: _leftColumnWidth,
                      compact: true,
                    ),
                    right: showDayTimelineBlocks
                        ? _TimelineBlocksPlaceholder()
                        : _TimePillPlaceholder(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerTableRow extends StatelessWidget {
  const _ShimmerTableRow({
    required this.left,
    required this.right,
    this.headerBackground = false,
  });

  final Widget left;
  final Widget right;
  final bool headerBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColoredBox(
          color: headerBackground
              ? const Color(0xB2F9F5FA)
              : Colors.transparent,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                Container(width: 1, color: AppPalette.borderHairline),
                SizedBox(
                  width: ClassroomSchedulingShimmer._statusColumnWidth,
                  child: Center(child: right),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: AppPalette.borderHairline),
      ],
    );
  }
}

class _EntityCellPlaceholder extends StatelessWidget {
  const _EntityCellPlaceholder({required this.width, this.compact = false});

  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 32 : 38,
            height: compact ? 32 : 38,
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Container(
            height: compact ? 12 : 14,
            width: width * 0.7,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: width * 0.5,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePillPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Container(
        width: 88,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _TimelineBlocksPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          12,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching Classroom profile screen layout:
/// dropdown/header row, classroom details card, three summary cards, and events card.
class ClassroomProfileShimmer extends StatelessWidget {
  const ClassroomProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row: dropdown + icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ShimmerLoader(
                height: 44,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            ShimmerLoader(
              height: 28,
              width: 28,
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Classroom details (capacity) card
        Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromARGB(255, 232, 234, 234),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // age range
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.55,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // thumb icon placeholder
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const SummaryCardShimmer(),
        const SummaryCardShimmer(),
        const SummaryCardShimmer(),
        const SizedBox(height: 16),

        // Events card placeholder
        Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
          child: Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromARGB(255, 232, 234, 234),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer placeholder for MyChildsDayCard matching the card body layout.
/// Shows: timer row + student detail section + action rows.
class MyChildsDayCardShimmer extends StatelessWidget {
  const MyChildsDayCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Column(
        children: [
          // Status text
          Container(
            height: 17,
            width: 200,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Timer row (HH:MM:SS format)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // HH
              Column(
                children: [
                  Container(
                    height: 48,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Separator
              Text(
                ':',
                style: TextStyle(fontSize: 48, color: MaterialHues.grey300),
              ),
              const SizedBox(width: 8),
              // MM
              Column(
                children: [
                  Container(
                    height: 48,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Separator
              Text(
                ':',
                style: TextStyle(fontSize: 48, color: MaterialHues.grey300),
              ),
              const SizedBox(width: 8),
              // SS
              Column(
                children: [
                  Container(
                    height: 48,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reminder row
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Location row
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          // Student detail row
          Row(
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.whiteColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 130,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sign-in PIN row
          Container(
            height: 16,
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          // Button
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for a single Classroom Students list row, mirroring
/// [ClassroomStudentListItem]: bordered card with a checkbox box, circular
/// avatar, and a name line.
class _ClassroomStudentRowShimmer extends StatelessWidget {
  const _ClassroomStudentRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: MaterialHues.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkbox placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Avatar placeholder
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Name placeholder
          Expanded(
            child: Container(
              height: 16,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer list of [ClassroomStudentListItem] rows, shown on the Students tab's
/// first load instead of a spinner. The tab card renders the real search bar /
/// toggles above this, so this widget covers only the scrollable roster.
class ClassroomStudentsListShimmer extends StatelessWidget {
  const ClassroomStudentsListShimmer({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          rowCount,
          (i) => const _ClassroomStudentRowShimmer(),
        ),
      ),
    );
  }
}

/// Full Classroom Students tab shimmer: search bar + select-all row + filter
/// toggles + roster rows. Used on the very first landing (before any classroom
/// has loaded) so the whole tab body shows structure instead of "Loading...".
class ClassroomStudentsTabShimmer extends StatelessWidget {
  const ClassroomStudentsTabShimmer({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar + filter icon
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Select-all + chips row
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 15,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 22,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter toggles row
              Row(
                children: [
                  Container(
                    height: 18,
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    height: 18,
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(child: ClassroomStudentsListShimmer(rowCount: rowCount)),
      ],
    );
  }
}

/// Shimmer placeholder for a single Classroom Staff list row, mirroring
/// `_StaffListItem`: bordered card with a circular avatar, a name + designation
/// text column, and a trailing mail-icon button.
class _ClassroomStaffRowShimmer extends StatelessWidget {
  const _ClassroomStaffRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: MaterialHues.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name + designation placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 13,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Mail icon placeholder
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Shimmer list of `_StaffListItem` rows, shown on the Staff tab's first load
/// instead of a spinner. The tab card renders the real search bar / filter
/// chips above this; this covers only the scrollable roster (with the same
/// horizontal padding the real list uses).
class ClassroomStaffListShimmer extends StatelessWidget {
  const ClassroomStaffListShimmer({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          rowCount,
          (i) => const _ClassroomStaffRowShimmer(),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for StudentAttendanceCard matching the stats layout.
/// Shows: 3 stat rows (attended days, attended hours, absent days).
class StudentAttendanceCardShimmer extends StatelessWidget {
  const StudentAttendanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Column(
        children: [
          // Attended Days stat
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: MaterialHues.grey300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Attended Hours stat (with 2 circles)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: MaterialHues.grey300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.whiteColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.whiteColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Absent Days stat
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(color: MaterialHues.grey300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteColor,
                    shape: BoxShape.circle,
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

// ============================================================================
// Student Profile screen shimmers
//
// Skeleton placeholders for the tabs of the Student Profile screen, shown on
// first load in place of a centered spinner. Each mirrors the real content
// (cards, avatars, label/value rows) so the layout doesn't jump when data
// arrives. All share the [_SkelBox] / [_LabelValueRowShimmer] primitives.
// ============================================================================

/// Neutral grey placeholder box used to compose the student shimmers below.
class _SkelBox extends StatelessWidget {
  const _SkelBox({
    this.width,
    this.height = 14,
    this.radius = 4,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A single "Label .......... Value" row placeholder.
class _LabelValueRowShimmer extends StatelessWidget {
  const _LabelValueRowShimmer({this.labelWidth = 90, this.valueWidth = 120});

  final double labelWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SkelBox(width: labelWidth, height: 13),
        _SkelBox(width: valueWidth, height: 14),
      ],
    );
  }
}

/// A real card shell whose background/border do NOT shimmer — only [child]
/// (wrapped in a shimmer) animates. This is the key to the "dates tab" look:
/// the card stays a static empty card and just the text lines/avatars pulse,
/// instead of the whole rectangle pulsing as one solid box.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.borderColor = AppPalette.borderHairline,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Shimmer.fromColors(
        baseColor: MaterialHues.grey300,
        highlightColor: MaterialHues.grey100,
        child: child,
      ),
    );
  }
}

/// A standalone shimmering text line (for headers that sit outside a card).
class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: _SkelBox(width: width, height: 16),
    );
  }
}

/// Field-label widths cycled through so the skeleton rows don't all line up at
/// the same length (which reads as a block rather than text).
const List<double> _kLabelWidths = [64, 88, 72, 100, 56];

/// Field-value widths, longer than labels and varied for the same reason.
const List<double> _kValueWidths = [200, 150, 240, 180, 130];

/// Detail-card label widths resembling the real labels (Relation, Email ID,
/// Phone Number, Sign-in Pin, Type) so each row reads as text, not a slab.
const List<double> _kDetailLabelWidths = [58, 56, 96, 74, 48];

/// Matching value widths: relation short, email long, phone medium, pin short.
const List<double> _kDetailValueWidths = [70, 150, 110, 56, 132];

/// Shimmer for the Profile (About) tab — mirrors [ProfileInfoCard]: a static
/// white card (top radius 12 / bottom 16); only the title line and the stacked
/// label-over-value text lines shimmer (matching [ProfileField]'s column layout).
class StudentProfileInfoShimmer extends StatelessWidget {
  const StudentProfileInfoShimmer({super.key, this.rowCount = 8});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return _ShimmerCard(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
        bottom: Radius.circular(16),
      ),
      borderColor: const Color.fromARGB(255, 232, 234, 234),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Profile Information" title line.
          const _SkelBox(width: 150, height: 15),
          const SizedBox(height: 18),
          for (int i = 0; i < rowCount; i++) ...[
            // Label line over a longer value line.
            _SkelBox(
              width: _kLabelWidths[i % _kLabelWidths.length],
              height: 12,
            ),
            const SizedBox(height: 8),
            _SkelBox(
              width: _kValueWidths[i % _kValueWidths.length],
              height: 14,
            ),
            if (i != rowCount - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

/// Shimmer for the Health sub-tab — a static "Health" header line plus a static
/// card whose label/value text lines shimmer.
class StudentHealthCardShimmer extends StatelessWidget {
  const StudentHealthCardShimmer({super.key, this.rowCount = 4});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerLine(width: 72),
        const SizedBox(height: 16),
        _ShimmerCard(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rowCount; i++) ...[
                _LabelValueRowShimmer(
                  labelWidth:
                      _kDetailLabelWidths[i % _kDetailLabelWidths.length] + 20,
                  valueWidth: 60 + (i % 3) * 24,
                ),
                if (i != rowCount - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Shimmer for the Students list screen — a column of collapsed [StudentCard]
/// skeletons: a static 64px bordered card whose checkbox, circular avatar, and
/// name (left) / classroom (right) lines shimmer.
class StudentListShimmer extends StatelessWidget {
  const StudentListShimmer({super.key, this.rowCount = 8});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rowCount; i++) ...[
          const _StudentListCardShimmer(),
          if (i != rowCount - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StudentListCardShimmer extends StatelessWidget {
  const _StudentListCardShimmer();

  @override
  Widget build(BuildContext context) {
    return const _ShimmerCard(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            // Checkbox
            _SkelBox(width: 20, height: 20, radius: 4),
            SizedBox(width: 10),
            // Avatar
            _SkelBox(width: 44, height: 44, circle: true),
            SizedBox(width: 10),
            // Name (left) ... classroom (right)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkelBox(width: 130, height: 14),
                  _SkelBox(width: 80, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for the Family, Pickup and Physician tabs — a list of static cards,
/// each with an avatar + name header (shimmering), a divider, and label/value
/// text-line rows (shimmering). The card background and divider stay static.
class StudentDetailCardsShimmer extends StatelessWidget {
  const StudentDetailCardsShimmer({
    super.key,
    this.cardCount = 2,
    this.rowCount = 4,
  });

  final int cardCount;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < cardCount; i++) ...[
          _DetailCardShimmer(rowCount: rowCount),
          if (i != cardCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DetailCardShimmer extends StatelessWidget {
  const _DetailCardShimmer({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.borderHairline),
      ),
      child: Column(
        children: [
          // Avatar + name header — only these shimmer.
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Shimmer.fromColors(
                baseColor: MaterialHues.grey300,
                highlightColor: MaterialHues.grey100,
                child: Row(
                  children: const [
                    _SkelBox(width: 44, height: 44, circle: true),
                    SizedBox(width: 12),
                    _SkelBox(width: 140, height: 15),
                  ],
                ),
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: AppPalette.borderHairline,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: MaterialHues.grey300,
              highlightColor: MaterialHues.grey100,
              child: Column(
                children: [
                  for (int i = 0; i < rowCount; i++) ...[
                    _LabelValueRowShimmer(
                      labelWidth:
                          _kDetailLabelWidths[i % _kDetailLabelWidths.length],
                      valueWidth:
                          _kDetailValueWidths[i % _kDetailValueWidths.length],
                    ),
                    if (i != rowCount - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for the Physical Exams (Dates) tab — a static header line plus a list
/// of static cards whose status-chip + checkup-date text lines shimmer.
class StudentExamCardsShimmer extends StatelessWidget {
  const StudentExamCardsShimmer({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerLine(width: 130),
        const SizedBox(height: 16),
        for (int i = 0; i < cardCount; i++) ...[
          _ShimmerCard(
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Status chip
                _SkelBox(width: 90, height: 22, radius: 8),
                SizedBox(height: 18),
                // Checkup date label + value
                _LabelValueRowShimmer(labelWidth: 100, valueWidth: 110),
              ],
            ),
          ),
          if (i != cardCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Shimmer for the Immunization tab — static vaccine cards, each with a name
/// line and a few dose rows (label + status chip + date) that shimmer.
class StudentImmunizationShimmer extends StatelessWidget {
  const StudentImmunizationShimmer({
    super.key,
    this.cardCount = 3,
    this.dosesPerCard = 2,
  });

  final int cardCount;
  final int dosesPerCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < cardCount; i++) ...[
          _ShimmerCard(
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vaccine name
                const _SkelBox(width: 130, height: 15),
                for (int d = 0; d < dosesPerCard; d++) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _SkelBox(width: 56, height: 13), // Dose N
                      _SkelBox(width: 70, height: 22, radius: 8), // status chip
                      _SkelBox(width: 78, height: 13), // date
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (i != cardCount - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Shimmer for the Important Dates tab body — a list of label/value rows shown
/// inside the tab's existing bordered container.
class StudentImportantDatesShimmer extends StatelessWidget {
  const StudentImportantDatesShimmer({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Column(
        children: [
          for (int i = 0; i < rowCount; i++) ...[
            _LabelValueRowShimmer(
              labelWidth: 90 + (i % 3) * 20,
              valueWidth: 90 + (i % 4) * 20,
            ),
            if (i != rowCount - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// Shimmer for the Documents tab list — static collapsed document tiles whose
/// name + type-badge + chevron lines shimmer, shown below the real search header.
class StudentDocumentsListShimmer extends StatelessWidget {
  const StudentDocumentsListShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rowCount; i++) ...[
          _ShimmerCard(
            borderRadius: BorderRadius.circular(14),
            borderColor: const Color(0x33162831),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: const [
                // Document name
                _SkelBox(width: 150, height: 14),
                SizedBox(width: 10),
                // Document-type badge
                _SkelBox(width: 64, height: 15, radius: 6),
                Spacer(),
                // Expand chevron
                _SkelBox(width: 18, height: 18),
              ],
            ),
          ),
          if (i != rowCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ============================================================================
// Billing / General Ledger shimmers
// ============================================================================

/// Shimmer placeholder matching the collapsed [LedgerCard] layout:
/// white bordered card (minHeight 60) with a header name line.
class LedgerCardShimmer extends StatelessWidget {
  const LedgerCardShimmer({super.key, this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.borderHairline),
        ),
        child: Center(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// A column of [LedgerCardShimmer] rows used for the initial ledger list load.
class LedgerListShimmer extends StatelessWidget {
  const LedgerListShimmer({super.key, this.rowCount = 6});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rowCount, (_) => const LedgerCardShimmer()),
    );
  }
}

// ============================================================================
// Staff Profile screen shimmers
//
// Mirror the student shimmers: static card shells (background/border do not
// animate) with only the text lines shimmering. Reuse the same [_ShimmerCard] /
// [_SkelBox] / [_LabelValueRowShimmer] primitives.
// ============================================================================

/// Shimmer for the Staff Profile tab — a static card whose title line and
/// stacked label-over-value fields shimmer (matches the profile `_Field`
/// column layout: short label line, gap, longer value line).
class StaffProfileInfoShimmer extends StatelessWidget {
  const StaffProfileInfoShimmer({super.key, this.rowCount = 11});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return _ShimmerCard(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
        bottom: Radius.circular(16),
      ),
      borderColor: const Color.fromARGB(255, 232, 234, 234),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkelBox(width: 150, height: 15),
          const SizedBox(height: 18),
          for (int i = 0; i < rowCount; i++) ...[
            _SkelBox(
              width: _kLabelWidths[i % _kLabelWidths.length],
              height: 12,
            ),
            const SizedBox(height: 8),
            _SkelBox(
              width: _kValueWidths[i % _kValueWidths.length],
              height: 14,
            ),
            if (i != rowCount - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// Shimmer for the Staff Documents tab — static collapsed document tiles whose
/// name + type-badge + chevron lines shimmer.
class StaffDocumentsListShimmer extends StatelessWidget {
  const StaffDocumentsListShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rowCount; i++) ...[
          _ShimmerCard(
            borderRadius: BorderRadius.circular(14),
            borderColor: const Color(0x33162831),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: const [
                _SkelBox(width: 150, height: 14),
                SizedBox(width: 10),
                _SkelBox(width: 64, height: 15, radius: 6),
                Spacer(),
                _SkelBox(width: 18, height: 18),
              ],
            ),
          ),
          if (i != rowCount - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Shimmer for the Staff Important Dates tab — a list of static bordered cards,
/// each with a stacked label (date-type) line over a value (date) line.
class StaffImportantDatesShimmer extends StatelessWidget {
  const StaffImportantDatesShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  static const List<double> _labelWidths = [180, 150, 220, 160, 200];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rowCount; i++)
          Container(
            margin: EdgeInsets.only(top: i == 0 ? 16 : 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x33162831)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Shimmer.fromColors(
              baseColor: MaterialHues.grey300,
              highlightColor: MaterialHues.grey100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkelBox(
                    width: _labelWidths[i % _labelWidths.length],
                    height: 13,
                  ),
                  const SizedBox(height: 8),
                  const _SkelBox(width: 100, height: 14),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Parent Billing / Statements shimmers
// ============================================================================

/// Shimmer placeholder matching the collapsed [ParentTransactionCard] layout:
/// avatar circle, student name + transaction-type badge (left), amount + date (right).
class ParentTransactionCardShimmer extends StatelessWidget {
  const ParentTransactionCardShimmer({super.key, this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.borderHairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 22,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 14,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder matching the collapsed [ParentStatementCard] layout:
/// avatar circle, student name (left), statement-type badge (right).
class ParentStatementCardShimmer extends StatelessWidget {
  const ParentStatementCardShimmer({super.key, this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MaterialHues.grey300,
      highlightColor: MaterialHues.grey100,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.borderHairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 22,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for the Staff Dates tab body (below the static calendar header) —
/// stacked date rows plus a physical-checkup status card.
class StaffDatesShimmer extends StatelessWidget {
  const StaffDatesShimmer({super.key, this.rowCount = 4});

  final int rowCount;

  static const List<double> _labelWidths = [180, 150, 220, 200];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: MaterialHues.grey300,
          highlightColor: MaterialHues.grey100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < rowCount; i++) ...[
                _SkelBox(
                  width: _labelWidths[i % _labelWidths.length],
                  height: 13,
                ),
                const SizedBox(height: 8),
                const _SkelBox(width: 100, height: 14),
                if (i != rowCount - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Physical checkup status card.
        _ShimmerCard(
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkelBox(width: 90, height: 22, radius: 8),
              SizedBox(height: 18),
              _LabelValueRowShimmer(labelWidth: 100, valueWidth: 110),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Reports shimmers
// ============================================================================

/// Shimmer placeholder matching the collapsed [GeneratedReportCard] row:
/// white bordered card (height 64) with a filename line.
class GeneratedReportsListShimmer extends StatelessWidget {
  const GeneratedReportsListShimmer({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < rowCount; i++) ...[
          _ShimmerCard(
            borderRadius: BorderRadius.circular(12),
            borderColor: const Color(0x33162831),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const SizedBox(
              height: 64,
              child: Row(
                children: [
                  _SkelBox(width: 180, height: 14),
                ],
              ),
            ),
          ),
          if (i != rowCount - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
