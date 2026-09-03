import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';

/// A card's own heading with an optional "View all" on the right (3A1
/// "Today's school status").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.onAction,
    this.actionLabel = AppStrings.viewAll,
    this.actionColor,
    this.trailing,
    super.key,
  });

  final String title;

  /// Shows the link when set.
  final VoidCallback? onAction;
  final String actionLabel;

  /// Defaults to pink, the action colour.
  final Color? actionColor;

  /// Something other than a link on the right: a pill, a chevron.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(color: c.ink),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onAction != null)
          TextLink(label: actionLabel, onTap: onAction, color: actionColor),
        ?trailing,
      ],
    );
  }
}
