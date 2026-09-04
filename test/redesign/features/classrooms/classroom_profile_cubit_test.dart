import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_profile_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

ClassroomProfileCubit build({
  ClassroomsSource source = const PreviewClassroomsSource(),
  Persona persona = Persona.admin,
}) => ClassroomProfileCubit(
  source: source,
  classroomId: PreviewClassroomsSource.sunflowerId,
  persona: persona,
);

void main() {
  group('ClassroomProfileCubit', () {
    test('loads the record, its day and the school around it', () async {
      final cubit = build();
      expect(cubit.state.status, ClassroomProfileStatus.loading);

      await cubit.load();

      final profile = cubit.state.profile!;
      expect(cubit.state.status, ClassroomProfileStatus.ready);
      expect(profile.summary.name, 'Sunflower');
      expect(profile.students.expected, 23);
      expect(profile.students.signedIn, 14);
      expect(profile.staff.expected, 4);
      expect(profile.center.classroomCount, 5);
      expect(profile.center.totalPlaces, 96);
      expect(profile.movements.length, 3);
      expect(profile.arrivingCount, 2);
      expect(profile.leavingCount, 1);
      await cubit.close();
    });

    test('the photo well starts empty', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.upload, PhotoUploadStatus.idle);
      await cubit.close();
    });

    test('an upload runs and lands on file', () async {
      final cubit = build();
      await cubit.load();

      final pending = cubit.uploadPhoto('sunflower-corner.jpg');
      expect(cubit.state.upload, PhotoUploadStatus.uploading);
      await pending;

      expect(cubit.state.upload, PhotoUploadStatus.done);
      expect(cubit.state.profile!.photo!.fileName, 'sunflower-corner.jpg');
      await cubit.close();
    });

    test('a failed upload loses nothing, and a retry sends it again', () async {
      final cubit = build(source: const _FlakyUploadSource());
      await cubit.load();

      await cubit.uploadPhoto('sunflower-corner.jpg');
      expect(cubit.state.upload, PhotoUploadStatus.failed);
      expect(cubit.state.profile, isNotNull);
      expect(cubit.state.pendingFileName, 'sunflower-corner.jpg');

      await cubit.retryUpload();
      expect(cubit.state.upload, PhotoUploadStatus.done);
      await cubit.close();
    });

    test('removing takes the photo off the record', () async {
      final cubit = build();
      await cubit.load();
      await cubit.uploadPhoto('sunflower-corner.jpg');

      await cubit.removePhoto();

      expect(cubit.state.upload, PhotoUploadStatus.idle);
      expect(cubit.state.profile!.photo, isNull);
      await cubit.close();
    });

    test('a role that may only look cannot upload', () async {
      final cubit = build(persona: Persona.staff);
      await cubit.load();

      await cubit.uploadPhoto('sunflower-corner.jpg');

      expect(cubit.state.canEdit, isFalse);
      expect(cubit.state.upload, PhotoUploadStatus.idle);
      await cubit.close();
    });

    test('nothing reachable fails outright', () async {
      final cubit = build(source: const FailingClassroomsSource());
      await cubit.load();

      expect(cubit.state.status, ClassroomProfileStatus.failed);
      await cubit.close();
    });
  });
}

/// Fails the first upload and takes the second, which is what a retry meets.
class _FlakyUploadSource extends PreviewClassroomsSource {
  const _FlakyUploadSource();

  static int _calls = 0;

  @override
  Future<ClassroomPhoto> uploadPhoto({
    required String classroomId,
    required String fileName,
  }) async {
    _calls += 1;
    if (_calls == 1) throw Exception('upload failed');
    return super.uploadPhoto(classroomId: classroomId, fileName: fileName);
  }
}
