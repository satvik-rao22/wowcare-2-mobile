import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff/usecases/get_staff_documents_usecase.dart';

class StaffDocumentsListCubit extends Cubit<StaffDocumentsListState> {
  StaffDocumentsListCubit({
    required GetStaffDocumentsUseCase getStaffDocumentsUseCase,
    required StaffRepository repository,
  })  : _getStaffDocumentsUseCase = getStaffDocumentsUseCase,
        _repository = repository,
        super(const StaffDocumentsListState.initial());

  final GetStaffDocumentsUseCase _getStaffDocumentsUseCase;
  final StaffRepository _repository;

  static const int _pageSize = 10;

  Future<void> loadInitial(String staffCode, {bool? expired}) async {
    // Try cache first
    final cached = await (_repository is StaffRepositoryWithCache
        ? (_repository as StaffRepositoryWithCache)
            .loadCachedStaffDocuments(staffCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        StaffDocumentsListState.loaded(
          documents: cached.items,
          currentPage: cached.page,
          hasMore: cached.hasMore,
          isFromCache: true,
        ),
      );
      // If we have a fresh enough cache, don't auto-hit the API.
      return;
    }

    // No cache (or expired) – load from API.
    await refresh(staffCode, expired: expired);
  }

  Future<void> refresh(String staffCode, {bool? expired}) async {
    if (state.isRefreshing) return;

    emit(
      state.copyWith(
        isLoading: state.documents.isEmpty,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    try {
      // Load only page 0 on refresh
      final firstPage = await _getStaffDocumentsUseCase(
        staffCode: staffCode,
        page: 0,
        size: _pageSize,
        expired: expired,
      );

      if (isClosed) return;

      emit(
        StaffDocumentsListState.loaded(
          documents: firstPage.items,
          currentPage: firstPage.page,
          hasMore: firstPage.hasMore,
          isFromCache: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadNextPage(String staffCode, {bool? expired}) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final page = await _getStaffDocumentsUseCase(
        staffCode: staffCode,
        page: nextPageIndex,
        size: _pageSize,
        expired: expired,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          documents: [...state.documents, ...page.items],
          currentPage: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}

class StaffDocumentsListState extends Equatable {
  const StaffDocumentsListState({
    required this.documents,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const StaffDocumentsListState.initial()
      : documents = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null;

  const StaffDocumentsListState.loaded({
    required List<StaffDocument> documents,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
  })  : documents = documents,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isLoadingMore = false,
        errorMessage = null;

  final List<StaffDocument> documents;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  StaffDocumentsListState copyWith({
    List<StaffDocument>? documents,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return StaffDocumentsListState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        documents,
        isLoading,
        isRefreshing,
        isFromCache,
        currentPage,
        hasMore,
        isLoadingMore,
        errorMessage,
      ];
}

