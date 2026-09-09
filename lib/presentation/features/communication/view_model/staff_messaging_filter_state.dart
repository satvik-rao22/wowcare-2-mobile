import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';

class StaffMessagingFilterState extends Equatable {
  final List<StaffMember> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? selectedClassroomCode;
  final String? selectedClassroomName;
  final String? selectedDesignation;
  final String? selectedStaffStatus;
  final String searchQuery;
  final String? errorMessage;

  const StaffMessagingFilterState({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    this.selectedClassroomCode,
    this.selectedClassroomName,
    this.selectedDesignation,
    this.selectedStaffStatus,
    required this.searchQuery,
    this.errorMessage,
  });

  const StaffMessagingFilterState.initial()
    : items = const [],
      currentPage = 0,
      hasMore = true,
      isLoading = true,
      isRefreshing = false,
      isLoadingMore = false,
      selectedClassroomCode = null,
      selectedClassroomName = null,
      selectedDesignation = null,
      selectedStaffStatus = null,
      searchQuery = '',
      errorMessage = null;

  StaffMessagingFilterState copyWith({
    List<StaffMember>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? selectedClassroomCode,
    String? selectedClassroomName,
    String? selectedDesignation,
    String? selectedStaffStatus,
    String? searchQuery,
    String? errorMessage,
    bool clearClassroom = false,
    bool clearDesignation = false,
    bool clearStaffStatus = false,
  }) {
    return StaffMessagingFilterState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedClassroomCode: clearClassroom
          ? null
          : (selectedClassroomCode ?? this.selectedClassroomCode),
      selectedClassroomName: clearClassroom
          ? null
          : (selectedClassroomName ?? this.selectedClassroomName),
      selectedDesignation: clearDesignation
          ? null
          : (selectedDesignation ?? this.selectedDesignation),
      selectedStaffStatus: clearStaffStatus
          ? null
          : (selectedStaffStatus ?? this.selectedStaffStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    items,
    currentPage,
    hasMore,
    isLoading,
    isRefreshing,
    isLoadingMore,
    selectedClassroomCode,
    selectedClassroomName,
    selectedDesignation,
    selectedStaffStatus,
    searchQuery,
    errorMessage,
  ];
}
