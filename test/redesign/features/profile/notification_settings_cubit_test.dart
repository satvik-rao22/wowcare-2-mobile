import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/features/profile/cubit/notification_settings_cubit.dart';

import 'profile_test_doubles.dart';

void main() {
  late FakeProfileSource source;

  NotificationSettingsCubit build() =>
      NotificationSettingsCubit(source: source, userId: 'marcus');

  NotificationPreferenceGroup groupIn(
    NotificationSettingsCubit cubit,
    String code,
  ) => cubit.state.groups.firstWhere((g) => g.groupCode == code);

  setUp(() => source = FakeProfileSource());

  group('NotificationSettingsCubit', () {
    test('13e: the groups arrive banded by category, in order', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, NotificationSettingsStatus.ready);
      expect(cubit.state.categories.length, 2);
      expect(cubit.state.categories.first.name, 'Students');
      expect(cubit.state.categories.first.groups.length, 2);
      expect(cubit.state.categories.last.name, 'Staff');
      await cubit.close();
    });

    test('a school with no groups is ready and empty, not failed', () async {
      source.preferences = const <NotificationPreferenceGroup>[];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, NotificationSettingsStatus.ready);
      expect(cubit.state.isEmpty, isTrue);
      await cubit.close();
    });

    test('a failed fetch is a failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.isFailed, isTrue);
      await cubit.close();
    });

    test('a tick flips the channel and PATCHes that one group', () async {
      final cubit = build();
      await cubit.load();
      await cubit.toggleChannel('g1', NotificationChannel.email);

      expect(
        groupIn(cubit, 'g1').isChannelEnabled(NotificationChannel.email),
        isFalse,
      );
      expect(source.updated?.groupCode, 'g1');
      // The whole channel map goes back, not just the one that changed.
      expect(source.updated?.channels.length, 3);
      expect(cubit.state.isSaving('g1'), isFalse);
      await cubit.close();
    });

    test('a failed save puts the tick back and says so', () async {
      source.throwsOnWrite = true;
      final cubit = build();
      await cubit.load();
      await cubit.toggleChannel('g1', NotificationChannel.push);

      expect(
        groupIn(cubit, 'g1').isChannelEnabled(NotificationChannel.push),
        isTrue,
      );
      expect(cubit.state.hasSaveFailed, isTrue);
      expect(cubit.state.isSaving('g1'), isFalse);

      cubit.clearFailure();
      expect(cubit.state.hasSaveFailed, isFalse);
      await cubit.close();
    });

    test('a channel a group does not offer cannot be ticked', () async {
      final cubit = build();
      await cubit.load();
      await cubit.toggleChannel('g2', NotificationChannel.email);

      expect(
        groupIn(cubit, 'g2').isChannelAvailable(NotificationChannel.email),
        isFalse,
      );
      expect(source.updated, isNull);
      await cubit.close();
    });

    test('a second tap cannot race the first', () async {
      final cubit = build();
      await cubit.load();
      final first = cubit.toggleChannel('g1', NotificationChannel.push);
      final second = cubit.toggleChannel('g1', NotificationChannel.push);
      await Future.wait(<Future<void>>[first, second]);

      // One flip, not two: the second was refused while the first was live.
      expect(
        groupIn(cubit, 'g1').isChannelEnabled(NotificationChannel.push),
        isFalse,
      );
      await cubit.close();
    });
  });
}
