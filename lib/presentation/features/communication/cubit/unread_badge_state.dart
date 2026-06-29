import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

class UnreadBadgeState extends Equatable {
  const UnreadBadgeState({
    required this.countsByType,
    required this.isLoading,
    required this.isRefreshing,
    this.errorMessage,
  });

  const UnreadBadgeState.initial()
      : countsByType = const {},
        isLoading = false,
        isRefreshing = false,
        errorMessage = null;

  /// Unread counts keyed by [ConversationType.toApiString()].
  /// e.g. {'STAFF_DIRECT': 3, 'ROOM_CHAT': 7, 'ADMIN_CHAT': 0}
  final Map<String, int> countsByType;

  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  // ─── Derived helpers ────────────────────────────────────────────────────────

  /// Sum of all unread counts across every conversation type.
  int get totalUnread => countsByType.values.fold(0, (sum, c) => sum + c);

  /// Unread count for a specific [ConversationType].
  int unreadFor(ConversationType type) =>
      countsByType[type.toApiString()] ?? 0;

  /// Unread counts visible to an admin (all three types).
  int get adminTotal =>
      unreadFor(ConversationType.staffDirect) +
      unreadFor(ConversationType.roomChat) +
      unreadFor(ConversationType.adminChat);

  /// Unread counts visible to a staff member.
  int get staffTotal =>
      unreadFor(ConversationType.staffDirect) +
      unreadFor(ConversationType.roomChat);

  /// Unread counts visible to a parent.
  int get parentTotal =>
      unreadFor(ConversationType.roomChat) +
      unreadFor(ConversationType.adminChat);

  /// Unread total for the given role string ('admin', 'staff', 'parent').
  int totalForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminTotal;
      case 'staff':
        return staffTotal;
      case 'parent':
        return parentTotal;
      default:
        return totalUnread;
    }
  }

  UnreadBadgeState copyWith({
    Map<String, int>? countsByType,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UnreadBadgeState(
      countsByType: countsByType ?? this.countsByType,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [countsByType, isLoading, isRefreshing, errorMessage];
}
