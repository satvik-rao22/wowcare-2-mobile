part of 'student_newsletters_cubit.dart';

enum StudentNewslettersStatus { initial, loading, loaded, error }

class StudentNewslettersState extends Equatable {
  const StudentNewslettersState({
    required this.status,
    required this.items,
    required this.selectedChildCode,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
    required this.isPaginationLoading,
    required this.errorMessage,
  });

  const StudentNewslettersState.initial()
    : status = StudentNewslettersStatus.initial,
      items = const <NewsletterEntity>[],
      selectedChildCode = '',
      currentPage = 0,
      pageSize = 10,
      totalPages = 0,
      totalElements = 0,
      hasMore = false,
      isPaginationLoading = false,
      errorMessage = '';

  final StudentNewslettersStatus status;
  final List<NewsletterEntity> items;
  final String selectedChildCode;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
  final bool isPaginationLoading;
  final String errorMessage;

  bool get isLoading => status == StudentNewslettersStatus.loading;
  bool get isLoaded => status == StudentNewslettersStatus.loaded;
  bool get isError => status == StudentNewslettersStatus.error;
  bool get isInitial => status == StudentNewslettersStatus.initial;

  StudentNewslettersState copyWith({
    StudentNewslettersStatus? status,
    List<NewsletterEntity>? items,
    String? selectedChildCode,
    int? currentPage,
    int? pageSize,
    int? totalPages,
    int? totalElements,
    bool? hasMore,
    bool? isPaginationLoading,
    String? errorMessage,
  }) {
    return StudentNewslettersState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedChildCode: selectedChildCode ?? this.selectedChildCode,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    selectedChildCode,
    currentPage,
    pageSize,
    totalPages,
    totalElements,
    hasMore,
    isPaginationLoading,
    errorMessage,
  ];
}

