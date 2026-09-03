import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';

/// A bare text action: "View all", "Clear all", "Forgot password?".
///
/// Pink by default, because it is an action. It sinks as a surface and pads
/// itself a little so the target is wider than the glyphs.
class TextLink extends StatelessWidget {
  const TextLink({
    required this.label,
    this.onTap,
    this.color,
    this.style = AppTextStyles.sectionLink,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    link: true,
    label: label,
    child: Pressable.surface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space1),
        child: Text(
          label,
          style: style.copyWith(color: color ?? context.colours.pink),
        ),
      ),
    ),
  );
}
