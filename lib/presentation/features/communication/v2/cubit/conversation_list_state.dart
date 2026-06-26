import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';

class ConversationListState extends Equatable {
  const ConversationListState({
    required this.conversationType,
    required this.conversations,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.hasMore,
    required this.page,
    this.errorMessage,
    this.staffSearchResults = const [],
    this.isSearchingStaff = false,
    this.lastStaffSearchQuery,
    this.staffSearchErrorMessage,
    this.activeDesignation,
    this.activeStaffStatus,
    this.activeClassroom,
  });

  const ConversationListState.initial({required ConversationType conversationType})
      : conversationType = conversationType,
        conversations = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        hasMore = true,
        page = 0,
        errorMessage = null,
        staffSearchResults = const [],
        isSearchingStaff = false,
        lastStaffSearchQuery = null,
        staffSearchErrorMessage = null,
        activeDesignation = null,
        activeStaffStatus = null,
        activeClassroom = null;

  const ConversationListState.loaded({
    required ConversationType conversationType,
    required List<ConversationEntity> conversations,
    required bool isFromCache,
    int page = 0,
    bool hasMore = false,
  })  : conversationType = conversationType,
        conversations = conversations,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        hasMore = hasMore,
        page = page,
        errorMessage = null,
        staffSearchResults = const [],
        isSearchingStaff = false,
        lastStaffSearchQuery = null,
        staffSearchErrorMessage = null,
        activeDesignation = null,
        activeStaffStatus = null,
        activeClassroom = null;

  final ConversationType conversationType;
  final List<ConversationEntity> conversations;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  /// Results from the staff directory API while the user is typing a search
  /// query. Empty when no search is active.
  final List<MessagingStaffResult> staffSearchResults;

  /// True while the staff directory API call is in flight.
  final bool isSearchingStaff;

  /// Last successful staff search query, used for retry.
  final String? lastStaffSearchQuery;

  /// Error message from the last failed staff search. Null if search succeeded.
  final String? staffSearchErrorMessage;

  /// Active filter: staff designation (STAFF_DIRECT only).
  final String? activeDesignation;

  /// Active filter: staff employment status (STAFF_DIRECT only).
  final String? activeStaffStatus;

  /// Active filter: classroom code (STAFF_DIRECT only).
  final String? activeClassroom;

  bool get hasConversations => conversations.isNotEmpty;
  bool get hasStaffSearchError => staffSearchErrorMessage != null;
  bool get hasActiveFilters =>
      activeDesignation != null ||
      activeStaffStatus != null ||
      activeClassroom != null;

  ConversationListState copyWith({
    List<ConversationEntity>? conversations,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    bool? hasMore,
    int? page,
    String? errorMessage,
    bool clearError = false,
    List<MessagingStaffResult>? staffSearchResults,
    bool? isSearchingStaff,
    String? lastStaffSearchQuery,
    String? staffSearchErrorMessage,
    bool clearStaffSearchError = false,
    String? activeDesignation,
    bool clearDesignation = false,
    String? activeStaffStatus,
    bool clearStaffStatus = false,
    String? activeClassroom,
    bool clearClassroom = false,
  }) {
    return ConversationListState(
      conversationType: conversationType,
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      staffSearchResults: staffSearchResults ?? this.staffSearchResults,
      isSearchingStaff: isSearchingStaff ?? this.isSearchingStaff,
      lastStaffSearchQuery: lastStaffSearchQuery ?? this.lastStaffSearchQuery,
      staffSearchErrorMessage: clearStaffSearchError ? null : (staffSearchErrorMessage ?? this.staffSearchErrorMessage),
      activeDesignation: clearDesignation ? null : (activeDesignation ?? this.activeDesignation),
      activeStaffStatus: clearStaffStatus ? null : (activeStaffStatus ?? this.activeStaffStatus),
      activeClassroom: clearClassroom ? null : (activeClassroom ?? this.activeClassroom),
    );
  }

  @override
  List<Object?> get props => [
        conversationType,
        conversations,
        isLoading,
        isRefreshing,
        isFromCache,
        hasMore,
        page,
        errorMessage,
        staffSearchResults,
        isSearchingStaff,
        lastStaffSearchQuery,
        staffSearchErrorMessage,
        activeDesignation,
        activeStaffStatus,
        activeClassroom,
      ];
}
