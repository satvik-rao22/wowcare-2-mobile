import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

import 'profile_test_doubles.dart';

void main() {
  late FakeProfileSource source;

  ProfileCubit build({Persona persona = Persona.admin, String id = 'marcus'}) =>
      ProfileCubit(source: source, userId: id, persona: persona);

  setUp(() => source = FakeProfileSource());

  group('ProfileCubit', () {
    test('13a: the record, the roles and the build all arrive', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.record?.fullName, 'Marcus Whitfield');
      expect(cubit.state.record?.roleLabels, <String>['Admin', 'Parent']);
      expect(cubit.state.build?.version, '2.4.1');
      expect(cubit.state.hasBody, isTrue);
      await cubit.close();
    });

    test('13f: a cached answer is the offline state, with its time', () async {
      source.snapshot = ProfileSnapshot(
        record: FakeProfileSource.staffRecord,
        isFromCache: true,
        cachedAtLabel: '9:02 AM',
      );
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.offline);
      expect(cubit.state.isOffline, isTrue);
      expect(cubit.state.cachedAtLabel, '9:02 AM');
      // Offline still has a record to draw, which is the point of the state.
      expect(cubit.state.hasBody, isTrue);
      await cubit.close();
    });

    test('13f: nothing to show at all is the failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.failed);
      expect(cubit.state.hasBody, isFalse);
      await cubit.close();
    });

    test('the re-entrancy guard stops a second load overlapping', () async {
      final cubit = build();
      final first = cubit.load();
      final second = cubit.load();
      await Future.wait(<Future<void>>[first, second]);

      expect(source.fetchCalls, 1);
      await cubit.close();
    });

    test('the PIN is masked until it is asked for', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.pinLabel, ProfileStrings.pinMask);
      cubit.togglePin();
      expect(cubit.state.pinLabel, '4821');
      cubit.togglePin();
      expect(cubit.state.pinLabel, ProfileStrings.pinMask);
      await cubit.close();
    });

    test('13a: the Admin lens may edit the schedule, Staff may not', () async {
      final admin = build();
      await admin.load();
      expect(admin.state.canEditSchedule, isTrue);
      expect(admin.state.workSchedule, isNotNull);
      await admin.close();

      final staff = build(persona: Persona.staff);
      await staff.load();
      expect(staff.state.canEditSchedule, isFalse);
      expect(staff.state.workSchedule, isNotNull);
      await staff.close();
    });

    test('13c: a guardian gets children and no work schedule', () async {
      source.snapshot = const ProfileSnapshot(
        record: FakeProfileSource.guardianRecord,
      );
      final cubit = build(persona: Persona.guardian, id: 'ngozi');
      await cubit.load();

      expect(cubit.state.isGuardianLens, isTrue);
      expect(cubit.state.workSchedule, isNull);
      expect(cubit.state.children.length, 2);
      expect(cubit.state.children.first.name, 'Amara Okafor');
      await cubit.close();
    });

    test('13a: an upload reports progress and lands', () async {
      final cubit = build();
      await cubit.load();
      await cubit.uploadPhoto();

      expect(cubit.state.photo, PhotoStatus.idle);
      expect(cubit.state.record?.hasPhoto, isTrue);
      expect(cubit.state.hasPhotoChanged, isTrue);

      cubit.clearPhotoNotice();
      expect(cubit.state.hasPhotoChanged, isFalse);
      await cubit.close();
    });

    test(
      '13a: a failed upload leaves the record alone and offers a retry',
      () async {
        source.uploadFails = true;
        final cubit = build();
        await cubit.load();
        await cubit.uploadPhoto();

        expect(cubit.state.photo, PhotoStatus.failed);
        // The record itself is untouched, which is what the card promises.
        expect(cubit.state.status, ProfileStatus.ready);
        expect(cubit.state.record, FakeProfileSource.staffRecord);

        cubit.clearPhotoFailure();
        expect(cubit.state.photo, PhotoStatus.idle);
        await cubit.close();
      },
    );

    test('removing the photo takes it off the record', () async {
      final cubit = build();
      await cubit.load();
      await cubit.removePhoto();

      expect(source.removedPhotoFor, 'marcus');
      expect(cubit.state.record?.hasPhoto, isFalse);
      expect(cubit.state.hasPhotoRemoved, isTrue);
      await cubit.close();
    });
  });
}
