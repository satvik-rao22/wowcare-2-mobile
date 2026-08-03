import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/school_code_resolver.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';
import 'package:wowcare/domain/features/newsletter/usecases/get_sent_newsletters_usecase.dart';

class NewsletterListCubit extends Cubit<NewsletterListState> {
  NewsletterListCubit({
    required GetSentNewslettersUseCase getSentNewslettersUseCase,
    required NewsletterRepository repository,
    required StorageService storageService,
  })  : _getSentNewslettersUseCase = getSentNewslettersUseCase,
        _repository = repository,
        _storageService = storageService,
        super(const NewsletterListState.initial());

  final GetSentNewslettersUseCase _getSentNewslettersUseCase;
  final NewsletterRepository _repository;
  final StorageService _storageService;
  int _refreshRequestId = 0;

  static const int _pageSize = 10;

  Future<String?> _resolveSchoolCode() async {
    final schoolCode = await resolveLoggedInSchoolCode(_storageService);
    if (schoolCode.isEmpty) return null;
    return schoolCode;
  }

  Future<void> loadInitial() async {
    final schoolCode = await _resolveSchoolCode();
    if (schoolCode == null) {
      emit(
        state.copyWith(
          errorMessage: 'School code not available. Please sign in again.',
          isLoading: false,
          isRefreshing: false,
        ),
      );
      return;
    }

    final cached = await (_repository is NewsletterRepositoryWithCache
        ? (_repository as NewsletterRepositoryWithCache)
            .loadCachedSentNewsletters(schoolCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        NewsletterListState.loaded(
          newsletters: cached.items,
          isFromCache: true,
          schoolCode: schoolCode,
          page: cached.page,
          hasMore: cached.hasMore,
        ),
      );
      refresh();
      return;
    }

    await refresh();
  }

  Future<void> applyFilters({
    String? search,
    List<String>? classroomCodes,
  }) async {
    final String normalizedSearch = (search ?? state.search).trim();
    final List<String> normalizedClassroomCodes = (classroomCodes ??
            state.classroomCodes)
        .map((String code) => code.trim())
        .where((String code) => code.isNotEmpty)
        .toSet()
        .toList();
    emit(
      state.copyWith(
        search: normalizedSearch,
        classroomCodes: normalizedClassroomCodes,
      ),
    );
    await refresh();
  }

  Future<void> refresh() async {
    final schoolCode = state.schoolCode.isNotEmpty
        ? state.schoolCode
        : await _resolveSchoolCode();
    final int requestId = ++_refreshRequestId;

    if (schoolCode == null || schoolCode.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'School code not available. Please sign in again.',
          isLoading: false,
          isRefreshing: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: state.newsletters.isEmpty,
        isRefreshing: true,
        isLoadingMore: false,
        errorMessage: null,
        schoolCode: schoolCode,
      ),
    );

    try {
      final page = await _getSentNewslettersUseCase(
        schoolCode: schoolCode,
        search: state.search,
        classroomCodes: state.classroomCodes,
        page: 0,
        size: _pageSize,
      );
      if (isClosed || requestId != _refreshRequestId) return;
      emit(
        NewsletterListState.loaded(
          newsletters: page.items,
          isFromCache: false,
          schoolCode: schoolCode,
          search: state.search,
          classroomCodes: state.classroomCodes,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _refreshRequestId) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Loads the next page and appends it to the current list. No-op while a
  /// refresh/load is already running, when there are no more pages, or before
  /// the first page has loaded.
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || state.isRefreshing || !state.hasMore) return;
    if (state.newsletters.isEmpty) return;
    final schoolCode = state.schoolCode;
    if (schoolCode.isEmpty) return;

    // Bind to the active refresh generation so a concurrent refresh() discards
    // this page instead of appending a stale/duplicate batch.
    final int requestId = _refreshRequestId;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final page = await _getSentNewslettersUseCase(
        schoolCode: schoolCode,
        search: state.search,
        classroomCodes: state.classroomCodes,
        page: state.page + 1,
        size: _pageSize,
      );
      if (isClosed || requestId != _refreshRequestId) return;
      emit(
        state.copyWith(
          newsletters: <Newsletter>[...state.newsletters, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed || requestId != _refreshRequestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}

class NewsletterListState extends Equatable {
  const NewsletterListState({
    required this.newsletters,
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.isFromCache,
    required this.schoolCode,
    required this.search,
    required this.classroomCodes,
    required this.page,
    required this.hasMore,
    this.errorMessage,
  });

  const NewsletterListState.initial()
      : newsletters = const <Newsletter>[],
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        isFromCache = false,
        schoolCode = '',
        search = '',
        classroomCodes = const <String>[],
        page = 0,
        hasMore = true,
        errorMessage = null;

  const NewsletterListState.loaded({
    required List<Newsletter> newsletters,
    required bool isFromCache,
    required String schoolCode,
    String search = '',
    List<String> classroomCodes = const <String>[],
    int page = 0,
    bool hasMore = false,
  })  : newsletters = newsletters,
        isLoading = false,
        isRefreshing = false,
        isLoadingMore = false,
        isFromCache = isFromCache,
        schoolCode = schoolCode,
        search = search,
        classroomCodes = classroomCodes,
        page = page,
        hasMore = hasMore,
        errorMessage = null;

  final List<Newsletter> newsletters;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isFromCache;
  final String schoolCode;
  final String search;
  final List<String> classroomCodes;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  NewsletterListState copyWith({
    List<Newsletter>? newsletters,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isFromCache,
    String? schoolCode,
    String? search,
    List<String>? classroomCodes,
    int? page,
    bool? hasMore,
    String? errorMessage,
  }) {
    return NewsletterListState(
      newsletters: newsletters ?? this.newsletters,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isFromCache: isFromCache ?? this.isFromCache,
      schoolCode: schoolCode ?? this.schoolCode,
      search: search ?? this.search,
      classroomCodes: classroomCodes ?? this.classroomCodes,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        newsletters,
        isLoading,
        isRefreshing,
        isLoadingMore,
        isFromCache,
        schoolCode,
        search,
        classroomCodes,
        page,
        hasMore,
        errorMessage,
      ];
}
