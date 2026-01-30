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

  Future<void> loadInitial(String staffCode) async {
    // Try cache first
    final cached = await (_repository is StaffRepositoryWithCache
        ? (_repository as StaffRepositoryWithCache)
            .loadCachedStaffDocuments(staffCode)
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        StaffDocumentsListState.loaded(
          documents: cached.items,
          isFromCache: true,
        ),
      );
      // If we have a fresh enough cache, don't auto-hit the API.
      return;
    }

    // No cache (or expired) – load from API.
    await refresh(staffCode);
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
      final documentsPage = await _getStaffDocumentsUseCase(
        staffCode: staffCode,
        page: 0,
        size: 100, // Load all documents for now
        expired: expired,
      );

      if (isClosed) return;

      emit(
        StaffDocumentsListState.loaded(
          documents: documentsPage.items,
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
}

class StaffDocumentsListState extends Equatable {
  const StaffDocumentsListState({
    required this.documents,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.errorMessage,
  });

  const StaffDocumentsListState.initial()
      : documents = const [],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        errorMessage = null;

  const StaffDocumentsListState.loaded({
    required List<StaffDocument> documents,
    required bool isFromCache,
  })  : documents = documents,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        errorMessage = null;

  final List<StaffDocument> documents;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final String? errorMessage;

  StaffDocumentsListState copyWith({
    List<StaffDocument>? documents,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    String? errorMessage,
  }) {
    return StaffDocumentsListState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [documents, isLoading, isRefreshing, isFromCache, errorMessage];
}

