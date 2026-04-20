import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff/usecases/get_staff_documents_usecase.dart';
import '../../../../domain/features/staff/usecases/delete_staff_document_usecase.dart';

class StaffDocumentsListCubit extends Cubit<StaffDocumentsListState> {
  StaffDocumentsListCubit({
    required GetStaffDocumentsUseCase getStaffDocumentsUseCase,
    required DeleteStaffDocumentUseCase deleteStaffDocumentUseCase,
    required StaffRepository repository,
  })  : _getStaffDocumentsUseCase = getStaffDocumentsUseCase,
        _deleteStaffDocumentUseCase = deleteStaffDocumentUseCase,
        _repository = repository,
        super(const StaffDocumentsListState.initial());

  final GetStaffDocumentsUseCase _getStaffDocumentsUseCase;
  final DeleteStaffDocumentUseCase _deleteStaffDocumentUseCase;
  final StaffRepository _repository;

  static const int _pageSize = 10;

  Future<void> loadInitial(String staffCode, {bool? expired}) async {
    // Try cache first
    final cached = await (_repository is StaffRepositoryWithCache
        ? (_repository as StaffRepositoryWithCache)
            .loadCachedStaffDocuments(staffCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      // Always start from page 0 on initial load, even if cache has a different page
      emit(
        StaffDocumentsListState.loaded(
          documents: cached.items,
          currentPage: 0, // Always start from page 0
          hasMore: cached.hasMore,
          isFromCache: true,
        ),
      );
      // Stale-while-revalidate: show cached immediately, but refresh from API so
      // newly-added fields (e.g. uploadedBy/createdAt) appear even if cache is old.
      // ignore: unawaited_futures
      refresh(staffCode, expired: expired);
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
    // Don't load next page if we're still loading initial data or if there's no more data
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    
    // Don't load if we haven't loaded any pages yet (currentPage should be >= 0 after initial load)
    if (state.currentPage < 0) return;

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

  Future<String?> deleteDocument(String staffCode, String documentUuid) async {
    try {
      final result = await _deleteStaffDocumentUseCase.call(
        documentUuid: documentUuid,
        staffCode: staffCode,
      );

      return result.fold(
        (failure) {
          // Return error message
          return failure.message ?? 'Failed to delete document';
        },
        (message) {
          // Refresh the list after successful delete
          refresh(staffCode, expired: null);
          // Return null on success (caller will show success message)
          return null;
        },
      );
    } catch (e) {
      return e.toString();
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

