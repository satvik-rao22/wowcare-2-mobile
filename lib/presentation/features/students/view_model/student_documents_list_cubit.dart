import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/file_download_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import 'package:wowcare/domain/features/student/entities/student_document.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_documents_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_student_document_usecase.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

class StudentDocumentsListCubit extends Cubit<StudentDocumentsListState> {
  StudentDocumentsListCubit({
    required GetStudentDocumentsUseCase getStudentDocumentsUseCase,
    required DeleteStudentDocumentUseCase deleteStudentDocumentUseCase,
    required StudentRepository repository,
    FileDownloadService? fileDownloadService,
  }) : _getStudentDocumentsUseCase = getStudentDocumentsUseCase,
       _deleteStudentDocumentUseCase = deleteStudentDocumentUseCase,
       _repository = repository,
       _fileDownloadService = fileDownloadService ?? FileDownloadService(),
       super(const StudentDocumentsListState.initial());

  final GetStudentDocumentsUseCase _getStudentDocumentsUseCase;
  final DeleteStudentDocumentUseCase _deleteStudentDocumentUseCase;
  final StudentRepository _repository;
  final FileDownloadService _fileDownloadService;

  /// Downloads a resolved document URL to [savePath]. Kept off the View (which
  /// must not construct a Dio) and off the authenticated API client (the URL is
  /// a pre-signed external link — see [FileDownloadService]).
  Future<void> downloadFile(String url, String savePath) =>
      _fileDownloadService.downloadToFile(url, savePath);

  static const int _pageSize = 10;

  Future<void> loadInitial(String studentCode, {bool? expiredOnly}) async {
    final cached = await (_repository is StudentRepositoryWithCache
        ? (_repository as StudentRepositoryWithCache)
              .loadCachedStudentDocuments(studentCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        StudentDocumentsListState.loaded(
          documents: cached.items,
          currentPage: 0,
          hasMore: cached.hasMore,
          isFromCache: true,
        ),
      );
      return;
    }

    await refresh(studentCode, expiredOnly: expiredOnly);
  }

  Future<void> refresh(String studentCode, {bool? expiredOnly}) async {
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
        expiredOnly: expiredOnly,
      );

      if (isClosed) return;

      emit(
        StudentDocumentsListState.loaded(
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
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadNextPage(String studentCode, {bool? expiredOnly}) async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.currentPage < 0) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final page = await _getStudentDocumentsUseCase(
        studentCode: studentCode,
        page: nextPageIndex,
        size: _pageSize,
        expiredOnly: expiredOnly,
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
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Document UUIDs whose delete is in flight — a second tap on the same
  /// document while the first delete is still running is ignored, so the cubit
  /// enforces single-flight independently of any UI disabling.
  final Set<String> _deletingDocuments = <String>{};

  Future<String?> deleteDocument(
    String studentCode,
    String documentUuid,
  ) async {
    if (_deletingDocuments.contains(documentUuid)) return null;
    _deletingDocuments.add(documentUuid);
    try {
      final result = await _deleteStudentDocumentUseCase.call(
        documentUuid: documentUuid,
        studentCode: studentCode,
      );

      return result.fold(
        (failure) {
          return failure.message ?? StudentStrings.failedToDeleteDocument;
        },
        (message) {
          refresh(studentCode, expiredOnly: null);
          return null;
        },
      );
    } catch (e) {
      return ApiErrorHandler.extractErrorMessage(e);
    } finally {
      _deletingDocuments.remove(documentUuid);
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
  }) : documents = documents,
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
