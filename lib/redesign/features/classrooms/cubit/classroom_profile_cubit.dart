import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';

part 'classroom_profile_state.dart';

/// The classroom's own record (7f), reached by tapping the header card.
///
/// The photo well is a small state machine of its own: choose, uploading,
/// on file, failed. A failed upload never loses what was already on file,
/// which is what the frame's copy promises.
class ClassroomProfileCubit extends Cubit<ClassroomProfileState> {
  ClassroomProfileCubit({
    required ClassroomsSource source,
    required String classroomId,
    required Persona persona,
  }) : _source = source,
       super(ClassroomProfileState(classroomId: classroomId, persona: persona));

  final ClassroomsSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) {
      emit(state.copyWith(status: ClassroomProfileStatus.loading));
    }

    try {
      final profile = await _source.loadProfile(state.classroomId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ClassroomProfileStatus.ready,
          profile: profile,
          upload: profile.photo == null
              ? PhotoUploadStatus.idle
              : PhotoUploadStatus.done,
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.profile == null
              ? ClassroomProfileStatus.failed
              : ClassroomProfileStatus.cached,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// Put a photo on the record. The percentage is the design's own: a real
  /// upload reports progress and this stands in for it.
  Future<void> uploadPhoto(String fileName) async {
    final profile = state.profile;
    if (profile == null || !state.canEdit) return;

    emit(
      state.copyWith(
        upload: PhotoUploadStatus.uploading,
        pendingFileName: fileName,
      ),
    );

    try {
      final photo = await _source.uploadPhoto(
        classroomId: state.classroomId,
        fileName: fileName,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          upload: PhotoUploadStatus.done,
          profile: profile.copyWith(photo: photo),
        ),
      );
    } on Exception catch (_) {
      // Nothing was lost: whatever was on file is still on file.
      if (!isClosed) emit(state.copyWith(upload: PhotoUploadStatus.failed));
    }
  }

  Future<void> retryUpload() async {
    final fileName = state.pendingFileName;
    if (fileName == null) return;
    await uploadPhoto(fileName);
  }

  Future<void> removePhoto() async {
    final profile = state.profile;
    if (profile == null || !state.canEdit) return;

    try {
      await _source.removePhoto(state.classroomId);
      if (isClosed) return;
      emit(
        state.copyWith(
          upload: PhotoUploadStatus.idle,
          profile: profile.copyWith(clearPhoto: true),
          clearPendingFileName: true,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(upload: PhotoUploadStatus.failed));
    }
  }
}
