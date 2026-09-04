import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// One label and its value on a record.
@immutable
class StaffFact {
  const StaffFact(this.label, this.value, {this.tone = StaffFactTone.plain});

  final String label;
  final String value;
  final StaffFactTone tone;
}

/// What a value's colour is saying. Plain is the answer to the question; the
/// rest are the three things a date or a status can be.
enum StaffFactTone { plain, quiet, good, bad }

/// The label-and-value card 6c's Profile and Dates tabs are both made of,
/// with an optional heading and one small key beside it.
class FactCard extends StatelessWidget {
  const FactCard({
    required this.facts,
    this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a handler.',
       );

  final List<StaffFact> facts;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StaffSizes.cardRowGap,
        children: <Widget>[
          if (title != null || onAction != null)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title ?? '',
                    style: StaffTextStyles.cardHeading.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onAction != null)
                  _SmallKey(label: actionLabel!, onTap: onAction!),
              ],
            ),
          for (final fact in facts) _FactRow(fact: fact),
        ],
      ),
    );
  }
}

/// The quiet key beside a card's heading: 6c's Edit.
class _SmallKey extends StatelessWidget {
  const _SmallKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.chip(c),
          padding: StaffSizes.smallKeyPad,
          child: Text(
            label,
            style: StaffTextStyles.smallKey.copyWith(color: c.ink),
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final StaffFact fact;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = switch (fact.tone) {
      StaffFactTone.plain => c.ink,
      StaffFactTone.quiet => c.ink2,
      StaffFactTone.good => c.successFg,
      StaffFactTone.bad => c.dangerFg,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: StaffSizes.fieldRowGap,
      children: <Widget>[
        SizedBox(
          width: StaffSizes.profileLabelWidth,
          child: Text(
            fact.label,
            style: StaffTextStyles.factLabel.copyWith(color: c.ink3),
          ),
        ),
        Expanded(
          child: Text(
            fact.value,
            style: StaffTextStyles.dateValue.copyWith(color: ink),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
