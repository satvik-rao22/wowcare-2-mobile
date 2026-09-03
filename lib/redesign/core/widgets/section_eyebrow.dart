import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// An uppercase, tracked section label (5a "Sunflower · 18", 3A1 "Needs your
/// attention").
///
/// Colour carries meaning here: teal over a student group, sun over staff,
/// danger red over what needs attention, ink3 over anything neutral. [meta]
/// is the count or note that sits beside it in ink3.
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow({
    required this.label,
    this.color,
    this.meta,
    this.metaColor,
    this.trailing,
    super.key,
  });

  final String label;

  /// Defaults to ink3.
  final Color? color;

  final String? meta;
  final Color? metaColor;

  /// Something on the far right: a counter, a link.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.eyebrowInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: AppSizes.eyebrowMetaGap,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: color ?? c.ink3),
          ),
          if (meta != null)
            Expanded(
              child: Text(
                meta!,
                style: AppTextStyles.eyebrowMeta.copyWith(
                  color: metaColor ?? c.ink3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
