import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';

/// A screen or card still fetching: the 24px ring, centred, with an optional
/// line under it.
class LoadingState extends StatelessWidget {
  const LoadingState({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSizes.emptyGap,
      children: <Widget>[
        const LoadingRing(size: AppSizes.ringLarge),
        if (label != null)
          Text(
            label!,
            style: AppTextStyles.subLine.copyWith(color: context.colours.ink3),
          ),
      ],
    ),
  );
}
