import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

part 'profile_state.dart';

/// 13a, 13c and 13f. The signed-in person's own record.
///
/// One cubit for all three frames: the persona chooses the lens (a guardian
/// gets 13c's children card and no work schedule) and the fetch chooses the
/// state (13f's loaded, loading, load failed and offline over cache).
///
/// The photo is a second, independent piece of work. It has its own status so
/// an upload that fails leaves the record on screen untouched, which is what
/// 13a's failed card promises.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileSource source,
    required String userId,
    required Persona persona,
  }) : _source = source,
       super(ProfileState(userId: userId, persona: persona));

  final ProfileSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: ProfileStatus.loading));

    try {
      final snapshot = await _source.fetchProfile(state.userId);
      final build = await _source.buildInfo();
      if (isClosed) return;

      emit(
        state.copyWith(
          status: snapshot.isFromCache
              ? ProfileStatus.offline
              : ProfileStatus.ready,
          record: snapshot.record,
          cachedAtLabel: snapshot.cachedAtLabel,
          clearCachedAt: snapshot.cachedAtLabel == null,
          build: build,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: ProfileStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// The Show / Hide key on the Sign-In PIN row.
  void togglePin() => emit(state.copyWith(isPinVisible: !state.isPinVisible));

  /// Sends a new photo and follows it up the wire. Progress drives the ring
  /// around the avatar and the percentage beside "Uploading".
  Future<void> uploadPhoto() async {
    if (state.photo == PhotoStatus.uploading) return;
    emit(state.copyWith(photo: PhotoStatus.uploading, photoProgress: 0));

    try {
      await for (final progress in _source.uploadPhoto(state.userId)) {
        if (isClosed) return;
        emit(state.copyWith(photoProgress: progress));
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          photo: PhotoStatus.idle,
          photoProgress: 0,
          record: state.record?.copyWith(hasPhoto: true),
          hasPhotoChanged: true,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(photo: PhotoStatus.failed));
    }
  }

  Future<void> removePhoto() async {
    try {
      await _source.removePhoto(state.userId);
      if (isClosed) return;
      emit(
        state.copyWith(
          photo: PhotoStatus.idle,
          record: state.record?.copyWith(hasPhoto: false),
          hasPhotoRemoved: true,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(photo: PhotoStatus.failed));
    }
  }

  /// The screen has toasted the photo result, so the next one starts clean.
  void clearPhotoNotice() =>
      emit(state.copyWith(hasPhotoChanged: false, hasPhotoRemoved: false));

  /// Try again, under 13a's failed photo card.
  void clearPhotoFailure() => emit(state.copyWith(photo: PhotoStatus.idle));
}
