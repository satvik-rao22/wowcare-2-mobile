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
    if (state.isRefreshing) return;
    final schoolCode = state.schoolCode.isNotEmpty
        ? state.schoolCode
        : await _resolveSchoolCode();

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
        size: 50,
      );
      if (isClosed) return;
      emit(
        NewsletterListState.loaded(
          newsletters: page.items,
          isFromCache: false,
          schoolCode: schoolCode,
          search: state.search,
          classroomCodes: state.classroomCodes,
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
}

class NewsletterListState extends Equatable {
  const NewsletterListState({
    required this.newsletters,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.schoolCode,
    required this.search,
    required this.classroomCodes,
    this.errorMessage,
  });

  const NewsletterListState.initial()
      : newsletters = const <Newsletter>[],
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        schoolCode = '',
        search = '',
        classroomCodes = const <String>[],
        errorMessage = null;

  const NewsletterListState.loaded({
    required List<Newsletter> newsletters,
    required bool isFromCache,
    required String schoolCode,
    String search = '',
    List<String> classroomCodes = const <String>[],
  })  : newsletters = newsletters,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        schoolCode = schoolCode,
        search = search,
        classroomCodes = classroomCodes,
        errorMessage = null;

  final List<Newsletter> newsletters;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final String schoolCode;
  final String search;
  final List<String> classroomCodes;
  final String? errorMessage;

  NewsletterListState copyWith({
    List<Newsletter>? newsletters,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    String? schoolCode,
    String? search,
    List<String>? classroomCodes,
    String? errorMessage,
  }) {
    return NewsletterListState(
      newsletters: newsletters ?? this.newsletters,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      schoolCode: schoolCode ?? this.schoolCode,
      search: search ?? this.search,
      classroomCodes: classroomCodes ?? this.classroomCodes,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        newsletters,
        isLoading,
        isRefreshing,
        isFromCache,
        schoolCode,
        search,
        classroomCodes,
        errorMessage,
      ];
}
