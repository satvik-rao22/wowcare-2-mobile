import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';

/// One coloured band of 13e's table and the groups under it.
///
/// The API returns a flat list carrying `categoryCode` / `categoryName` on
/// every group; the screen draws them banded, so this is that grouping done
/// once in the state rather than in the widget tree.
@immutable
class PreferenceCategory extends Equatable {
  const PreferenceCategory({
    required this.code,
    required this.name,
    required this.groups,
  });

  final String code;

  /// Students, Staff, Center: the band's label, drawn uppercase.
  final String name;

  final List<NotificationPreferenceGroup> groups;

  /// Bands the groups by category, keeping the order the groups arrive in
  /// (the source sorts them by `displayOrder`).
  static List<PreferenceCategory> of(List<NotificationPreferenceGroup> groups) {
    final order = <String>[];
    final byCode = <String, List<NotificationPreferenceGroup>>{};

    for (final group in groups) {
      final code = group.categoryCode;
      if (!byCode.containsKey(code)) {
        order.add(code);
        byCode[code] = <NotificationPreferenceGroup>[];
      }
      byCode[code]!.add(group);
    }

    return <PreferenceCategory>[
      for (final code in order)
        PreferenceCategory(
          code: code,
          name: byCode[code]!.first.categoryName,
          groups: List<NotificationPreferenceGroup>.unmodifiable(byCode[code]!),
        ),
    ];
  }

  @override
  List<Object?> get props => <Object?>[code, name, groups];
}
