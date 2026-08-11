import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/conversation_display.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../domain/features/communication/entities/conversation.dart';
import '../../../../../../domain/features/communication/repositories/communication_repository.dart';
import '../../../../../../shared/common/views/filter_screen.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../../core/util/safe_state_mixin.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/storage_keys.dart';
import '../../../../../../domain/features/communication/entities/enums.dart';
import '../../../../../../domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import '../../../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../classrooom/views/filters/designation_display_utils.dart';
import '../../../../student/cubit/student_cubit.dart';
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
  Map<String, List<String>> _currentFilters = {};
  bool _showUnread = false;
  static const int _conversationPageSize = 50;

  /// Drives the inbox's "load more" — fetches the next page once the user
  /// scrolls within this many pixels of the end, instead of capping the
  /// list at whatever the first fixed-size fetch returned.
  final ScrollController _conversationScrollController = ScrollController();
  static const double _loadMoreScrollThreshold = 300.0;

  /// Fires after a background bulk-send job completes, so the new conversation
  /// appears without requiring a manual pull-to-refresh.
  StreamSubscription<String>? _conversationListChangedSub;

  /// The logged-in user's own staff/user code — used to hide self from
  /// contact pickers and block self-conversations.
  String? _currentUserCode;

  /// The logged-in user's canonical **userCode** (`USR-…`). Distinct from
  /// [_currentUserCode], which is the **staff** code (`STF_…`) used for staff
  /// picker / self-conversation checks. Conversation participants are keyed by
  /// userCode, so the "other participant" resolution MUST compare against this
  /// — comparing against the staff code never matches self and would make a 1:1
  /// row fall back to the first participant (often the viewer themselves).
  String? _currentAccountCode;

  Future<void> _loadCurrentUserCode() async {
    final storageService = serviceLocator<StorageService>();
    final staffCode =
        (await storageService.getString(StorageKeys.staffCode) ?? '').trim();
    final userCode =
        (await storageService.getString(StorageKeys.userCode) ?? '').trim();
    final code = staffCode.isNotEmpty ? staffCode : userCode;
    if (!mounted || (code.isEmpty && userCode.isEmpty)) return;
    setState(() {
      if (code.isNotEmpty) _currentUserCode = code;
      if (userCode.isNotEmpty) _currentAccountCode = userCode;
    });
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

  /// Tag display name -> backend tag code, resolved once per school for the
  /// Parent tab's Tags filter (tags have no fixed/predefined codes like
  /// designation does, so this has to be fetched).
  Map<String, String> _tagNameToCode = {};

  String get _conversationType =>
      widget.isStaffMessaging ? 'STAFF_DIRECT' : 'ROOM_CHAT';

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadTagNameCodeMap() async {
    final storageService = serviceLocator<StorageService>();
    final schoolCode =
        await storageService.getString(StorageKeys.schoolCode) ?? '';
    if (schoolCode.isEmpty) return;
    final map = await serviceLocator<GetTagNameCodeMapForSchoolUseCase>()(
      schoolCode: schoolCode,
    );
    if (!mounted) return;
    setState(() => _tagNameToCode = map);
  }

  /// Maps a single-select Status filter selection ('Active'/'Upcoming') to
  /// the backend enum value, or null when nothing is selected.
  String? _mapStatusToApi(List<String>? selected) {
    if (selected == null || selected.isEmpty) return null;
    return selected.first.trim().toUpperCase();
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
    return names.map((n) => _tagNameToCode[n]).whereType<String>().toList();
  }

  /// True when any Classroom/Status/Designation/Tags filter is actively
  /// selected (ignores the 'Unread' toggle, which doesn't drive these lists).
  bool get _hasActiveContactFilters => _currentFilters.entries.any(
    (e) => e.key != 'Unread' && e.value.isNotEmpty,
  );

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
  String get _activeFiltersSummary => _currentFilters.entries
      .where((e) => e.key != 'Unread' && e.value.isNotEmpty)
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
    if (_currentUserCode != null && code == _currentUserCode) {
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

    final result = await serviceLocator<CreateOrOpenConversationUseCase>()(
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
    );
  }

  void _applyFilters() {
    setState(() {}); // Trigger rebuild to re-filter in build
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
  /// fetched into [CommunicationCubit]'s state yet.
  List<Conversation>? _serverSearchResults;

  /// Guards against an older, slower keystroke's response overwriting a
  /// newer one's — only the response matching [_searchController]'s CURRENT
  /// text at completion time is applied.
  int _searchRequestToken = 0;

  Future<void> _searchConversations(String query) async {
    final token = ++_searchRequestToken;
    if (query.isEmpty) {
      if (mounted) setState(() => _serverSearchResults = null);
      return;
    }
    final result = await serviceLocator<CommunicationRepository>()
        .searchConversations(query: query, type: _conversationType);
    if (!mounted || token != _searchRequestToken) return;
    result.fold(
      (_) {}, // Keep showing the previous (or empty) results on failure.
      (conversations) => setState(() => _serverSearchResults = conversations),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters.clear();
      _showUnread = false;
      _currentFilters['Unread'] = [];
      _searchController.clear();
      _serverSearchResults = null;
      _searchRequestToken++;
    });
    if (!mounted) return;
    _applyFilters();
    if (widget.isStaffMessaging) {
      context.read<StaffCubit>().updateFilters(
        status: null,
        designation: null,
        classCodes: const [],
      );
      unawaited(
        context.read<StaffCubit>().refresh(ignoreRefreshingGuard: true),
      );
    } else {
      context.read<StudentCubit>().updateFilters(
        status: null,
        classroomCodes: const [],
        tagCodes: const [],
      );
      unawaited(context.read<StudentCubit>().refreshWithCacheReset());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Non-admin staff only see the classrooms they're allowed to
        // access; admins see every active classroom.
        context.read<ClassroomCubit>().loadActiveClassrooms(
          applyAttendanceStaffScope: true,
        );
        context.read<StaffCubit>().loadInitial();
        context.read<StudentCubit>().loadInitial();
        unawaited(_loadCurrentUserCode());
        if (!widget.isStaffMessaging) {
          unawaited(_loadTagNameCodeMap());
        }
        await context.read<CommunicationCubit>().loadConversations(
          type: _conversationType,
          size: _conversationPageSize,
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
          context.read<CommunicationCubit>().loadConversations(
            type: _conversationType,
            size: _conversationPageSize,
          );
        });
  }

  void _onConversationScroll() {
    if (!_conversationScrollController.hasClients) return;
    final position = _conversationScrollController.position;
    if (position.maxScrollExtent - position.pixels > _loadMoreScrollThreshold) {
      return;
    }
    context.read<CommunicationCubit>().loadMoreConversations(
      type: _conversationType,
      size: _conversationPageSize,
    );
  }

  @override
  void dispose() {
    _conversationListChangedSub?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _conversationScrollController.removeListener(_onConversationScroll);
    _conversationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomRefreshIndicator(
      onRefresh: () async {
        if (!mounted) return;
        await context.read<CommunicationCubit>().loadConversations(
          type: _conversationType,
          size: _conversationPageSize,
        );
      },
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
                          color: const Color(0x33B1AFE9),
                        ),
                        child: CustomSearchBar(
                          controller: _searchController,
                          hintText: widget.isStaffMessaging
                              ? 'Search Staff'
                              : 'Search student',
                          searchBarColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          borderColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Discoverable manual refresh — mirrors the pull-to-refresh
                    // (loadConversations) so users aren't limited to the pull gesture,
                    // which isn't obvious and can't be triggered on a short/empty list.
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.read<CommunicationCubit>().loadConversations(
                            type: _conversationType,
                            size: _conversationPageSize,
                          );
                          CoreUtils.showTopSnackBar(
                            context: context,
                            message: 'Refreshing conversations…',
                            duration: const Duration(milliseconds: 1200),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0x33B1AFE9),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final classroomNames = context
                              .read<ClassroomCubit>()
                              .state
                              .classrooms
                              .map((e) => e.name)
                              .toList();

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => widget.isStaffMessaging
                                  ? FilterScreen(
                                      sections: [
                                        FilerSection(
                                          label: 'Classroom',
                                          hintText: 'Select classroom',
                                          items: classroomNames,
                                          initialSelected:
                                              _currentFilters['Classroom'] ??
                                              [],
                                          isMultiSelectDropDown: true,
                                        ),
                                        FilerSection(
                                          label: 'Designation',
                                          hintText: 'Select designation',
                                          items:
                                              _designationLabelToCode.keys
                                                  .toList()
                                                ..sort(),
                                          isMultiSelectDropDown: true,
                                          initialSelected:
                                              _currentFilters['Designation'] ??
                                              [],
                                        ),
                                        FilerSection(
                                          label: 'Status',
                                          hintText: 'Select status',
                                          items: const [
                                            'Active',
                                            'Upcoming',
                                            'Inactive',
                                          ],
                                          initialSelected:
                                              _currentFilters['Status'] ?? [],
                                          isSingleSelect: true,
                                        ),
                                      ],
                                      onApply: (filters) {
                                        if (!mounted) return;
                                        setState(() {
                                          _currentFilters = filters;
                                        });
                                        _applyFilters();
                                        context
                                            .read<StaffCubit>()
                                            .updateFilters(
                                              status: _mapStatusToApi(
                                                filters['Status'],
                                              ),
                                              designation: _mapDesignationToApi(
                                                filters['Designation'],
                                              ),
                                              classCodes:
                                                  _mapClassroomNamesToCodes(
                                                    filters['Classroom'],
                                                  ),
                                            );
                                        unawaited(
                                          context.read<StaffCubit>().refresh(
                                            ignoreRefreshingGuard: true,
                                          ),
                                        );
                                      },
                                    )
                                  : FilterScreen(
                                      sections: [
                                        FilerSection(
                                          label: 'Classroom',
                                          hintText: 'Select classroom',
                                          items: classroomNames,
                                          initialSelected:
                                              _currentFilters['Classroom'] ??
                                              [],
                                          isMultiSelectDropDown: true,
                                        ),
                                        FilerSection(
                                          label: 'Status',
                                          hintText: 'Select status',
                                          items: const [
                                            'Active',
                                            'Upcoming',
                                            'Inactive',
                                          ],
                                          initialSelected:
                                              _currentFilters['Status'] ?? [],
                                          isSingleSelect: true,
                                        ),
                                        FilerSection(
                                          label: 'Tags',
                                          hintText: 'Select tags',
                                          items: _tagNameToCode.keys.toList()
                                            ..sort(),
                                          initialSelected:
                                              _currentFilters['Tags'] ?? [],
                                          isMultiSelectDropDown: true,
                                        ),
                                      ],
                                      onApply: (filters) {
                                        if (!mounted) return;
                                        setState(() {
                                          _currentFilters = filters;
                                        });
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
                                              .refreshWithCacheReset(),
                                        );
                                      },
                                    ),
                            ),
                          );
                          if (!mounted) return;
                          if (result is Map) {
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SvgPicture.asset(MediaRes.filterIcon, height: 20),
                              if (_hasActiveContactFilters)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: CustomToggle(
                        label: 'Show Only Unread',
                        isToggled: _showUnread,
                        onToggle: (v) {
                          setState(() {
                            _showUnread = v;
                            _currentFilters['Unread'] = v ? ['true'] : [];
                          });
                          _applyFilters();
                        },
                        //onToggle: (v) => setState(() => _showUnread = v),
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
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _activeFiltersSummary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff573353),
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
                  return BlocBuilder<CommunicationCubit, CommunicationState>(
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
                      Set<String> existingContactCodes = const {};
                      Set<String> existingContactNames = const {};
                      final query = _searchController.text.trim().toLowerCase();

                      if (communicationState
                          is CommunicationConversationsLoaded) {
                        // The Staff tab's filters (Classroom/Designation/Status)
                        // are matched against a conversation via each
                        // conversation's participants, which carry the staff
                        // member's own userCode — the same code StaffCubit's
                        // filtered results use.
                        final filteredStaffCodes =
                            (widget.isStaffMessaging &&
                                _hasActiveContactFilters)
                            ? staffState.items
                                  .map((s) => s.userCode)
                                  .where((c) => c.isNotEmpty)
                                  .toSet()
                            : null;

                        // Room-chat (Parent Messaging) conversations carry no
                        // student code on the participant — only the
                        // guardian(s) — so Classroom/Status/Tags filters are
                        // matched by the conversation's title instead, which
                        // is set to the student's full name when the
                        // room-chat conversation is created. StudentCubit's
                        // `items` here is already the server-filtered set
                        // (classroom/status/tags applied via updateFilters),
                        // so matching against it applies all three filters.
                        final filteredStudentNames =
                            (!widget.isStaffMessaging &&
                                _hasActiveContactFilters)
                            ? studentState.items
                                  .map(
                                    (s) => '${s.firstName} ${s.lastName}'
                                        .trim()
                                        .toLowerCase(),
                                  )
                                  .toSet()
                            : null;

                        final allConversationsForType = communicationState
                            .getConversations(_conversationType);

                        // Anyone who already has a conversation belongs in
                        // the list above, not duplicated in "Start new
                        // chat" below — computed from the full (unfiltered
                        // by search) list so it's correct regardless of
                        // what's currently typed.
                        //
                        // Staff Messaging conversations carry the staff
                        // member's own userCode as a participant, so they
                        // can be matched directly against StaffCubit's
                        // codes. Room-chat (Parent Messaging) conversations
                        // only have the guardian(s) as participants — the
                        // student is never a participant — so there's no
                        // code to match against StudentCubit's items.
                        // Instead, match by the conversation's title, which
                        // is set to the student's full name when the
                        // room-chat conversation is created.
                        if (widget.isStaffMessaging) {
                          existingContactCodes = allConversationsForType
                              .expand((c) => c.participants)
                              .map((p) => p.userCode)
                              .toSet();
                        } else {
                          existingContactNames = allConversationsForType
                              .map((c) => c.title.trim().toLowerCase())
                              .toSet();
                        }

                        // Once the server search for the current query has
                        // resolved, search the account's full conversation
                        // history instead of only what's already loaded
                        // locally — a match may not be among the
                        // (recency-ordered) conversations fetched so far.
                        // Falls back to filtering the local list by title
                        // while that request is still in flight.
                        final conversationsBaseList =
                            (query.isNotEmpty && _serverSearchResults != null)
                            ? _serverSearchResults!
                            : allConversationsForType;

                        conversationsToDisplay = conversationsBaseList.where((
                          conv,
                        ) {
                          if (query.isNotEmpty &&
                              !conv.title.toLowerCase().contains(query)) {
                            return false;
                          }
                          if (_showUnread && conv.unreadCount == 0)
                            return false;
                          if (filteredStaffCodes != null &&
                              !conv.participants.any(
                                (p) => filteredStaffCodes.contains(p.userCode),
                              )) {
                            return false;
                          }
                          if (filteredStudentNames != null &&
                              !filteredStudentNames.contains(
                                conv.title.trim().toLowerCase(),
                              )) {
                            return false;
                          }
                          // Hide a conversation a user somehow has with only
                          // themselves (no other participant). Participants
                          // are keyed by userCode, so this MUST compare
                          // against the account code — never the staff code.
                          if (_currentAccountCode != null &&
                              _currentAccountCode!.isNotEmpty &&
                              conv.participants.isNotEmpty &&
                              conv.participants.every(
                                (p) => p.userCode == _currentAccountCode,
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
                                  currentUserCode: _currentAccountCode,
                                  onTap: () => _openThread(
                                    name: ConversationDisplay.name(
                                      conversation,
                                      _currentAccountCode,
                                    ),
                                    avatar: ConversationDisplay.avatar(
                                      conversation,
                                      _currentAccountCode,
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
                                  padding: EdgeInsets.symmetric(vertical: 16),
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
                                  'START NEW CHAT (${filteredContacts.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: Color(0xFF9B96B0),
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
  }) {
    final route = MaterialPageRoute(
      builder: (_) => BlocProvider<CommunicationCubit>(
        create: (context) => serviceLocator<CommunicationCubit>(),
        child: widget.isStaffMessaging
            ? StaffMessagingThread(
                staffInfo: {
                  'name': name,
                  'avatar': avatar,
                  'code': code,
                  // Passed explicitly so the Firestore watch path matches the
                  // conversation's own org/school, not the viewer's stored
                  // active org/school (which may differ after a school switch).
                  'organizationCode': organizationCode,
                  'schoolCode': schoolCode,
                },
              )
            : ParentMessagingThread(
                parentInfo: {
                  'name': name,
                  'avatar': avatar,
                  'code': code,
                  // The conversation's own org/school — used to build the
                  // realtime (Firestore) watch path correctly even when the
                  // viewer's currently-active org/school differs.
                  'organizationCode': organizationCode,
                  'schoolCode': schoolCode,
                  // Was `participants.map((p) => p.userName)` — included
                  // every role (staff/admin too), not just guardians. Fixed
                  // to match the role-filtered pattern used elsewhere (e.g.
                  // ParentDirectMessagingScreen._buildParentInfo).
                  'parents': participants
                      .where((p) => p.role == 'GUARDIAN' || p.role == 'PARENT')
                      .map((p) => p.userName)
                      .toList(),
                  'guardianMap': {
                    for (final p in participants)
                      if (p.role == 'GUARDIAN' || p.role == 'PARENT')
                        p.userCode: p.userName,
                  },
                  'participants': participants,
                  // Was hardcoded `[]` — meant every message sent from this
                  // Admin/Staff screen routed to zero staff recipients,
                  // regardless of who was actually in the conversation.
                  'staffList': participants
                      .where(
                        (p) =>
                            p.role == 'STAFF' ||
                            p.role == 'ADMIN' ||
                            p.role == 'DIRECTOR' ||
                            p.role == 'TEACHER',
                      )
                      .map((p) => p.userCode)
                      .toList(),
                  'privateModeParents': participants
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
                  'privateModeActive': privateModeActive,
                  'privateModeActivatedBy': privateModeActivatedBy,
                  'privateModeActivatedAt': null,
                },
                isGuardian: false,
                // This branch is always Room Chat — Admin Chat's staff/admin
                // view goes through admin_chat_host_screen.dart's separate
                // (v2) screen instead.
                conversationType: ConversationType.roomChat,
              ),
      ),
    );
    unawaited(
      Navigator.of(context).push(route).then((_) async {
        if (!mounted) return;
        // Defer past the pop transition's last frame — calling this
        // synchronously while the popped route's tree is still tearing
        // down has been known to corrupt the element tree of whatever
        // gesture detector is live underneath (RefreshIndicator's own,
        // in this screen's case).
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        await context.read<CommunicationCubit>().refreshConversations(
          type: _conversationType,
          size: _conversationPageSize,
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
              color: Colors.grey.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              noMatches
                  ? (widget.isStaffMessaging
                        ? 'No staff match these filters'
                        : 'No students match these filters')
                  : (widget.isStaffMessaging
                        ? 'No staff conversations yet'
                        : 'No conversations yet'),
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            if (!noMatches) ...[
              const SizedBox(height: 6),
              const Text(
                'Use the + button to start one',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
        .where((s) => s.code != _currentUserCode)
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
        .where((s) => s.code != _currentUserCode)
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
    // contacts.
    final bool isDisabled = !widget.isStaffMessaging && !contact.hasGuardian;

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
      splashColor: const Color(0x1A6C5CE7),
      highlightColor: Colors.transparent,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              DocumentImageWidget(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff573353),
                      ),
                    ),
                    if (isDisabled)
                      const Text(
                        'No parent linked',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636E72),
                        ),
                      )
                    else if (contact.subtitle.isNotEmpty)
                      Text(
                        contact.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF636E72),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isDisabled)
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF6C5CE7),
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
}

class SliverSelectionShimmerWrapper extends StatelessWidget {
  const SliverSelectionShimmerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Messaging tab fallback looks better with list shimmer
    return const MessagingShimmer();
  }
}
