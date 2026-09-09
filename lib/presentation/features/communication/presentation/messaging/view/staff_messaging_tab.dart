import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/messaging_resolvers.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/conversation_display.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../domain/features/communication/entities/conversation.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/contact_filter_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/contact_filter_state.dart';
import '../../../../../../shared/common/views/filter_screen.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../../core/util/safe_state_mixin.dart';
import '../../../../../../core/util/attendance_classroom_scope.dart';
import '../../../../../../domain/features/communication/entities/enums.dart';
import '../../../../classroom/views/filters/designation_display_utils.dart';
import '../../../../students/cubit/student_cubit.dart';
import '../../../cubit/communication_state.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/participant_mapper.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/messaging_shimmer.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../widgets/messaging_list_tile.dart';

class StaffMessagingTab extends StatefulWidget {
  const StaffMessagingTab({super.key, this.isStaffMessaging = true});
  final bool isStaffMessaging;

  static const String routeName = '/staffMessagingTab';

  @override
  State<StaffMessagingTab> createState() => _StaffMessagingTabState();
}

class _StaffMessagingTabState extends State<StaffMessagingTab>
    with AutomaticKeepAliveClientMixin, SafeStateMixin {
  final TextEditingController _searchController = TextEditingController();
  // Defaults to Active — the list only shows active contacts unless the
  // user explicitly picks a different status via the filter sheet. Stored
  // in the same Title Case as the filter sheet's own item strings (see
  // the `Status` FilerSection's `items: const ['Active', 'Upcoming',
  // 'Inactive']` below).
  /// Contact filter/search view-state (Mandate 2/5, Bucket A → cubit).
  final ContactFilterCubit _contactFilter = ContactFilterCubit();

  /// True once the user has explicitly touched the Classroom filter
  /// themselves (via the filter sheet's Apply, or Clear All) — at that
  /// point [_applyDefaultClassroomFilter] must never silently overwrite
  /// their choice on a routine refresh. A logic guard, not UI-rebuild state,
  /// so it stays a plain field.
  bool _classroomFilterUserSet = false;
  static const int _conversationPageSize = 50;

  /// Drives the inbox's "load more" — fetches the next page once the user
  /// scrolls within this many pixels of the end, instead of capping the
  /// list at whatever the first fixed-size fetch returned.
  final ScrollController _conversationScrollController = ScrollController();
  static const double _loadMoreScrollThreshold = 300.0;

  /// Fires after a background bulk-send job completes, so the new conversation
  /// appears without requiring a manual pull-to-refresh.
  StreamSubscription<String>? _conversationListChangedSub;

  // Identity (currentUserCode = staff code STF_…, currentAccountCode =
  // canonical USR-… userCode) now lives on [_contactFilter]'s state.

  Future<void> _loadCurrentUserCode() async {
    // Read identity through the ambient cubit (Mandate 5: no StorageService in
    // views) — same underlying storage reads.
    final cubit = context.read<CommunicationCubit>();
    final staffCode = (await cubit.readStaffCode() ?? '').trim();
    final userCode = (await cubit.readCurrentUserCode() ?? '').trim();
    final code = staffCode.isNotEmpty ? staffCode : userCode;
    if (!mounted || (code.isEmpty && userCode.isEmpty)) return;
    _contactFilter.setIdentity(
      userCode: code.isNotEmpty ? code : null,
      accountCode: userCode.isNotEmpty ? userCode : null,
    );
  }

  /// Backend designation codes (matches staff_filter_screen.dart) used to turn
  /// the Designation filter's human-readable selections back into API values.
  static const List<String> _designationCodes = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
    'KIOSK_USER',
  ];

  Map<String, String> get _designationLabelToCode => {
    for (final code in _designationCodes)
      formatDesignationForDisplay(code): code,
  };

  String get _conversationType =>
      widget.isStaffMessaging ? 'STAFF_DIRECT' : 'ROOM_CHAT';

  @override
  bool get wantKeepAlive => true;

  /// Independently fetches EVERY conversation of this type — no status/
  /// classroom/tag filters — purely to know who already has a
  /// conversation. `CommunicationCubit`'s own conversation list can't be
  /// used for this: applying e.g. "Status: Inactive" narrows its single
  /// shared `conversationsByType[type]` slot down to inactive-only
  /// results (see `_resolvedFilterParams`/`loadConversations`), which
  /// would wrongly stop excluding anyone with an ACTIVE-status
  /// conversation from "Start New Chat" the moment that filter is picked.
  Future<void> _loadContactExclusionSet() async {
    final result = await context.read<CommunicationCubit>()
        .fetchConversationsPage(type: _conversationType, size: 500);
    if (!mounted) return;
    result.fold((_) {}, (page) {
      if (widget.isStaffMessaging) {
        _contactFilter.setStaffContactCodes(
          page.items
              .expand((c) => c.participants)
              .map((p) => p.userCode)
              .toSet(),
        );
      } else {
        _contactFilter.setStudentContactNames(
          page.items.map((c) => c.title.trim().toLowerCase()).toSet(),
        );
      }
    });
  }

  Future<void> _loadTagNameCodeMap() async {
    // School code + tag map via the ambient cubit (Mandate 5) — same underlying
    // storage read and use-case call.
    final cubit = context.read<CommunicationCubit>();
    final schoolCode = await cubit.readActiveSchoolCode() ?? '';
    if (schoolCode.isEmpty) return;
    final map = await cubit.loadSchoolTagNameCodeMap(schoolCode);
    if (!mounted) return;
    _contactFilter.setTagNameToCode(map);
  }

  /// Maps a single-select Status filter selection ('Active'/'Upcoming') to
  /// the backend enum value, or null when nothing is selected.
  String? _mapStatusToApi(List<String>? selected) {
    if (selected == null || selected.isEmpty) return null;
    return selected.first.trim().toUpperCase();
  }

  /// Keeps fetching subsequent pages until the whole roster is loaded.
  /// [StaffCubit]/[StudentCubit] default to a small page size sized for
  /// their own scroll-paginated directory screens — the "Start new chat"
  /// section here has no scroll-triggered "load more" of its own, so
  /// without this only the first page or two ever showed regardless of how
  /// many staff/students actually matched the active filter.
  Future<void> _drainStaffPages() async {
    final cubit = context.read<StaffCubit>();
    while (mounted && cubit.state.hasMore && !cubit.state.isLoadingMore) {
      await cubit.loadNextPage();
    }
  }

  Future<void> _drainStudentPages() async {
    final cubit = context.read<StudentCubit>();
    while (mounted && cubit.state.hasMore && !cubit.state.isLoadingMore) {
      await cubit.loadNextPage();
    }
  }

  /// Maps selected classroom names to their backend codes via ClassroomCubit.
  /// Always returns a (possibly empty) list so callers can use it directly to
  /// clear the filter when nothing is selected.
  List<String> _mapClassroomNamesToCodes(List<String>? names) {
    if (names == null || names.isEmpty) return const [];
    final classrooms = context.read<ClassroomCubit>().state.classrooms;
    final nameToCode = {for (final c in classrooms) c.name: c.code};
    return names.map((n) => nameToCode[n]).whereType<String>().toList();
  }

  /// The staff/staff API only accepts a single designation value, but the
  /// filter UI is multi-select — only the first selection is sent.
  String? _mapDesignationToApi(List<String>? selectedLabels) {
    if (selectedLabels == null || selectedLabels.isEmpty) return null;
    return _designationLabelToCode[selectedLabels.first];
  }

  List<String> _mapTagsToCodes(List<String>? names) {
    if (names == null || names.isEmpty) return const [];
    return names
        .map((n) => _contactFilter.state.tagNameToCode[n])
        .whereType<String>()
        .toList();
  }

  /// Resolves [_contactFilter.state.currentFilters] into the codes/values
  /// `CommunicationCubit.loadConversations` sends straight through to the
  /// backend's getConversationsByType query params — this is what actually
  /// narrows the conversation list now, instead of the old approach of
  /// fetching everything and intersecting client-side against a separately-
  /// filtered staff/student roster (which never touched the conversations
  /// endpoint itself).
  ({
    List<String> classroomCodes,
    List<String> tagCodes,
    List<String> designations,
    List<String> studentStatuses,
    List<String> staffStatuses,
    String conversationStatus,
  })
  _resolvedFilterParams() {
    final status = _mapStatusToApi(
      _contactFilter.state.currentFilters['Status'],
    );
    final designation = _mapDesignationToApi(
      _contactFilter.state.currentFilters['Designation'],
    );
    // STAFF_DIRECT only: ACTIVE/INACTIVE are carried entirely by the
    // conversation-level `status` param below — sending staffStatuses
    // alongside it returns EMPTY results (confirmed:
    // status=INACTIVE&staffStatuses=INACTIVE → nothing; status=INACTIVE
    // alone → 200 with the expected conversations). Only 'UPCOMING' (which
    // has no conversation-level equivalent) still needs the separate
    // param. Room Chat (studentStatuses) is unaffected — it keeps sending
    // the picked status as-is, same as before.
    final staffNeedsSeparateStatusParam = status == 'UPCOMING';
    return (
      classroomCodes: _mapClassroomNamesToCodes(
        _contactFilter.state.currentFilters['Classroom'],
      ),
      tagCodes: widget.isStaffMessaging
          ? const []
          : _mapTagsToCodes(_contactFilter.state.currentFilters['Tags']),
      designations: widget.isStaffMessaging && designation != null
          ? [designation]
          : const [],
      studentStatuses: !widget.isStaffMessaging && status != null
          ? [status]
          : const [],
      // The conversation's OWN top-level `status` — STAFF_DIRECT only;
      // only ACTIVE/INACTIVE are valid values here, and 'UPCOMING' stays
      // 'ACTIVE' (narrowed via staffStatuses instead). Room Chat keeps the
      // original hardcoded 'ACTIVE' (see CommunicationCubit.loadConversations's
      // own default) since this fix was confirmed for STAFF_DIRECT only.
      conversationStatus: widget.isStaffMessaging
          ? (status == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE')
          : 'ACTIVE',
      staffStatuses: widget.isStaffMessaging && staffNeedsSeparateStatusParam
          ? [status!]
          : const [],
    );
  }

  /// True when any Classroom/Status/Designation/Tags filter is actively
  /// selected (ignores the 'Unread' toggle, which doesn't drive these
  /// lists, and the silent default `Status: Active` — [_contactFilter.state.currentFilters]
  /// always carries that even when the user hasn't touched the filter
  /// sheet, so it must not count as a user-applied filter here).
  bool get _hasActiveContactFilters =>
      _contactFilter.state.currentFilters.entries.any((e) {
        if (e.key == 'Unread') return false;
        if (e.key == 'Status' &&
            e.value.length == 1 &&
            e.value.first == 'Active') {
          return false;
        }
        return e.value.isNotEmpty;
      });

  bool get _hasSearchQuery => _searchController.text.trim().isNotEmpty;

  /// True whenever the "Start new chat" section should be considered at
  /// all — either an explicit filter is applied, or the user is searching.
  /// Searching for someone who has no conversation yet should surface them
  /// here instead of just coming up empty. Without a filter/search, this
  /// stays hidden on both tabs so the inbox isn't cluttered with every
  /// contact that doesn't have a conversation yet.
  bool get _shouldShowStartNewChat =>
      _hasActiveContactFilters || _hasSearchQuery;

  /// Human-readable "Classroom: X  •  Status: Y" summary of the active
  /// filters, shown above the conversation list as a title when non-empty.
  /// Excludes the silent default `Status: Active` for the same reason as
  /// [_hasActiveContactFilters].
  String get _activeFiltersSummary => _contactFilter
      .state
      .currentFilters
      .entries
      .where((e) {
        if (e.key == 'Unread' || e.value.isEmpty) return false;
        if (e.key == 'Status' &&
            e.value.length == 1 &&
            e.value.first == 'Active') {
          return false;
        }
        return true;
      })
      .map((e) => '${e.key}: ${e.value.join(', ')}')
      .join('   •   ');

  /// Codes currently being created/opened — guards against a double-tap on
  /// the same contact firing two create requests while the first is still
  /// in flight.
  final Set<String> _startingConversationWith = {};

  /// Creates (or finds) a conversation with [code] and opens it directly —
  /// so picking a filtered contact behaves like starting a real chat, not
  /// just a silent refresh the user then has to find and tap again. Runs as
  /// a background request: shows a brief "Creating…" notice, then either a
  /// success notice (and opens the thread) or a failure notice — matches
  /// across the Staff and Parent tabs since both go through this one path.
  Future<void> _startConversationWith(
    String code,
    String name, {
    String classroomCode = '',
  }) async {
    if (_contactFilter.state.currentUserCode != null &&
        code == _contactFilter.state.currentUserCode) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'You can\'t start a conversation with yourself',
        isWarning: true,
      );
      return;
    }
    if (_startingConversationWith.contains(code)) return;
    _startingConversationWith.add(code);

    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Creating conversation with $name…',
    );

    final result = await context.read<CommunicationCubit>()
        .createOrOpenConversation(
          type: widget.isStaffMessaging
              ? ConversationType.staffDirect
              : ConversationType.roomChat,
          studentCode: widget.isStaffMessaging ? '' : code,
          classroomCode: widget.isStaffMessaging ? null : classroomCode,
          participantCodes: widget.isStaffMessaging ? [code] : const [],
          title: name,
        );
    _startingConversationWith.remove(code);
    if (!mounted) return;
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation == null) {
      final failureMessage = result.fold((f) => f.message, (_) => null);
      CoreUtils.showTopSnackBar(
        context: context,
        message: (failureMessage != null && failureMessage.trim().isNotEmpty)
            ? failureMessage
            : 'Could not start a conversation with $name',
        isError: true,
      );
      return;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Chat with $name created successfully',
      isSuccess: true,
    );
    unawaited(_loadContactExclusionSet());
    _openThread(
      // [name] is the counterpart the creator explicitly picked, so it is the
      // correct 1:1 label from this side — use it rather than the stored title.
      name: name,
      avatar: conversation.avatarUrl,
      code: conversation.code,
      participants: legacyParticipantsFromEntities(conversation.participants),
      organizationCode: conversation.organizationCode,
      schoolCode: conversation.schoolCode,
      privateModeActive: conversation.privateModeActive,
      privateModeActivatedBy: conversation.privateModeActivatedBy,
      studentStatus: conversation.studentStatus,
    );
  }

  void _applyFilters() {
    // The list re-filters via the ContactFilterCubit BlocBuilder + the search
    // controller ListenableBuilder in build(); no manual setState needed. Kept
    // as the shared "filters changed" hook its callers already reference.
  }

  /// Rapid search: hits the staff/student list API on every keystroke (no
  /// debounce) — mirrors StaffScreen/StudentScreen's own search bars, which
  /// use the same `searchStaff`/`updateSearch`+`refresh` pattern. Without
  /// this, "Start new chat" only ever filtered whatever page `loadInitial()`
  /// happened to load, so searching for someone outside that first page
  /// silently found nothing and never queried the backend at all.
  void _onSearchTextChanged() {
    _applyFilters();
    final query = _searchController.text.trim();
    if (widget.isStaffMessaging) {
      context.read<StaffCubit>().searchStaff(query);
    } else {
      context.read<StudentCubit>().updateSearch(query);
      context.read<StudentCubit>().refresh(ignoreRefreshingGuard: true);
    }
    _searchConversations(query);
  }

  /// Existing conversations matching the current search text, sourced from
  /// the server (`GET /conversations/search?q=...`) rather than filtering
  /// only whatever page of conversations happens to already be loaded
  /// client-side — a query can match a conversation that hasn't been
  /// fetched into [CommunicationCubit]'s state yet. (Now on
  /// [_contactFilter]'s state.)
  ///
  /// Guards against an older, slower keystroke's response overwriting a
  /// newer one's — only the response matching [_searchController]'s CURRENT
  /// text at completion time is applied.
  int _searchRequestToken = 0;

  Future<void> _searchConversations(String query) async {
    final token = ++_searchRequestToken;
    if (query.isEmpty) {
      if (mounted) _contactFilter.setSearchResults(null);
      return;
    }
    final result = await context.read<CommunicationCubit>().searchConversations(
      query: query,
      type: _conversationType,
    );
    if (!mounted || token != _searchRequestToken) return;
    result.fold(
      (_) {}, // Keep showing the previous (or empty) results on failure.
      (conversations) => _contactFilter.setSearchResults(conversations),
    );
  }

  void _clearAllFilters() {
    // Resets to Active-only (not "show everyone"), unread off, search cleared.
    _contactFilter.clearFilters();
    // Explicit user action — must never be silently re-defaulted back to the
    // primary classroom by a later refresh (see [_applyDefaultClassroomFilter]).
    _classroomFilterUserSet = true;
    _searchController.clear();
    _searchRequestToken++;
    if (!mounted) return;
    _applyFilters();
    if (widget.isStaffMessaging) {
      context.read<StaffCubit>().updateFilters(
        status: 'ACTIVE',
        designation: null,
        classCodes: const [],
      );
      unawaited(
        context
            .read<StaffCubit>()
            .refresh(ignoreRefreshingGuard: true)
            .then((_) => _drainStaffPages()),
      );
    } else {
      context.read<StudentCubit>().updateFilters(
        status: 'ACTIVE',
        classroomCodes: const [],
        tagCodes: const [],
      );
      unawaited(
        context.read<StudentCubit>().refreshWithCacheReset().then(
          (_) => _drainStudentPages(),
        ),
      );
    }
    final clearedFilters = _resolvedFilterParams();
    unawaited(
      context.read<CommunicationCubit>().loadConversations(
        type: _conversationType,
        size: _conversationPageSize,
        status: clearedFilters.conversationStatus,
      ),
    );
  }

  /// Room Chat only: default the Classroom filter to the staff member's own
  /// primary classroom — same "pre-select the home classroom" pattern the
  /// attendance forms use ([resolveStaffPrimaryClassroomCode]), so "chats
  /// overview" and "Start new chat" both open already scoped instead of
  /// showing every classroom until the user filters manually. Resolves to
  /// no default for admin/parent personas or a staff member with no
  /// primary classroom set.
  ///
  /// [forceRefresh] bypasses the cached classroom list and cached staff
  /// profile — pass true from an explicit refresh (pull-to-refresh, the
  /// refresh icon). Without this, a staff member an admin just moved to a
  /// different classroom kept seeing their OLD classroom here no matter how
  /// many times they refreshed: neither [ClassroomCubit]'s classroom list
  /// nor the staff profile backing this resolution ever refetch on their
  /// own — only a full app kill (which drops [ClassroomCubit]'s in-memory
  /// "already loaded" state) had any chance of picking up the change, and
  /// even then only once the staff-profile disk cache's own TTL had lapsed.
  ///
  /// No-ops once [_classroomFilterUserSet] is true — an explicit filter
  /// pick (or Clear All) is the user taking manual control, and a routine
  /// refresh must never silently overwrite that.
  Future<void> _applyDefaultClassroomFilter({bool forceRefresh = false}) async {
    if (widget.isStaffMessaging || _classroomFilterUserSet) return;

    await context.read<ClassroomCubit>().loadActiveClassrooms(
      applyAttendanceStaffScope: true,
      force: forceRefresh,
    );
    if (!mounted || _classroomFilterUserSet) return;

    final primaryCode = await resolveStaffPrimaryClassroom(
      forceRefresh: forceRefresh,
    );
    if (!mounted ||
        _classroomFilterUserSet ||
        (primaryCode ?? '').trim().isEmpty) {
      return;
    }

    final primaryName = context
        .read<ClassroomCubit>()
        .state
        .classrooms
        .where((c) => c.code.trim() == primaryCode!.trim())
        .map((c) => c.name)
        .firstOrNull;
    if (primaryName == null || primaryName.trim().isEmpty) return;

    final current = _contactFilter.state.currentFilters['Classroom'];
    if (current != null &&
        current.length == 1 &&
        current.first == primaryName) {
      return;
    }

    _contactFilter.setDefaultClassroom(primaryName);
  }

  /// Explicit refresh (pull-to-refresh, the refresh icon): re-syncs the
  /// Room Chat default classroom against the server (see
  /// [_applyDefaultClassroomFilter]'s doc for why this needs to force-bypass
  /// caches, unlike a routine rebuild), re-scopes the "Start New Chat"
  /// student roster to match, then reloads the conversation list — all
  /// three previously only ever reflected whatever classroom was resolved
  /// once at mount.
  Future<void> _refreshConversationsAndClassroomDefault() async {
    if (!mounted) return;
    await _applyDefaultClassroomFilter(forceRefresh: true);
    if (!mounted) return;
    if (!widget.isStaffMessaging) {
      context.read<StudentCubit>().updateFilters(
        classroomCodes: _mapClassroomNamesToCodes(
          _contactFilter.state.currentFilters['Classroom'],
        ),
      );
      unawaited(
        context.read<StudentCubit>().refreshWithCacheReset().then(
          (_) => _drainStudentPages(),
        ),
      );
    }
    final f = _resolvedFilterParams();
    await context.read<CommunicationCubit>().loadConversations(
      type: _conversationType,
      size: _conversationPageSize,
      status: f.conversationStatus,
      classroomCodes: f.classroomCodes,
      tagCodes: f.tagCodes,
      designations: f.designations,
      studentStatuses: f.studentStatuses,
      staffStatuses: f.staffStatuses,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Non-admin staff only see the classrooms they're allowed to
        // access; admins see every active classroom. Awaited (unlike
        // before) because Room Chat's primary-classroom default below
        // needs the classroom list to resolve a name for the filter chip.
        await context.read<ClassroomCubit>().loadActiveClassrooms(
          applyAttendanceStaffScope: true,
        );
        if (!mounted) return;

        // Room Chat: default the Classroom filter to the staff member's own
        // primary classroom. See [_applyDefaultClassroomFilter]'s own doc.
        await _applyDefaultClassroomFilter();
        if (!mounted) return;

        // Seed the Active default (matches [_contactFilter.state.currentFilters]) BEFORE the
        // initial load, so "Start New Chat" doesn't briefly (or
        // permanently, since nothing else ever sets this) show
        // inactive/upcoming contacts.
        context.read<StaffCubit>().updateFilters(status: 'ACTIVE');
        unawaited(
          context.read<StaffCubit>().loadInitial().then(
            (_) => _drainStaffPages(),
          ),
        );
        context.read<StudentCubit>().updateFilters(
          status: 'ACTIVE',
          classroomCodes: _mapClassroomNamesToCodes(
            _contactFilter.state.currentFilters['Classroom'],
          ),
        );
        unawaited(
          context.read<StudentCubit>().loadInitial().then(
            (_) => _drainStudentPages(),
          ),
        );
        unawaited(_loadCurrentUserCode());
        unawaited(_loadContactExclusionSet());
        if (!widget.isStaffMessaging) {
          unawaited(_loadTagNameCodeMap());
        }
        // `status` (the conversation's own ACTIVE/INACTIVE state, not
        // studentStatuses/staffStatuses) is what actually gates whether a
        // conversation is returned at all — confirmed via
        // GET .../conversations/type/STAFF_DIRECT?status=INACTIVE.
        // classroomCodes is included too (was previously omitted here,
        // silently unscoped until the user manually touched the filter
        // sheet or pulled to refresh) so the primary-classroom default
        // above actually takes effect on the very first load.
        final initialFilters = _resolvedFilterParams();
        await context.read<CommunicationCubit>().loadConversations(
          type: _conversationType,
          size: _conversationPageSize,
          status: initialFilters.conversationStatus,
          classroomCodes: initialFilters.classroomCodes,
        );
        if (!mounted) return;
        // Realtime listener starts only after the API/Isar history has
        // loaded — Firestore only ever applies deltas on top of it.
        context.read<CommunicationCubit>().startWatchingConversations(
          type: _conversationType,
        );
      }
    });

    _searchController.addListener(_onSearchTextChanged);
    _conversationScrollController.addListener(_onConversationScroll);

    // Reload the conversation list when the background bulk-send job finishes.
    // The job runs fire-and-forget after the compose screen is dismissed, so
    // refreshConversations() in MessagingTab fires before the job completes.
    // This subscription catches the job-done signal and does the real refresh.
    _conversationListChangedSub = MessagingEventService
        .instance
        .onConversationListChanged
        .listen((changedType) {
          if (!mounted) return;
          if (changedType != _conversationType) return;
          final f = _resolvedFilterParams();
          context.read<CommunicationCubit>().loadConversations(
            type: _conversationType,
            size: _conversationPageSize,
            status: f.conversationStatus,
            classroomCodes: f.classroomCodes,
            tagCodes: f.tagCodes,
            designations: f.designations,
            studentStatuses: f.studentStatuses,
            staffStatuses: f.staffStatuses,
          );
        });
  }

  void _onConversationScroll() {
    if (!_conversationScrollController.hasClients) return;
    final position = _conversationScrollController.position;
    if (position.maxScrollExtent - position.pixels > _loadMoreScrollThreshold) {
      return;
    }
    final f = _resolvedFilterParams();
    context.read<CommunicationCubit>().loadMoreConversations(
      type: _conversationType,
      size: _conversationPageSize,
      classroomCodes: f.classroomCodes,
      tagCodes: f.tagCodes,
      designations: f.designations,
      studentStatuses: f.studentStatuses,
      staffStatuses: f.staffStatuses,
    );
  }

  @override
  void dispose() {
    _conversationListChangedSub?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _conversationScrollController.removeListener(_onConversationScroll);
    _conversationScrollController.dispose();
    unawaited(_contactFilter.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Rebuild the tab on the contact-filter cubit + search text.
    return BlocBuilder<ContactFilterCubit, ContactFilterState>(
      bloc: _contactFilter,
      builder: (context, _) => ListenableBuilder(
        listenable: _searchController,
        builder: (context, __) => CustomRefreshIndicator(
          onRefresh: _refreshConversationsAndClassroomDefault,
          child: CustomScrollView(
            controller: _conversationScrollController,
            // Short/empty lists don't fill the viewport, and without this a
            // CustomScrollView with unfilled content isn't scrollable at all —
            // so the pull-to-refresh gesture never registers. The manual
            // refresh button above was a workaround for exactly this; this
            // makes the pull gesture itself work regardless of list length.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: const SizedBox(height: 15)),
              // search bar and filter icon as well as clear all button and unread messages toggle
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.messagingSearchFieldBg,
                            ),
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: widget.isStaffMessaging
                                  ? AppStrings.searchStaff
                                  : AppStrings.searchStudent,
                              searchBarColor: WidgetStatePropertyAll(
                                AppColors.transparentColor,
                              ),
                              borderColor: AppColors.transparentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        // Discoverable manual refresh — mirrors the pull-to-refresh
                        // (loadConversations) so users aren't limited to the pull gesture,
                        // which isn't obvious and can't be triggered on a short/empty list.
                        Material(
                          color: AppColors.transparentColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              unawaited(
                                _refreshConversationsAndClassroomDefault(),
                              );
                              CoreUtils.showTopSnackBar(
                                context: context,
                                message: 'Refreshing conversations…',
                                duration: const Duration(milliseconds: 1200),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSizes.xsPlus),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.messagingSearchFieldBg,
                              ),
                              child: Icon(
                                Icons.refresh,
                                color: AppColors.primaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Material(
                          color: AppColors.transparentColor,
                          child: InkWell(
                            onTap: () async {
                              final classroomNames = context
                                  .read<ClassroomCubit>()
                                  .state
                                  .classrooms
                                  .map((e) => e.name)
                                  .toList();

                              await context.push(
                                CommunicationRoutes.filter,
                                extra: widget.isStaffMessaging
                                    ? MessagingFilterArgs(
                                        sections: [
                                          FilerSection(
                                            label: 'Classroom',
                                            hintText: AppStrings.selectClassroomHint,
                                            items: classroomNames,
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Classroom'] ??
                                                [],
                                            isMultiSelectDropDown: true,
                                          ),
                                          FilerSection(
                                            label: 'Designation',
                                            hintText: AppStrings.selectDesignationHint,
                                            items:
                                                _designationLabelToCode.keys
                                                    .toList()
                                                  ..sort(),
                                            isMultiSelectDropDown: true,
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Designation'] ??
                                                [],
                                          ),
                                          FilerSection(
                                            label: 'Status',
                                            hintText: AppStrings.selectStatusHint,
                                            items: const [
                                              'Active',
                                              'Upcoming',
                                              'Inactive',
                                            ],
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Status'] ??
                                                [],
                                            isSingleSelect: true,
                                          ),
                                        ],
                                        onApply: (filters) {
                                          if (!mounted) return;
                                          _contactFilter.setFilters(filters);
                                          // Explicit user action — see
                                          // [_applyDefaultClassroomFilter].
                                          _classroomFilterUserSet = true;
                                          _applyFilters();
                                          context
                                              .read<StaffCubit>()
                                              .updateFilters(
                                                status: _mapStatusToApi(
                                                  filters['Status'],
                                                ),
                                                designation:
                                                    _mapDesignationToApi(
                                                      filters['Designation'],
                                                    ),
                                                classCodes:
                                                    _mapClassroomNamesToCodes(
                                                      filters['Classroom'],
                                                    ),
                                              );
                                          unawaited(
                                            context
                                                .read<StaffCubit>()
                                                .refresh(
                                                  ignoreRefreshingGuard: true,
                                                )
                                                .then(
                                                  (_) => _drainStaffPages(),
                                                ),
                                          );
                                          // Narrow the conversation list itself
                                          // server-side, not just the "Start new
                                          // chat" staff roster above.
                                          final f = _resolvedFilterParams();
                                          unawaited(
                                            context
                                                .read<CommunicationCubit>()
                                                .loadConversations(
                                                  type: _conversationType,
                                                  size: _conversationPageSize,
                                                  status: f.conversationStatus,
                                                  classroomCodes:
                                                      f.classroomCodes,
                                                  designations: f.designations,
                                                  staffStatuses:
                                                      f.staffStatuses,
                                                ),
                                          );
                                        },
                                      )
                                    : MessagingFilterArgs(
                                        sections: [
                                          FilerSection(
                                            label: 'Classroom',
                                            hintText: AppStrings.selectClassroomHint,
                                            items: classroomNames,
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Classroom'] ??
                                                [],
                                            isMultiSelectDropDown: true,
                                          ),
                                          FilerSection(
                                            label: 'Status',
                                            hintText: AppStrings.selectStatusHint,
                                            items: const [
                                              'Active',
                                              'Upcoming',
                                              'Inactive',
                                            ],
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Status'] ??
                                                [],
                                            isSingleSelect: true,
                                          ),
                                          FilerSection(
                                            label: 'Tags',
                                            hintText: AppStrings.selectTagsHint,
                                            items:
                                                _contactFilter
                                                    .state
                                                    .tagNameToCode
                                                    .keys
                                                    .toList()
                                                  ..sort(),
                                            initialSelected:
                                                _contactFilter
                                                    .state
                                                    .currentFilters['Tags'] ??
                                                [],
                                            isMultiSelectDropDown: true,
                                          ),
                                        ],
                                        onApply: (filters) {
                                          if (!mounted) return;
                                          _contactFilter.setFilters(filters);
                                          // Explicit user action — see
                                          // [_applyDefaultClassroomFilter].
                                          _classroomFilterUserSet = true;
                                          _applyFilters();
                                          context
                                              .read<StudentCubit>()
                                              .updateFilters(
                                                status: _mapStatusToApi(
                                                  filters['Status'],
                                                ),
                                                classroomCodes:
                                                    _mapClassroomNamesToCodes(
                                                      filters['Classroom'],
                                                    ),
                                                tagCodes: _mapTagsToCodes(
                                                  filters['Tags'],
                                                ),
                                              );
                                          unawaited(
                                            context
                                                .read<StudentCubit>()
                                                .refreshWithCacheReset()
                                                .then(
                                                  (_) => _drainStudentPages(),
                                                ),
                                          );
                                          // Narrow the conversation list itself
                                          // server-side, not just the "Start new
                                          // chat" student roster above — this is
                                          // the actual conversation-list Tags
                                          // filter fix.
                                          final f = _resolvedFilterParams();
                                          unawaited(
                                            context
                                                .read<CommunicationCubit>()
                                                .loadConversations(
                                                  type: _conversationType,
                                                  size: _conversationPageSize,
                                                  status: f.conversationStatus,
                                                  classroomCodes:
                                                      f.classroomCodes,
                                                  tagCodes: f.tagCodes,
                                                  studentStatuses:
                                                      f.studentStatuses,
                                                ),
                                          );
                                        },
                                      ),
                              );
                              if (!mounted) return;
                              // The filter sheet's onApply already pushed the new
                              // filters to _contactFilter (which rebuilds the list);
                              // no extra setState needed here.
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.xs),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                  if (_hasActiveContactFilters)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.messagingNotificationDot,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xsPlus),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: CustomToggle(
                            label: AppStrings.showOnlyUnread,
                            isToggled: _contactFilter.state.showUnread,
                            onToggle: (v) {
                              _contactFilter.setShowUnread(v);
                              _applyFilters();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: CustomClearAllChip(
                            onTap: () {
                              _clearAllFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(child: const SizedBox(height: 15)),

              if (_hasActiveContactFilters)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.xs),
                    child: Text(
                      _activeFiltersSummary,
                      style: AppTextStyles.size14.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.messagingHeadingPlum,
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: const SizedBox(height: 15)),

              BlocBuilder<StaffCubit, StaffState>(
                builder: (context, staffState) {
                  return BlocBuilder<StudentCubit, StudentState>(
                    builder: (context, studentState) {
                      return BlocBuilder<
                        CommunicationCubit,
                        CommunicationState
                      >(
                        builder: (context, communicationState) {
                          if (communicationState
                              is CommunicationConversationsLoading) {
                            return const MessagingShimmer();
                          }

                          if (communicationState is CommunicationError) {
                            return SliverFillRemaining(
                              child: Center(
                                child: Text(communicationState.message),
                              ),
                            );
                          }

                          List<Conversation> conversationsToDisplay = [];
                          // Who already has a conversation — from the
                          // independently-fetched, always-unfiltered
                          // [_contactFilter.state.allContactCodes]/[_contactFilter.state.allContactNames], NOT from
                          // `communicationState`'s (possibly Status/Classroom/
                          // Tag-filtered) list. See [_loadContactExclusionSet].
                          final existingContactCodes = widget.isStaffMessaging
                              ? _contactFilter.state.allContactCodes
                              : const <String>{};
                          final existingContactNames = widget.isStaffMessaging
                              ? const <String>{}
                              : _contactFilter.state.allContactNames;
                          final query = _searchController.text
                              .trim()
                              .toLowerCase();

                          if (communicationState
                              is CommunicationConversationsLoaded) {
                            // Classroom/Designation/Status/Tags filtering happens
                            // server-side now (CommunicationCubit.loadConversations
                            // sends classroomCodes/tagCodes/designations/
                            // studentStatuses/staffStatuses straight through to
                            // the backend, see _resolvedFilterParams) — the
                            // conversations below are already the filtered set.
                            // No client-side cross-referencing against
                            // StaffCubit/StudentCubit's separately-filtered
                            // roster needed (or wanted: that roster is its own
                            // page and could disagree with the real, complete
                            // server-side filtered result).
                            final allConversationsForType = communicationState
                                .getConversations(_conversationType);

                            // Once the server search for the current query has
                            // resolved, search the account's full conversation
                            // history instead of only what's already loaded
                            // locally — a match may not be among the
                            // (recency-ordered) conversations fetched so far.
                            // Falls back to filtering the local list by title
                            // while that request is still in flight.
                            final conversationsBaseList =
                                (query.isNotEmpty &&
                                    _contactFilter.state.serverSearchResults !=
                                        null)
                                ? _contactFilter.state.serverSearchResults!
                                : allConversationsForType;

                            // Enforced client-side, not just via the server-
                            // side status/studentStatuses/staffStatuses query
                            // params in _resolvedFilterParams — this screen's
                            // Firestore subscription (startWatchingConversations)
                            // keeps pushing updates on top of the loaded list,
                            // so without this the next realtime snapshot could
                            // silently undo whichever status was picked.
                            // Defaults to 'ACTIVE'.
                            final statusFilter =
                                _mapStatusToApi(
                                  _contactFilter.state.currentFilters['Status'],
                                ) ??
                                'ACTIVE';
                            // Room Chat only — STAFF_DIRECT conversations never
                            // carry a classroomCode (that tab's Classroom filter
                            // narrows by the counterpart staff's own classroom
                            // assignment instead, purely server-side via
                            // StaffCubit/loadConversations), so re-checking it
                            // here would wrongly hide every Staff Direct
                            // conversation once that filter is active. Same
                            // "re-check client-side" reasoning as statusFilter
                            // above: the classroomCodes query param only narrows
                            // the initial REST fetch — startWatchingConversations'
                            // Firestore merge keeps adding/updating every ROOM_CHAT
                            // conversation in the user's own inbox regardless of
                            // classroom, so without this the list silently
                            // reverted to unfiltered moments after the classroom
                            // filter (including the default primary-classroom
                            // one) was applied.
                            final classroomFilterCodes =
                                !widget.isStaffMessaging
                                ? _mapClassroomNamesToCodes(
                                    _contactFilter
                                        .state
                                        .currentFilters['Classroom'],
                                  )
                                : const <String>[];
                            conversationsToDisplay = conversationsBaseList.where((
                              conv,
                            ) {
                              if (query.isNotEmpty &&
                                  !conv.title.toLowerCase().contains(query)) {
                                return false;
                              }
                              if (_contactFilter.state.showUnread &&
                                  conv.unreadCount == 0)
                                return false;
                              if (classroomFilterCodes.isNotEmpty &&
                                  !classroomFilterCodes.contains(
                                    conv.classroomCode?.trim(),
                                  )) {
                                return false;
                              }
                              if (widget.isStaffMessaging) {
                                if (statusFilter == 'ACTIVE' ||
                                    statusFilter == 'INACTIVE') {
                                  // The conversation's own top-level `status`
                                  // is the reliable, always-present signal
                                  // for these two states — confirmed via
                                  // GET .../conversations/type/STAFF_DIRECT
                                  // ?status=INACTIVE returning conversations
                                  // the per-participant check alone was
                                  // wrongly hiding.
                                  if (conv.status.trim().toUpperCase() !=
                                      statusFilter) {
                                    return false;
                                  }
                                } else {
                                  // 'UPCOMING' has no conversation-level
                                  // equivalent — fall back to the
                                  // counterpart's own employment status.
                                  // Fails OPEN when that field itself is
                                  // missing (null); only a known non-matching
                                  // status hides.
                                  final counterpart = conv.participants
                                      .where(
                                        (p) =>
                                            p.userCode !=
                                            _contactFilter
                                                .state
                                                .currentAccountCode,
                                      )
                                      .firstOrNull;
                                  final staffStatus = counterpart?.staffStatus
                                      ?.trim()
                                      .toUpperCase();
                                  if (staffStatus != null &&
                                      staffStatus != statusFilter) {
                                    return false;
                                  }
                                }
                              } else {
                                // Room Chat — unchanged, matches studentStatus
                                // directly regardless of which status value is
                                // picked (this fix was confirmed for
                                // STAFF_DIRECT only).
                                final studentStatus = conv.studentStatus
                                    ?.trim()
                                    .toUpperCase();
                                if (studentStatus != null &&
                                    studentStatus != statusFilter) {
                                  return false;
                                }
                              }
                              // Hide a conversation a user somehow has with only
                              // themselves (no other participant). Participants
                              // are keyed by userCode, so this MUST compare
                              // against the account code — never the staff code.
                              if (_contactFilter.state.currentAccountCode !=
                                      null &&
                                  _contactFilter
                                      .state
                                      .currentAccountCode!
                                      .isNotEmpty &&
                                  conv.participants.isNotEmpty &&
                                  conv.participants.every(
                                    (p) =>
                                        p.userCode ==
                                        _contactFilter.state.currentAccountCode,
                                  )) {
                                return false;
                              }
                              return true;
                            }).toList();
                          }

                          final filteredContacts = (_shouldShowStartNewChat)
                              ? (widget.isStaffMessaging
                                    ? _filteredStaffContacts(
                                        staffState,
                                        query: query,
                                        excludeCodes: existingContactCodes,
                                      )
                                    : _filteredStudentContacts(
                                        studentState,
                                        query: query,
                                        excludeNames: existingContactNames,
                                      ))
                              : const <_FilteredContact>[];

                          // Every sliver below carries a stable Key, and every
                          // list item is keyed by its own stable code rather
                          // than index — this list's shape changes a lot
                          // (load-more appending pages, sort-by-lastMessageAt
                          // reordering on a new message, the "Start new chat"
                          // section appearing/disappearing). Without keys,
                          // Flutter matches old/new children by position, and
                          // a gesture detector (e.g. RefreshIndicator's own)
                          // can get reparented onto a different item mid
                          // rebuild — the exact "_elements.contains(element)"
                          // class of crash.
                          final slivers = <Widget>[];

                          if (conversationsToDisplay.isEmpty &&
                              filteredContacts.isEmpty) {
                            slivers.add(
                              KeyedSubtree(
                                key: const ValueKey('contact_picker'),
                                child: _buildContactPicker(context),
                              ),
                            );
                          } else {
                            if (conversationsToDisplay.isNotEmpty) {
                              slivers.add(
                                SliverList(
                                  key: const ValueKey('conversations_list'),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final conversation =
                                        conversationsToDisplay[index];
                                    return MessagingListTile(
                                      key: ValueKey(
                                        'conversation_${conversation.code}',
                                      ),
                                      conversation: conversation,
                                      currentUserCode: _contactFilter
                                          .state
                                          .currentAccountCode,
                                      onTap: () => _openThread(
                                        name: ConversationDisplay.name(
                                          conversation,
                                          _contactFilter
                                              .state
                                              .currentAccountCode,
                                        ),
                                        avatar: ConversationDisplay.avatar(
                                          conversation,
                                          _contactFilter
                                              .state
                                              .currentAccountCode,
                                        ),
                                        code: conversation.code,
                                        participants: conversation.participants,
                                        organizationCode:
                                            conversation.organizationCode,
                                        schoolCode: conversation.schoolCode,
                                        privateModeActive:
                                            conversation.privateModeActive,
                                        privateModeActivatedBy:
                                            conversation.privateModeActivatedBy,
                                        studentStatus:
                                            conversation.studentStatus,
                                      ),
                                    );
                                  }, childCount: conversationsToDisplay.length),
                                ),
                              );
                              if (communicationState
                                      is CommunicationConversationsLoaded &&
                                  communicationState.getIsLoadingMore(
                                    _conversationType,
                                  )) {
                                slivers.add(
                                  const SliverToBoxAdapter(
                                    key: ValueKey('loading_more_indicator'),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: AppSizes.md,
                                      ),
                                      child: Center(
                                        child: PrimaryCircularLoader(
                                          size: 22,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                            if (filteredContacts.isNotEmpty) {
                              slivers.add(
                                SliverToBoxAdapter(
                                  key: const ValueKey('start_new_chat_header'),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      16,
                                      20,
                                      4,
                                    ),
                                    child: Text(
                                      AppStrings.startNewChat(filteredContacts.length),
                                      style: AppTextStyles.size14.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: AppColors.messagingMutedPurple,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              slivers.add(
                                SliverList(
                                  key: const ValueKey('start_new_chat_list'),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final contact = filteredContacts[index];
                                    return _buildContactRow(
                                      contact,
                                      key: ValueKey('contact_${contact.code}'),
                                    );
                                  }, childCount: filteredContacts.length),
                                ),
                              );
                            }
                          }

                          return SliverMainAxisGroup(slivers: slivers);
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pushes the staff/parent thread screen and refreshes the inbox on return
  /// — shared by tapping an existing conversation tile and by starting a
  /// brand-new conversation from the filtered "Start new chat" list.
  void _openThread({
    required String name,
    required String avatar,
    required String code,
    List<ConversationParticipant> participants = const [],
    String organizationCode = '',
    String schoolCode = '',
    // Conversation-level private mode. The backend tracks private mode on the
    // CONVERSATION (privateModeActive / privateModeActivatedBy), never on
    // participants, so this is the only reliable signal the Parent Messaging
    // thread can use to show per-parent private tabs. Consumed ONLY by the
    // ParentMessagingThread branch below; StaffMessagingThread ignores it.
    bool privateModeActive = false,
    String? privateModeActivatedBy,
    String? studentStatus,
  }) {
    // STAFF_DIRECT is 1:1 — the counterpart's own employment status (not
    // mine) is what gates the composer, mirroring how Room/Admin Chat use
    // the STUDENT's status rather than the viewer's own.
    final counterpart = participants
        .where((p) => p.userCode != _contactFilter.state.currentAccountCode)
        .firstOrNull;
    // How many OTHER active participants this conversation has — seeded
    // into the fresh per-thread CommunicationCubit instance below so its
    // read/delivered-by-all tick aggregation has something to work with
    // (that cubit never loads the full conversation list itself). See
    // CommunicationCubit.seedRecipientCount's own doc for why this is
    // required, not just an optimization.
    final recipientCount = participants
        .where(
          (p) =>
              p.isActive &&
              p.userCode != _contactFilter.state.currentAccountCode,
        )
        .length;
    final args = widget.isStaffMessaging
        ? SeededThreadArgs(
            isStaffMessaging: true,
            conversationCode: code,
            recipientCount: recipientCount,
            staffInfo: StaffThreadInfo(
              name: name,
              avatar: avatar,
              code: code,
              // Passed explicitly so the Firestore watch path matches the
              // conversation's own org/school, not the viewer's stored
              // active org/school (which may differ after a school switch).
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              staffStatus: counterpart?.staffStatus,
              // A staff member can be deactivated (participant-level
              // `active: false` / a set `deactivatedReason`) without
              // their employment `staffStatus` ever flipping to
              // INACTIVE — confirmed via a real conversation where the
              // counterpart had staffStatus=ACTIVE but active=false,
              // deactivatedReason="Staff deactivated", and the composer
              // still showed as sendable. See ConversationParticipant
              // .isActive's own doc comment for why both signals matter.
              staffIsActiveParticipant: counterpart?.isActive,
            ),
          )
        : SeededThreadArgs(
            isStaffMessaging: false,
            conversationCode: code,
            recipientCount: recipientCount,
            conversationType: ConversationType.roomChat,
            parentInfo: ParentThreadInfo(
              name: name,
              avatar: avatar,
              code: code,
              // The conversation's own org/school — used to build the
              // realtime (Firestore) watch path correctly even when the
              // viewer's currently-active org/school differs.
              organizationCode: organizationCode,
              schoolCode: schoolCode,
              // Was `participants.map((p) => p.userName)` — included
              // every role (staff/admin too), not just guardians. Fixed
              // to match the role-filtered pattern used elsewhere (e.g.
              // ParentDirectMessagingScreen._buildParentInfo).
              parents: participants
                  .where((p) => p.role == 'GUARDIAN' || p.role == 'PARENT')
                  .map((p) => p.userName)
                  .toList(),
              guardianMap: {
                for (final p in participants)
                  if (p.role == 'GUARDIAN' || p.role == 'PARENT')
                    p.userCode: p.userName,
              },
              participants: participants,
              // Was hardcoded `[]` — meant every message sent from this
              // Admin/Staff screen routed to zero staff recipients,
              // regardless of who was actually in the conversation.
              staffList: participants
                  .where(
                    (p) =>
                        p.role == 'STAFF' ||
                        p.role == 'ADMIN' ||
                        p.role == 'DIRECTOR' ||
                        p.role == 'TEACHER',
                  )
                  .map((p) => p.userCode)
                  .toList(),
              privateModeParents: participants
                  .where(
                    (p) =>
                        (p.role == 'GUARDIAN' || p.role == 'PARENT') &&
                        p.privateModeEnabled,
                  )
                  .map((p) => p.userName)
                  .toList(),
              // Conversation-level flag from the backend = the source of
              // truth for whether a guardian turned private mode on.
              // (Per-participant privateModeEnabled is never set by the
              // toggle, so deriving from participants was always false.)
              privateModeActive: privateModeActive,
              privateModeActivatedBy: privateModeActivatedBy,
              privateModeActivatedAt: null,
              studentStatus: studentStatus,
            ),
          );
    // The parent branch is always Room Chat (isGuardian: false) — the seeded
    // thread route hardcodes both; Admin Chat's staff/admin view goes through
    // admin_chat_host_screen.dart's separate (v2) screen instead.
    unawaited(
      context.push(CommunicationRoutes.seededThread, extra: args).then((
        _,
      ) async {
        if (!mounted) return;
        // Defer past the pop transition's last frame — calling this
        // synchronously while the popped route's tree is still tearing
        // down has been known to corrupt the element tree of whatever
        // gesture detector is live underneath (RefreshIndicator's own,
        // in this screen's case).
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        // Without the active filter params here, returning from a thread
        // silently re-fetched the UNFILTERED list — the filter chip/state
        // (and its red "active" dot) stayed showing since nothing cleared
        // them, but the list itself reverted to unfiltered, looking like
        // the filter had been "removed" without actually updating its own
        // indicator to match.
        final f = _resolvedFilterParams();
        await context.read<CommunicationCubit>().refreshConversations(
          type: _conversationType,
          size: _conversationPageSize,
          classroomCodes: f.classroomCodes,
          tagCodes: f.tagCodes,
          designations: f.designations,
          studentStatuses: f.studentStatuses,
          staffStatuses: f.staffStatuses,
        );
      }),
    );
  }

  Widget _buildContactPicker(BuildContext context) {
    final noMatches = _shouldShowStartNewChat;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.messagingIconMuted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              noMatches
                  ? (widget.isStaffMessaging
                        ? AppStrings.noStaffMatchTheseFilters
                        : AppStrings.noStudentsMatchTheseFilters)
                  : (widget.isStaffMessaging
                        ? AppStrings.emptyStaffConversations
                        : AppStrings.noConversationsYet),
              style: AppTextStyles.size14.copyWith(fontSize: 15, color: AppColors.messagingIconMuted),
            ),
            if (!noMatches) ...[
              const SizedBox(height: 6),
              Text(
                AppStrings.useThePlusButton,
                style: AppTextStyles.size14.copyWith(fontSize: 13, color: AppColors.messagingIconMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Staff items matching the active filters and/or search query, minus the
  /// logged-in user and anyone who already has a conversation — those
  /// belong in the conversation list above, not duplicated here.
  List<_FilteredContact> _filteredStaffContacts(
    StaffState staffState, {
    String query = '',
    Set<String> excludeCodes = const {},
  }) {
    return staffState.items
        .where((s) => s.code != _contactFilter.state.currentUserCode)
        .where((s) => !excludeCodes.contains(s.userCode))
        .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
        .map(
          (s) => _FilteredContact(
            code: s.code,
            userCode: s.userCode,
            name: s.name,
            // `profileImage` is never populated by the data layer for
            // StaffMember (always null) — `profilePhotoAssetCode` is the
            // field that's actually set.
            avatarUrl: s.profilePhotoAssetCode,
            subtitle: formatDesignationForDisplay(s.designation),
            isInactive: s.status.trim().toUpperCase() == 'INACTIVE',
          ),
        )
        .toList();
  }

  /// Student items matching the active filters and/or search query, minus
  /// the logged-in user and anyone who already has a conversation. Room-chat
  /// conversations carry no student code, so "already has a conversation" is
  /// matched by the student's full name against [excludeNames] (each
  /// conversation's title, set to the student's full name at creation) —
  /// not by code.
  List<_FilteredContact> _filteredStudentContacts(
    StudentState studentState, {
    String query = '',
    Set<String> excludeNames = const {},
  }) {
    return studentState.items
        .where((s) => s.code != _contactFilter.state.currentUserCode)
        .where((s) => !excludeNames.contains(s.fullName.trim().toLowerCase()))
        .where((s) => query.isEmpty || s.fullName.toLowerCase().contains(query))
        .map(
          (s) => _FilteredContact(
            code: s.code,
            name: s.fullName,
            avatarUrl: s.profileImage,
            subtitle: s.primaryClassroomName ?? '',
            classroomCode: s.classroomCode,
            hasGuardian: s.hasGuardian,
            isInactive: s.status.trim().toUpperCase() == 'INACTIVE',
          ),
        )
        .toList();
  }

  /// Flat list row (avatar, name, subtitle, trailing edit icon, thin bottom
  /// divider) matching the existing conversation tile's look, used for the
  /// "Start new chat" section under the filtered inbox.
  Widget _buildContactRow(_FilteredContact contact, {Key? key}) {
    // A student with no guardian linked can't be messaged (no one to
    // receive it) — disable the row, matching web. Never applies to staff
    // contacts. An inactive contact (staff or student) is disabled too —
    // starting a brand-new conversation with someone already inactive
    // isn't a valid action.
    final bool noGuardian = !widget.isStaffMessaging && !contact.hasGuardian;
    final bool isDisabled = noGuardian || contact.isInactive;

    return InkWell(
      key: key,
      // Staff contacts: userCode (USR_*) is the STAFF_DIRECT participant.
      // Student contacts deliberately leave userCode empty (see
      // _FilteredContact doc comment below) — contact.code (the student's
      // own code) is what _startConversationWith sends as ROOM_CHAT's
      // required studentCode. Passing the empty userCode unconditionally
      // sent ROOM_CHAT with no studentCode, which the backend 500s on —
      // this is the same conversation-creation path the New Message screen
      // uses correctly, just reached by searching here instead.
      onTap: isDisabled
          ? null
          : () => _startConversationWith(
              widget.isStaffMessaging ? contact.userCode : contact.code,
              contact.name,
              classroomCode: contact.classroomCode,
            ),
      splashColor: AppColors.messagingTileSplash,
      highlightColor: AppColors.transparentColor,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            border: Border(
              bottom: BorderSide(color: AppColors.messagingDividerLight, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xsPlus),
          child: Row(
            children: [
              DocumentImageWidget(
                disableAttendanceStatusLookup: true,
                fileUuid: '',
                // `avatarUrl` is either a resolved URL or a raw media-asset
                // code depending on which list this contact came from.
                imageUrl: (contact.avatarUrl ?? '').startsWith('http')
                    ? contact.avatarUrl
                    : null,
                mediaAssetCode: (contact.avatarUrl ?? '').startsWith('http')
                    ? null
                    : contact.avatarUrl,
                staffCode: widget.isStaffMessaging ? contact.code : null,
                studentCode: widget.isStaffMessaging ? null : contact.code,
                name: contact.name,
                size: 44,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTextStyles.size16.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.messagingHeadingPlum,
                      ),
                    ),
                    if (isDisabled)
                      Text(
                        contact.isInactive ? AppStrings.inactive : AppStrings.noParentLinked,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 12,
                          color: AppColors.messagingTextSecondary,
                        ),
                      )
                    else if (contact.subtitle.isNotEmpty)
                      Text(
                        contact.subtitle,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 13,
                          color: AppColors.messagingTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isDisabled)
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.messagingAccentPurple,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilteredContact {
  const _FilteredContact({
    required this.code,
    this.userCode = '',
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
    this.classroomCode = '',
    this.hasGuardian = true,
    this.isInactive = false,
  });

  /// Profile / navigation code (STF_* for staff, student code for parents).
  /// Used for self-exclusion and profile screen navigation.
  final String code;

  /// Messaging participant identifier (USR_* for staff, empty for students).
  /// When non-empty, this is sent as participantUserCode instead of [code].
  final String userCode;
  final String name;
  final String? avatarUrl;
  final String subtitle;

  /// Room Chat's optional classroom scope — only meaningful for student
  /// contacts (empty for staff). Straight from [Student.classroomCode].
  final String classroomCode;

  /// Only meaningful for student contacts — see [Student.hasGuardian]. A
  /// student with no guardian linked can't be messaged, so this contact row
  /// is shown disabled, matching web.
  final bool hasGuardian;

  /// True when [StaffMember.status]/[Student.status] is `INACTIVE` —
  /// starting a brand-new conversation with someone already inactive isn't
  /// a valid action (they can't receive/send messages once it exists), so
  /// this contact row is shown disabled, matching the composer's own
  /// "This student/staff member is inactive" gating for existing chats.
  final bool isInactive;
}

class SliverSelectionShimmerWrapper extends StatelessWidget {
  const SliverSelectionShimmerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Messaging tab fallback looks better with list shimmer
    return const MessagingShimmer();
  }
}
