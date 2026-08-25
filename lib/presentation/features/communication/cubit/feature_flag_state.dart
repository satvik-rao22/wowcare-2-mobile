part of 'feature_flag_cubit.dart';

/// State for feature flags.
/// Single immutable class (not sealed union) following WowCare patterns.
class FeatureFlagState extends Equatable {
  const FeatureFlagState({
    this.isLoading = false,
    this.flags = const {},
    this.errorMessage = '',
  });

  /// Loading state (true while fetching flags from storage)
  final bool isLoading;

  /// Map of flag name → enabled state
  /// Example: {'bulkMessaging': false, 'realtimeMessaging': true}
  final Map<String, bool> flags;

  /// Error message if flag load fails
  final String errorMessage;

  /// Check if a specific flag is enabled
  bool isFlagEnabled(String flagName) {
    return flags[flagName] ?? false;
  }

  /// Master communication enable/disable
  bool get isCommunicationEnabled => flags['communicationEnabled'] ?? true;

  /// Parent messaging (Room Chat + Admin Chat)
  bool get isParentMessagingEnabled => flags['parentMessagingEnabled'] ?? true;

  /// Staff messaging (Staff Direct)
  bool get isStaffMessagingEnabled => flags['staffMessagingEnabled'] ?? true;

  /// Admin Chat specifically
  bool get isAdminChatEnabled => flags['adminChatEnabled'] ?? true;

  /// Bulk messaging (admin-only)
  bool get isBulkMessagingEnabled => flags['bulkMessagingEnabled'] ?? false;

  /// Private mode feature
  bool get isPrivateModeEnabled => flags['privateModeEnabled'] ?? true;

  /// Firebase realtime sync
  bool get isRealtimeEnabled => flags['realtimeEnabled'] ?? true;

  /// Create a copy with optional field overrides
  FeatureFlagState copyWith({
    bool? isLoading,
    Map<String, bool>? flags,
    String? errorMessage,
  }) {
    return FeatureFlagState(
      isLoading: isLoading ?? this.isLoading,
      flags: flags ?? this.flags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, flags, errorMessage];
}
