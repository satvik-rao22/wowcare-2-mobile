import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';

/// The coloured gradient banner shown at the top of every assessment profile /
/// dashboard (student, classroom, school). Replaces the old flat white header
/// and is the module's hero surface: a per-entity gradient, a ringed avatar
/// (with optional [heroTag] for a shared-element flight from the list card),
/// title/subtitle in white, the overall average, and an optional month picker.
class AssessmentGradientHeader extends StatelessWidget {
  const AssessmentGradientHeader({
    super.key,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.overall,
    this.icon,
    this.initials = '',
    this.seed = '',
    this.avatarUrl,
    this.heroTag,
    this.monthPicker,
  });

  final Gradient gradient;
  final String title;
  final String subtitle;

  /// Overall average out of 5 (rendered in white on the right). Null hides it.
  final double? overall;

  /// Entity icon (classroom / school). When null, [initials] are shown.
  final IconData? icon;
  final String initials;
  final String seed;
  final String? avatarUrl;
  final String? heroTag;
  final Widget? monthPicker;

  Color get _shadowColor =>
      gradient.colors.isNotEmpty ? gradient.colors.last : const Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final wide = width >= AssessmentUi.tabletMax;
        final pad = AssessmentUi.cardPadding(width);
        final avatarRadius = AssessmentUi.avatarRadius(width, base: 26);

        Widget avatar = InitialsAvatar(
          seed: seed,
          initials: initials,
          icon: icon,
          imageUrl: avatarUrl,
          gradient: avatarUrl == null ? gradient : null,
          radius: avatarRadius,
        );
        if (heroTag != null) {
          avatar = Hero(tag: heroTag!, child: avatar);
        }

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _shadowColor.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // White ring lifts the avatar off the same-hue banner.
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: avatar,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: wide ? 24 : 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: wide ? 14.5 : 12.5,
                                color: Colors.white70)),
                      ],
                    ),
                  ),
                  if (overall != null || icon != null)
                    _OverallAverage(overall: overall, wide: wide),
                ],
              ),
              if (monthPicker != null) ...[
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: monthPicker!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OverallAverage extends StatelessWidget {
  const _OverallAverage({required this.overall, this.wide = false});

  final double? overall;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final numberSize = wide ? 38.0 : 28.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (overall == null)
          Text('—',
              style: TextStyle(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white))
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: overall!),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: numberSize,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        const Text('avg / 5',
            style: TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
