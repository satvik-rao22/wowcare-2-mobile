import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';

class SchedulingLegend extends StatelessWidget {
  const SchedulingLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        SizedBox(height: 8),
        Row(
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
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(
                  asset: MediaRes.alertTriangleIcon,
                  colorFilter: ColorFilter.mode(
                    AppColors.errorColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Under Ratio',
              ),
            ),
            Expanded(
              child: _LegendItem(
                icon: _SvgIcon(asset: MediaRes.greenCheckCircleIcon),
                label: 'In Ratio',
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
              fontFamily: 'Manrope',
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

/// Reused by classroom rows / sections to show the ratio status icon.
class RatioStatusIcon extends StatelessWidget {
  const RatioStatusIcon.inRatio({super.key}) : _isInRatio = true;
  const RatioStatusIcon.underRatio({super.key}) : _isInRatio = false;

  final bool _isInRatio;

  @override
  Widget build(BuildContext context) {
    if (_isInRatio) {
      return SvgPicture.asset(
        MediaRes.greenCheckCircleIcon,
        width: 18,
        height: 18,
      );
    }
    return SvgPicture.asset(
      MediaRes.alertTriangleIcon,
      width: 18,
      height: 18,
      colorFilter:
          const ColorFilter.mode(AppColors.errorColor, BlendMode.srcIn),
    );
  }
}
