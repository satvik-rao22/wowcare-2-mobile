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
    this.activeClassroomCodes = const [],
    this.activeTagCodes = const [],
    this.activeDesignations = const [],
    this.activeStudentStatuses = const [],
    this.activeStaffStatuses = const [],
    this.activeSearch,
  });

  const ConversationListState.initial({
    required ConversationType conversationType,
  }) : conversationType = conversationType,
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
       activeClassroomCodes = const [],
       activeTagCodes = const [],
       activeDesignations = const [],
       activeStudentStatuses = const [],
       activeStaffStatuses = const [],
       activeSearch = null;

  const ConversationListState.loaded({
    required ConversationType conversationType,
    required List<ConversationEntity> conversations,
    required bool isFromCache,
    int page = 0,
    bool hasMore = false,
    this.activeClassroomCodes = const [],
    this.activeTagCodes = const [],
    this.activeDesignations = const [],
    this.activeStudentStatuses = const [],
    this.activeStaffStatuses = const [],
    this.activeSearch,
  }) : conversationType = conversationType,
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
       staffSearchErrorMessage = null;

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

  // Active filters — sent straight through to the backend's
  // getConversationsByType query params (see GetConversationsEntityUseCase).
  // classroomCodes/tagCodes apply to student-scoped types (ROOM_CHAT,
  // ADMIN_CHAT); designations/staffStatuses apply to STAFF_DIRECT.
  final List<String> activeClassroomCodes;
  final List<String> activeTagCodes;
  final List<String> activeDesignations;
  final List<String> activeStudentStatuses;
  final List<String> activeStaffStatuses;
  final String? activeSearch;

  bool get hasConversations => conversations.isNotEmpty;
  bool get hasStaffSearchError => staffSearchErrorMessage != null;
  bool get hasActiveFilters =>
      activeClassroomCodes.isNotEmpty ||
      activeTagCodes.isNotEmpty ||
      activeDesignations.isNotEmpty ||
      activeStudentStatuses.isNotEmpty ||
      activeStaffStatuses.isNotEmpty ||
      (activeSearch?.isNotEmpty ?? false);

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
    List<String>? activeClassroomCodes,
    List<String>? activeTagCodes,
    List<String>? activeDesignations,
    List<String>? activeStudentStatuses,
    List<String>? activeStaffStatuses,
    String? activeSearch,
    bool clearActiveSearch = false,
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
      staffSearchErrorMessage: clearStaffSearchError
          ? null
          : (staffSearchErrorMessage ?? this.staffSearchErrorMessage),
      activeClassroomCodes: activeClassroomCodes ?? this.activeClassroomCodes,
      activeTagCodes: activeTagCodes ?? this.activeTagCodes,
      activeDesignations: activeDesignations ?? this.activeDesignations,
      activeStudentStatuses:
          activeStudentStatuses ?? this.activeStudentStatuses,
      activeStaffStatuses: activeStaffStatuses ?? this.activeStaffStatuses,
      activeSearch: clearActiveSearch
          ? null
          : (activeSearch ?? this.activeSearch),
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
    activeClassroomCodes,
    activeTagCodes,
    activeDesignations,
    activeStudentStatuses,
    activeStaffStatuses,
    activeSearch,
  ];
}
