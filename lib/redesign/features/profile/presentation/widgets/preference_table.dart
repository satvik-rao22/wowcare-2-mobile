import 'package:flutter/widgets.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/preference_group_row.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// 13e's grid: a header naming the three channels, then a coloured band per
/// category with its groups under it.
///
/// One table rather than a card per category: the columns have to line up
/// down the whole screen or the ticks stop being comparable.
class PreferenceTable extends StatelessWidget {
  const PreferenceTable({
    required this.categories,
    required this.isSaving,
    required this.onToggle,
    super.key,
  });

  final List<PreferenceCategory> categories;

  /// Whether a PATCH is in flight for that group.
  final bool Function(String groupCode) isSaving;

  final void Function(String groupCode, String channel) onToggle;

  /// The columns, left to right, and the channel code each one writes.
  static const List<String> channels = <String>[
    NotificationChannel.inApp,
    NotificationChannel.email,
    NotificationChannel.push,
  ];

  static const List<String> _headings = <String>[
    ProfileStrings.inApp,
    ProfileStrings.emailChannel,
    ProfileStrings.push,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Header(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.cardBorder),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.inner),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.inner),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final category in categories) ...<Widget>[
                  _Band(name: category.name, code: category.code),
                  for (final group in category.groups)
                    PreferenceGroupRow(
                      title: group.title,
                      description: group.description,
                      channels: <bool?>[
                        for (final channel in channels)
                          group.isChannelAvailable(channel)
                              ? group.isChannelEnabled(channel)
                              : null,
                      ],
                      isSaving: isSaving(group.groupCode),
                      onToggle: (column) =>
                          onToggle(group.groupCode, channels[column]),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "What happens", then the three channel columns.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: ProfileSizes.prefHeaderPad,
      decoration: BoxDecoration(
        color: c.altWell,
        border: Border.all(color: c.cardBorder),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.inner),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              ProfileStrings.whatHappens.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: c.ink2),
            ),
          ),
          for (final heading in PreferenceTable._headings)
            SizedBox(
              width: ProfileSizes.prefColumn,
              child: Text(
                heading,
                textAlign: TextAlign.center,
                style: ProfileTextStyles.prefColumn.copyWith(color: c.ink),
              ),
            ),
        ],
      ),
    );
  }
}

/// A category band. Colour is about what the notifications are about, never
/// about who is looking: teal for students, sun for staff, navy for the
/// center as a whole.
class _Band extends StatelessWidget {
  const _Band({required this.name, required this.code});

  final String name;
  final String code;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final (Color fill, Color ink) = switch (code) {
      _students => (c.studentBg, c.student),
      _staff => (c.staffBg, c.staffFg),
      _ => (c.altWell, c.ink),
    };

    return Container(
      padding: ProfileSizes.prefBandPad,
      decoration: BoxDecoration(
        color: fill,
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: Text(
        name.toUpperCase(),
        style: ProfileTextStyles.prefCategory.copyWith(color: ink),
      ),
    );
  }

  static const String _students = 'STUDENTS';
  static const String _staff = 'STAFF';
}
