import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_media_res.dart';
import '../model/scheduling_models.dart';
import '../utils/scheduling_block_status_style.dart';

class SchedulingLegend extends StatelessWidget {
  const SchedulingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(asset: MediaRes.availableHoursIcon),
                label: 'Available',
              ),
            ),
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(asset: MediaRes.scheduledHoursIcon),
                label: 'Scheduled',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(asset: MediaRes.notPublishedIcon),
                label: 'Not Published',
              ),
            ),
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(asset: MediaRes.publishedIcon),
                label: 'Published',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                icon: SchedulingBlockStatusStyle.weekViewIcon(
                  SchedulingBlockStatusKind.underRatio,
                ),
                label: SchedulingBlockStatusStyle.weekViewLabel(
                  SchedulingBlockStatusKind.underRatio,
                ),
              ),
            ),
            Expanded(
              child: _LegendItem(
                icon: SchedulingBlockStatusStyle.weekViewIcon(
                  SchedulingBlockStatusKind.inRatio,
                ),
                label: SchedulingBlockStatusStyle.weekViewLabel(
                  SchedulingBlockStatusKind.inRatio,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, height: 18, child: Center(child: icon)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon({required this.asset, this.colorFilter});

  final String asset;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: 18,
      height: 18,
      colorFilter: colorFilter,
    );
  }
}

/// Week-view classroom column icon for forecast `blockStatus`.
class RatioStatusIcon extends StatelessWidget {
  const RatioStatusIcon.inRatio({super.key}) : status = ClassroomRatioStatus.inRatio;
  const RatioStatusIcon.underRatio({super.key})
      : status = ClassroomRatioStatus.underRatio;
  const RatioStatusIcon.overRatio({super.key})
      : status = ClassroomRatioStatus.overRatio;

  final ClassroomRatioStatus status;

  @override
  Widget build(BuildContext context) {
    return SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(status);
  }
}
