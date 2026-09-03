import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';

/// The 22px ring radio from 1b: a 2px ring with a 10px dot inside once
/// selected, both in the student teal.
class RadioRing extends StatelessWidget {
  const RadioRing({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      width: AppSizes.radio,
      height: AppSizes.radio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.student : c.ink3,
          width: AppSizes.radioRing,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          width: AppSizes.radioDot,
          height: AppSizes.radioDot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? c.student : null,
          ),
        ),
      ),
    );
  }
}
