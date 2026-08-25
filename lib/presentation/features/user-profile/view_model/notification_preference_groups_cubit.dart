import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/domain/features/notifications/usecases/get_notification_preference_groups_usecase.dart';
import 'package:wowcare/domain/features/notifications/usecases/update_notification_preference_groups_usecase.dart';

class NotificationPreferenceGroupsState extends Equatable {
  const NotificationPreferenceGroupsState({
    this.groups = const <NotificationPreferenceGroup>[],
    this.isLoading = false,
    this.savingGroupCodes = const <String>{},
    this.errorMessage,
  });

  final List<NotificationPreferenceGroup> groups;
  final bool isLoading;

  /// `groupCode`s with a PATCH in flight — their checkboxes are disabled
  /// while saving so a second tap can't race the first.
  final Set<String> savingGroupCodes;
  final String? errorMessage;

  NotificationPreferenceGroupsState copyWith({
    List<NotificationPreferenceGroup>? groups,
    bool? isLoading,
    Set<String>? savingGroupCodes,
    String? errorMessage,
  }) {
    return NotificationPreferenceGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      savingGroupCodes: savingGroupCodes ?? this.savingGroupCodes,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    groups,
    isLoading,
    savingGroupCodes,
    errorMessage,
  ];
}

/// Owns the grouped notification-preferences screen. Loads groups from
/// `GET /preferences/groups` and, on every checkbox toggle, optimistically
/// flips that channel and immediately PATCHes the owning group's full
/// (available-channels-only) state back — reverting on failure.
class NotificationPreferenceGroupsCubit
    extends Cubit<NotificationPreferenceGroupsState> {
  NotificationPreferenceGroupsCubit({
    required GetNotificationPreferenceGroupsUseCase getGroups,
    required UpdateNotificationPreferenceGroupsUseCase updateGroups,
    required StorageService storage,
  }) : _getGroups = getGroups,
       _updateGroups = updateGroups,
       _storage = storage,
       super(const NotificationPreferenceGroupsState());

  final GetNotificationPreferenceGroupsUseCase _getGroups;
  final UpdateNotificationPreferenceGroupsUseCase _updateGroups;
  final StorageService _storage;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final userCode = await _read(StorageKeys.userCode);
      if (userCode.isEmpty) {
        emit(
          state.copyWith(
            groups: const <NotificationPreferenceGroup>[],
            isLoading: false,
          ),
        );
        return;
      }
      final groups = await _getGroups(userCode: userCode);
      final sorted = List<NotificationPreferenceGroup>.from(groups)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      emit(state.copyWith(groups: sorted, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Toggles [channel] for [groupCode]. No-ops if that channel isn't
  /// available for the group or a save for it is already in flight.
  Future<void> toggleChannel(
    String groupCode,
    String channel,
    bool value,
  ) async {
    final index = state.groups.indexWhere((g) => g.groupCode == groupCode);
    if (index == -1) return;
    final group = state.groups[index];
    if (!group.isChannelAvailable(channel)) return;
    if (state.savingGroupCodes.contains(groupCode)) return;

    final updatedGroup = group.copyWithChannel(channel, value);
    final updatedGroups = List<NotificationPreferenceGroup>.from(state.groups)
      ..[index] = updatedGroup;
    emit(
      state.copyWith(
        groups: updatedGroups,
        savingGroupCodes: <String>{...state.savingGroupCodes, groupCode},
        errorMessage: null,
      ),
    );

    try {
      final userCode = await _read(StorageKeys.userCode);
      await _updateGroups(
        userCode: userCode,
        request: UpdateNotificationPreferenceGroupsRequest(
          preferences: <NotificationPreferenceGroupUpdate>[
            NotificationPreferenceGroupUpdate(
              groupCode: groupCode,
              channels: updatedGroup.channels,
            ),
          ],
        ),
      );
      emit(
        state.copyWith(
          savingGroupCodes: state.savingGroupCodes
              .where((c) => c != groupCode)
              .toSet(),
        ),
      );
    } catch (e) {
      // Revert the optimistic flip.
      final revertedGroups = List<NotificationPreferenceGroup>.from(
        state.groups,
      )..[index] = group;
      emit(
        state.copyWith(
          groups: revertedGroups,
          savingGroupCodes: state.savingGroupCodes
              .where((c) => c != groupCode)
              .toSet(),
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<String> _read(String key) async =>
      (await _storage.getString(key) ?? '').trim();
}
