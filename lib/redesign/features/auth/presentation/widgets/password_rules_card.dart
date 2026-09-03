import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';

/// 1f's strength bar and the three rules under it.
///
/// The bar and the ticks read the same booleans, so the bar can never be full
/// while a rule is still grey.
class PasswordRulesCard extends StatelessWidget {
  const PasswordRulesCard({
    required this.rules,
    required this.strength,
    super.key,
  });

  /// Whether each of [_labels] is met, in the same order.
  final List<bool> rules;

  /// How full the bar is, nought to one.
  final double strength;

  static const List<String> _labels = <String>[
    AuthStrings.ruleLength,
    AuthStrings.ruleNumberSymbol,
    AuthStrings.ruleMatch,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AuthSizes.rulesCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AuthSizes.rulesCardGap,
        children: <Widget>[
          Trough(
            fraction: strength,
            fill: c.success,
            height: AuthSizes.strengthBar,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuthSizes.ruleGap,
            children: <Widget>[
              for (final (index, label) in _labels.indexed)
                _Rule(label: label, met: rules[index], colours: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({
    required this.label,
    required this.met,
    required this.colours,
  });

  final String label;
  final bool met;
  final Colourway colours;

  @override
  Widget build(BuildContext context) {
    final ink = met ? colours.successFg : colours.ink3;

    return Semantics(
      checked: met,
      label: label,
      child: Row(
        spacing: AuthSizes.ruleGap,
        children: <Widget>[
          Icon(AppIcons.check, size: AuthSizes.ruleGlyph, color: ink),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.alertText.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
