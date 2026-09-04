import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

part 'notification_settings_state.dart';

/// 13e. Ten groups, three channels, and no Save key.
///
/// A tick flips the channel at once, dims that one row while the PATCH is in
/// flight and puts the tick back if it fails, which is the behaviour the
/// frame's own note describes. A channel a group does not offer is not a
/// switched-off tick: it is a greige box that cannot be tapped at all.
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required ProfileSource source,
    required String userId,
  }) : _source = source,
       super(NotificationSettingsState(userId: userId));

  final ProfileSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) {
      emit(state.copyWith(status: NotificationSettingsStatus.loading));
    }

    try {
      final groups = await _source.fetchPreferences(state.userId);
      if (isClosed) return;
      final sorted = List<NotificationPreferenceGroup>.of(groups)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      emit(
        state.copyWith(
          status: NotificationSettingsStatus.ready,
          groups: sorted,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) {
        emit(state.copyWith(status: NotificationSettingsStatus.failed));
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// Flips [channel] on [groupCode]. Does nothing when the group does not
  /// offer that channel, or while a save for the same group is in flight.
  Future<void> toggleChannel(String groupCode, String channel) async {
    final index = state.groups.indexWhere((g) => g.groupCode == groupCode);
    if (index == -1) return;

    final group = state.groups[index];
    if (!group.isChannelAvailable(channel)) return;
    if (state.isSaving(groupCode)) return;

    final flipped = group.copyWithChannel(
      channel,
      !group.isChannelEnabled(channel),
    );

    emit(
      state.copyWith(
        groups: _replaced(index, flipped),
        savingGroupCodes: <String>{...state.savingGroupCodes, groupCode},
        hasSaveFailed: false,
      ),
    );

    try {
      await _source.updatePreference(state.userId, flipped);
      if (isClosed) return;
      emit(state.copyWith(savingGroupCodes: _without(groupCode)));
    } on Exception catch (_) {
      if (isClosed) return;
      // Put the tick back where it was; the screen toasts the reason.
      emit(
        state.copyWith(
          groups: _replaced(index, group),
          savingGroupCodes: _without(groupCode),
          hasSaveFailed: true,
        ),
      );
    }
  }

  /// The screen has toasted the failure, so the next tick starts clean.
  void clearFailure() => emit(state.copyWith(hasSaveFailed: false));

  List<NotificationPreferenceGroup> _replaced(
    int index,
    NotificationPreferenceGroup group,
  ) => List<NotificationPreferenceGroup>.of(state.groups)..[index] = group;

  Set<String> _without(String groupCode) =>
      state.savingGroupCodes.where((c) => c != groupCode).toSet();
}
