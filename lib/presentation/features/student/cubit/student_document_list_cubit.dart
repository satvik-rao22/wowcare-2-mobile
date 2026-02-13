import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student_document.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';
import '../../../../domain/features/student/usecases/get_student_documents_usecase.dart';

class StudentDocumentsListCubit extends Cubit<StudentDocumentsListState> {
  StudentDocumentsListCubit({
    required GetStudentDocumentsUseCase getStudentDocumentsUseCase,
    required StudentRepository repository,
  })  : _getStudentDocumentsUseCase = getStudentDocumentsUseCase,
        _repository = repository,
        super(const StudentDocumentsListState.initial());

  final GetStudentDocumentsUseCase _getStudentDocumentsUseCase;
  final StudentRepository _repository;

  static const int _pageSize = 10;

  List<StudentDocument> _applyExpiryFilter(
      List<StudentDocument> documents,
      bool showExpired,
      ) {
    final now = DateTime.now();

    return documents.where((doc) {
      final expiry = DateTime.parse(doc.expiryDate);
      final isExpired = expiry.isBefore(now);

      return showExpired ? isExpired : !isExpired;
    }).toList();
  }


  Future<void> loadInitial(
      String studentCode, {
        String sort = 'name,asc',
        String? name,
        String? type,
        bool showExpired = false,
      }) async {

    final cached = await (_repository is StudentRepositoryWithCache
        ? (_repository as StudentRepositoryWithCache)
        .loadCachedStudentDocuments(studentCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        StudentDocumentsListState.loaded(
          //documents: cached.items,
          documents: _applyExpiryFilter(cached.items, showExpired),
          currentPage: 0,
          hasMore: cached.hasMore,
          isFromCache: true,
        ),
      );
      return;
    }


    await refresh(
      studentCode,
      sort: sort,
      name: name,
      type: type,
      showExpired: showExpired,
    );
  }

  Future<void> refresh(
      String studentCode, {
        String sort = 'name,asc',
        String? name,
        String? type,
        bool showExpired = false,
      }) async {
    print('🟢 Cubit.refresh() called');
    print('StudentCode: $studentCode');
    print('showExpired: $showExpired');

    if (state.isRefreshing) return;

    emit(
      state.copyWith(
        isLoading: state.documents.isEmpty,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    try {
      final firstPage = await _getStudentDocumentsUseCase(
        studentCode: studentCode,
        page: 0,
        size: _pageSize,
        sort: sort,
        name: name,
        type: type,
      );
      print('🟢 Cubit received ${firstPage.items.length} documents');
      print('Current page: ${firstPage.page}');
      print('Has more: ${firstPage.hasMore}');


      if (isClosed) return;

      emit(
        StudentDocumentsListState.loaded(
          //documents: firstPage.items,
          documents: _applyExpiryFilter(firstPage.items, showExpired),
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

  Future<void> loadNextPage(
      String studentCode, {
        String sort = 'name,asc',
        String? name,
        String? type,
        bool showExpired = false,
      }) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;

      final page = await _getStudentDocumentsUseCase(
        studentCode: studentCode,
        page: nextPageIndex,
        size: _pageSize,
        sort: sort,
        name: name,
        type: type,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          //documents: [...state.documents, ...page.items],
          documents: [
            ...state.documents,
            ..._applyExpiryFilter(page.items, showExpired),
          ],
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

class StudentDocumentsListState extends Equatable {
  const StudentDocumentsListState({
    required this.documents,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  const StudentDocumentsListState.initial()
      : documents = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        currentPage = 0,
        hasMore = false,
        isLoadingMore = false,
        errorMessage = null;

  const StudentDocumentsListState.loaded({
    required List<StudentDocument> documents,
    required bool isFromCache,
    this.currentPage = 0,
    this.hasMore = false,
  })  : documents = documents,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isLoadingMore = false,
        errorMessage = null;

  final List<StudentDocument> documents;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  StudentDocumentsListState copyWith({
    List<StudentDocument>? documents,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return StudentDocumentsListState(
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
