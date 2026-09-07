import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/newsletter_staff_scope.dart';
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

  /// One-shot guard: an unscoped (admin) user's first page is loaded by
  /// [resolveStaffScopeAndLoad] and must not be re-issued if the view remounts
  /// while this cubit lives. Not part of the emitted state — nothing renders
  /// from it.
  bool _adminListLoaded = false;

  static const int _pageSize = 10;

  /// Resolves which classrooms the signed-in staff member may see, then loads
  /// the first page for unscoped (admin) users. Scoped staff wait for
  /// [bootstrapStaffList], which needs the classroom list to pick a default.
  ///
  /// This was `_resolveStaffScopeAndLoad` in `SentNewsLetterTab`, where its
  /// result sat in four `setState` fields. It comes from
  /// `StaffRepository.getStaffProfile()` — an API call — so it is Cubit state
  /// with no exceptions (§2 bucket A), and moving it also stops a view from
  /// reaching a repository through a helper (§5).
  Future<void> resolveStaffScopeAndLoad() async {
    final NewsletterStaffScope scope = await resolveNewsletterStaffScope(
      storage: _storageService,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        isStaffScoped: scope.isScoped,
        primaryClassroomCode: scope.primaryClassroomCode,
        allowedClassroomCodes: scope.allowedClassroomCodes,
        isScopeResolved: true,
      ),
    );

    if (!scope.isScoped && !_adminListLoaded) {
      _adminListLoaded = true;
      await loadInitial();
    }
  }

  /// The codes actually sent to the API for a given user selection.
  ///
  /// A scoped staff member always gets their primary classroom included, and
  /// falls back to the first allowed classroom when nothing else resolves —
  /// so this is deliberately NOT the same list as the dropdown's selection.
  /// The codes actually sent to the API for a given user selection.
  ///
  /// Returns null for a SCOPED user whose scope resolved to nothing — see
  /// [hasUnresolvableScope]. An empty list would mean "no classroom filter",
  /// i.e. every classroom in the school, which is the opposite of what a
  /// scoped user is allowed to see. Callers must treat null as "do not query".
  List<String>? effectiveClassroomCodes(List<String> selectedCodes) {
    if (!state.isStaffScoped) return selectedCodes;

    final Set<String> codes = <String>{};
    final String primary = (state.primaryClassroomCode ?? '').trim();
    if (primary.isNotEmpty) codes.add(primary);
    codes.addAll(selectedCodes);

    if (codes.isEmpty && state.allowedClassroomCodes.isNotEmpty) {
      codes.add(state.allowedClassroomCodes.first);
    }
    if (codes.isEmpty) return null;
    return codes.toList();
  }

  /// True when this user is classroom-scoped but nothing could be resolved to
  /// scope them BY — no primary classroom, no allowed codes, no selection.
  ///
  /// Reachable when `getStaffProfile()` fails and the device has no cached
  /// allowed codes (first sign-in offline). Previously this produced an
  /// unrestricted query; it is now a visible error instead.
  bool hasUnresolvableScope(List<String> selectedCodes) =>
      state.isStaffScoped && effectiveClassroomCodes(selectedCodes) == null;

  /// One-shot default classroom selection for a scoped staff member, applied
  /// once the classroom list has arrived.
  Future<void> bootstrapStaffList({
    required List<String> defaultNames,
    required List<String> selectedCodes,
    required String search,
  }) async {
    if (isClosed) return;

    final List<String>? codes = effectiveClassroomCodes(selectedCodes);
    if (codes == null) {
      // Scoped, but nothing to scope by. Surface it rather than querying the
      // whole school, and do NOT latch `isStaffListBootstrapped` — the staff
      // profile or the classroom list may still arrive, and latching here is
      // what previously made the failure permanent for the cubit's lifetime.
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: AppStrings.newsletterClassroomScopeUnavailable,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedClassroomNames: defaultNames,
        isStaffListBootstrapped: true,
      ),
    );
    await applyFilters(search: search, classroomCodes: codes);
  }

  /// The classroom multi-select changed. Records the selection only; the view
  /// debounces before calling [applyFilters], exactly as it did before.
  void selectClassroomNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(selectedClassroomNames: names));
  }

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
          errorMessage: AppStrings.newsletterSchoolCodeMissing,
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
        state.withLoadedPage(
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
    // A scoped user with no classroom codes would query the WHOLE school.
    // `bootstrapStaffList` guarantees non-empty codes on success, so empty
    // here means the bootstrap has not succeeded yet — pull-to-refresh must
    // not become a second route to an unrestricted query.
    if (state.isStaffScoped && state.classroomCodes.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: AppStrings.newsletterClassroomScopeUnavailable,
        ),
      );
      return;
    }

    final schoolCode = state.schoolCode.isNotEmpty
        ? state.schoolCode
        : await _resolveSchoolCode();
    final int requestId = ++_refreshRequestId;

    if (schoolCode == null || schoolCode.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: AppStrings.newsletterSchoolCodeMissing,
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
        state.withLoadedPage(
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
    // `required`, and deliberately without defaults: defaulting these is how
    // a scoped staff member silently becomes unscoped. Every construction
    // site must state the scope, so dropping it is a compile error rather
    // than a permissions bug. [NewsletterListState.initial] is the one place
    // the "no scope yet" values are written down.
    required this.isStaffScoped,
    required this.isScopeResolved,
    required this.primaryClassroomCode,
    required this.allowedClassroomCodes,
    required this.selectedClassroomNames,
    required this.isStaffListBootstrapped,
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
        errorMessage = null,
        isStaffScoped = false,
        isScopeResolved = false,
        primaryClassroomCode = null,
        allowedClassroomCodes = const <String>[],
        selectedClassroomNames = const <String>[],
        isStaffListBootstrapped = false;

  /// This state with a freshly loaded page applied: the three list flags and
  /// the error cleared, pagination replaced.
  ///
  /// An instance method rather than the `NewsletterListState.loaded(...)`
  /// named constructor it replaces. That constructor rebuilt the state from
  /// nothing, so the six staff-scope fields had to be hand-copied back in at
  /// every call site — and forgetting one silently downgraded a scoped staff
  /// member to "unscoped", which is a permissions bug, not a rendering one.
  /// Here they are carried from `this` and are not parameters at all, so
  /// there is nothing left to forget.
  NewsletterListState withLoadedPage({
    required List<Newsletter> newsletters,
    required bool isFromCache,
    required String schoolCode,
    String search = '',
    List<String> classroomCodes = const <String>[],
    int page = 0,
    bool hasMore = false,
  }) {
    return NewsletterListState(
      newsletters: newsletters,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      isFromCache: isFromCache,
      schoolCode: schoolCode,
      search: search,
      classroomCodes: classroomCodes,
      page: page,
      hasMore: hasMore,
      errorMessage: null,
      // Carried, never passed — a page load says nothing about who the
      // signed-in staff member is allowed to see.
      isStaffScoped: isStaffScoped,
      isScopeResolved: isScopeResolved,
      primaryClassroomCode: primaryClassroomCode,
      allowedClassroomCodes: allowedClassroomCodes,
      selectedClassroomNames: selectedClassroomNames,
      isStaffListBootstrapped: isStaffListBootstrapped,
    );
  }

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

  // ── Staff scope: who the signed-in user is allowed to see ───────────────
  // Resolved once from StaffRepository.getStaffProfile(); these used to be
  // four setState fields on SentNewsLetterTab (§2 bucket A).

  /// True when the signed-in staff member only sees their own classrooms.
  final bool isStaffScoped;

  /// False until [NewsletterListCubit.resolveStaffScopeAndLoad] has answered.
  /// The list shows its shimmer while a scoped user is still unresolved.
  final bool isScopeResolved;

  /// Always included in the API query for a scoped staff member.
  final String? primaryClassroomCode;

  /// Every classroom the scoped staff member may query.
  final List<String> allowedClassroomCodes;

  /// The classroom multi-select's current chips, by NAME.
  ///
  /// Deliberately separate from [classroomCodes], which is what was actually
  /// sent to the API — those differ, because a scoped staff member's primary
  /// classroom is added to the query without appearing as a user selection.
  final List<String> selectedClassroomNames;

  /// True once a scoped staff member's default classroom has been picked.
  final bool isStaffListBootstrapped;

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
    bool? isStaffScoped,
    bool? isScopeResolved,
    String? primaryClassroomCode,
    List<String>? allowedClassroomCodes,
    List<String>? selectedClassroomNames,
    bool? isStaffListBootstrapped,
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
      isStaffScoped: isStaffScoped ?? this.isStaffScoped,
      isScopeResolved: isScopeResolved ?? this.isScopeResolved,
      // Set once, from the resolved scope; copyWith cannot null it back out.
      primaryClassroomCode: primaryClassroomCode ?? this.primaryClassroomCode,
      allowedClassroomCodes:
          allowedClassroomCodes ?? this.allowedClassroomCodes,
      selectedClassroomNames:
          selectedClassroomNames ?? this.selectedClassroomNames,
      isStaffListBootstrapped:
          isStaffListBootstrapped ?? this.isStaffListBootstrapped,
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
        isStaffScoped,
        isScopeResolved,
        primaryClassroomCode,
        allowedClassroomCodes,
        selectedClassroomNames,
        isStaffListBootstrapped,
      ];
}
