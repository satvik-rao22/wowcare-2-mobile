import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// One group of 13e's table: what happens, the line describing it, and one
/// cell per channel.
///
/// The description is the part the shipped app throws away. The endpoint has
/// always returned it; this is the first screen to draw it.
class PreferenceGroupRow extends StatelessWidget {
  const PreferenceGroupRow({
    required this.title,
    required this.description,
    required this.channels,
    required this.isSaving,
    required this.onToggle,
    super.key,
  });

  final String title;
  final String description;

  /// One entry per column, in the order the header names them. A null value
  /// is a channel this group does not offer.
  final List<bool?> channels;

  /// A PATCH is in flight for this group: the row dims and stops responding.
  final bool isSaving;

  final void Function(int column) onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Opacity(
      opacity: isSaving ? ProfileSizes.savingOpacity : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Padding(
          padding: ProfileSizes.prefRowPad,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ProfileSizes.prefRowTextGap,
                  children: <Widget>[
                    Text(
                      title,
                      style: ProfileTextStyles.prefTitle.copyWith(color: c.ink),
                    ),
                    Text(
                      description,
                      style: ProfileTextStyles.prefDescription.copyWith(
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < channels.length; i++)
                SizedBox(
                  width: ProfileSizes.prefColumn,
                  child: _Cell(
                    value: channels[i],
                    label: title,
                    onTap: isSaving ? null : () => onToggle(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One channel of one group. A null [value] is the greige box: the channel is
/// not offered here at all, which is a different thing from switched off.
class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label, this.onTap});

  final bool? value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    if (value == null) {
      return Center(
        child: Container(
          width: ProfileSizes.notOfferedBox,
          height: ProfileSizes.notOfferedBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.deepWell,
            borderRadius: AppRadii.checkR,
            border: Border.all(color: c.cardBorder),
          ),
          child: Text(
            ProfileStrings.notOfferedMark,
            style: ProfileTextStyles.notOfferedMark.copyWith(color: c.ink3),
          ),
        ),
      );
    }

    return Semantics(
      checked: value,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: Center(child: AppCheckbox(checked: value!)),
      ),
    );
  }
}
