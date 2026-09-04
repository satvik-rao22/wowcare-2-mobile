import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// What the banner is saying (6e's three states).
enum StaffBannerTone {
  /// View only. Nothing is wrong; there is simply nothing to change.
  quiet,

  /// No access to Staff at this school.
  denied,

  /// The team as it was, because there is no signal.
  offline,
}

/// The strip across the top of 6e: a dot, then one sentence.
///
/// Not the core `OfflineBanner`, which is the navy slab a whole screen wears.
/// This is quieter and takes three tones, because two of the three states it
/// carries are not about the network at all.
class StaffBanner extends StatelessWidget {
  const StaffBanner({required this.message, required this.tone, super.key});

  final String message;
  final StaffBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      margin: StaffSizes.bannerMargin,
      padding: StaffSizes.bannerPad,
      decoration: BoxDecoration(
        color: _fill(c),
        borderRadius: AppRadii.innerR,
        border: Border.all(color: _line(c)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: StaffSizes.bannerGap,
        children: <Widget>[
          Container(
            width: StaffSizes.bannerDot,
            height: StaffSizes.bannerDot,
            margin: const EdgeInsets.only(top: StaffSizes.bannerDot / 2),
            decoration: BoxDecoration(
              color: _dot(c),
              borderRadius: AppRadii.pillR,
            ),
          ),
          Expanded(
            child: Text(
              message,
              style: StaffTextStyles.banner.copyWith(color: _ink(c)),
            ),
          ),
        ],
      ),
    );
  }

  Color _fill(Colourway c) => switch (tone) {
    StaffBannerTone.quiet => c.neutralBg,
    StaffBannerTone.denied => c.dangerBg,
    StaffBannerTone.offline => c.staffBg,
  };

  Color _line(Colourway c) => switch (tone) {
    StaffBannerTone.quiet => c.cardBorder,
    StaffBannerTone.denied => c.dangerLine,
    StaffBannerTone.offline => c.staffLine,
  };

  Color _dot(Colourway c) => switch (tone) {
    StaffBannerTone.quiet => c.ink3,
    StaffBannerTone.denied => c.danger,
    StaffBannerTone.offline => c.staff,
  };

  Color _ink(Colourway c) => switch (tone) {
    StaffBannerTone.quiet => c.ink2,
    StaffBannerTone.denied => c.dangerFg,
    StaffBannerTone.offline => c.staffFg,
  };
}
