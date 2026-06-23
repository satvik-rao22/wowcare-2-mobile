import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../domain/features/communication/entities/conversation.dart';
import '../../../../../../shared/common/views/filter_screen.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../../core/util/safe_state_mixin.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/storage_keys.dart';
import '../../../../../../domain/features/communication/entities/conversation_entity.dart';
import '../../../../../../domain/features/communication/entities/enums.dart';
import '../../../../../../domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import '../../../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../../../classrooom/views/filters/designation_display_utils.dart';
import '../../../../student/cubit/student_cubit.dart';
import '../../../cubit/communication_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/messaging_shimmer.dart';
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

  Future<void> _loadCurrentUserCode() async {
    final storageService = serviceLocator<StorageService>();
    final staffCode =
        (await storageService.getString(StorageKeys.staffCode) ?? '').trim();
    final userCode =
        (await storageService.getString(StorageKeys.userCode) ?? '').trim();
    final code = staffCode.isNotEmpty ? staffCode : userCode;
    if (!mounted || code.isEmpty) return;
    setState(() => _currentUserCode = code);
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
  /// here instead of just coming up empty.
  /// For Room Chat (parent messaging), always show to allow staff to start new conversations.
  bool get _shouldShowStartNewChat =>
      _hasActiveContactFilters ||
      _hasSearchQuery ||
      !widget.isStaffMessaging;

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
  Future<void> _startConversationWith(String code, String name) async {
    if (_currentUserCode != null && code == _currentUserCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can\'t start a conversation with yourself'),
        ),
      );
      return;
    }
    if (_startingConversationWith.contains(code)) return;
    _startingConversationWith.add(code);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating conversation with $name…'),
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await serviceLocator<CreateOrOpenConversationUseCase>()(
      type: widget.isStaffMessaging
          ? ConversationType.staffDirect
          : ConversationType.roomChat,
      studentCode: widget.isStaffMessaging ? '' : code,
      participantCodes: widget.isStaffMessaging ? [code] : const [],
      title: name,
    );
    _startingConversationWith.remove(code);
    if (!mounted) return;
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a conversation with $name')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat with $name created successfully')),
    );
    _openThread(
      name: conversation.title.isNotEmpty ? conversation.title : name,
      avatar: conversation.avatarUrl,
      code: conversation.code,
      participants: conversation.participants
          .map(_toLegacyParticipant)
          .toList(),
    );
  }

  /// Adapts the v2 `ParticipantEntity` (returned by
  /// `CreateOrOpenConversationUseCase`) to the legacy `ConversationParticipant`
  /// shape `ParentMessagingThread` expects, so participant names/roles still
  /// render correctly for a brand-new room-chat conversation.
  ConversationParticipant _toLegacyParticipant(ParticipantEntity p) {
    return ConversationParticipant(
      id: p.id,
      conversationId: p.conversationId,
      userCode: p.userCode,
      userName: p.userName,
      role: p.role.toApiString(),
      joinedAt: p.joinedAt,
      leftAt: p.leftAt,
      lastReadAt: p.lastReadAt,
      muted: p.muted,
      notificationsEnabled: p.notificationsEnabled,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  void _applyFilters() {
    setState(() {}); // Trigger rebuild to re-filter in build
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters.clear();
      _showUnread = false;
      _currentFilters['Unread'] = [];
      _searchController.clear();
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

    _searchController.addListener(_applyFilters);
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
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _conversationScrollController.removeListener(_onConversationScroll);
    _conversationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (!mounted) return;
        await context.read<CommunicationCubit>().loadConversations(
          type: _conversationType,
          size: _conversationPageSize,
        );
      },
      child: CustomScrollView(
        controller: _conversationScrollController,
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
                                          isMultiSelectDropDown: true,
                                          label: 'Status',
                                          hintText: 'Select status',
                                          items: ['Active', 'Upcoming'],
                                          initialSelected:
                                              _currentFilters['Status'] ?? [],
                                          isSingleSelect: true,
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
                                          items: ['Active', 'Upcoming'],
                                          initialSelected:
                                              _currentFilters['Status'] ?? [],
                                          isSingleSelect: true,
                                        ),
                                        FilerSection(
                                          label: 'Tags',
                                          hintText: 'Select tags',
                                          items: [
                                            '5 Days',
                                            'Full Day',
                                            'Photo Permission',
                                            'Vegetarian',
                                            'First Aid',
                                            'Allergy',
                                            'Pickup Authorized',
                                            'Medication',
                                            'Half Day',
                                            'Boy',
                                            'Girl',
                                          ],
                                          initialSelected:
                                              _currentFilters['Tags'] ?? [],
                                          isMultiSelectDropDown: false,
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
                      final query = _searchController.text
                          .trim()
                          .toLowerCase();

                      if (communicationState
                          is CommunicationConversationsLoaded) {
                        // Only the Staff tab's filters (Classroom/Designation/Status)
                        // can be reliably matched against a conversation: each
                        // conversation's participants carry the staff member's own
                        // userCode, which is the same code StaffCubit's filtered
                        // results use. Parent/Room-chat conversations have no such
                        // reliable student/classroom code on the participant, so
                        // their list isn't narrowed the same way.
                        final filteredStaffCodes =
                            (widget.isStaffMessaging &&
                                _hasActiveContactFilters)
                            ? staffState.items.map((s) => s.code).toSet()
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

                        conversationsToDisplay = allConversationsForType
                            .where((conv) {
                              if (query.isNotEmpty &&
                                  !conv.title.toLowerCase().contains(query)) {
                                return false;
                              }
                              if (_showUnread && conv.unreadCount == 0)
                                return false;
                              if (filteredStaffCodes != null &&
                                  !conv.participants.any(
                                    (p) =>
                                        filteredStaffCodes.contains(p.userCode),
                                  )) {
                                return false;
                              }
                              // Hide a conversation a user somehow has with only
                              // themselves (no other participant).
                              if (_currentUserCode != null &&
                                  conv.participants.isNotEmpty &&
                                  conv.participants.every(
                                    (p) => p.userCode == _currentUserCode,
                                  )) {
                                return false;
                              }
                              return true;
                            })
                            .toList();
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
                                  onTap: () => _openThread(
                                    name: conversation.title,
                                    avatar: conversation.avatarUrl,
                                    code: conversation.code,
                                    participants: conversation.participants,
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
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
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
  }) {
    final route = MaterialPageRoute(
      builder: (_) => BlocProvider<CommunicationCubit>(
        create: (context) => serviceLocator<CommunicationCubit>(),
        child: widget.isStaffMessaging
            ? StaffMessagingThread(
                staffInfo: {'name': name, 'avatar': avatar, 'code': code},
              )
            : ParentMessagingThread(
                parentInfo: {
                  'name': name,
                  'avatar': avatar,
                  'code': code,
                  'parents': participants.map((p) => p.userName).toList(),
                  'guardianMap': {
                    for (final p in participants)
                      if (p.role == 'GUARDIAN' || p.role == 'PARENT')
                        p.userCode: p.userName,
                  },
                  'participants': participants,
                  'staffList': [],
                  'privateModeParents': participants
                      .where(
                        (p) =>
                            (p.role == 'GUARDIAN' || p.role == 'PARENT') &&
                            p.privateModeEnabled,
                      )
                      .map((p) => p.userName)
                      .toList(),
                  'privateModeActive': participants.any(
                    (p) => p.privateModeEnabled,
                  ),
                  'privateModeActivatedBy': null,
                  'privateModeActivatedAt': null,
                },
                isGuardian: false,
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
        .where((s) => !excludeCodes.contains(s.code))
        .where(
          (s) => query.isEmpty || s.name.toLowerCase().contains(query),
        )
        .map(
          (s) => _FilteredContact(
            code: s.code,
            name: s.name,
            avatarUrl: s.profileImage,
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
        .where(
          (s) => query.isEmpty || s.fullName.toLowerCase().contains(query),
        )
        .map(
          (s) => _FilteredContact(
            code: s.code,
            name: s.fullName,
            avatarUrl: s.profileImage,
            subtitle: s.primaryClassroomName ?? '',
          ),
        )
        .toList();
  }

  /// Flat list row (avatar, name, subtitle, trailing edit icon, thin bottom
  /// divider) matching the existing conversation tile's look, used for the
  /// "Start new chat" section under the filtered inbox.
  Widget _buildContactRow(_FilteredContact contact, {Key? key}) {
    return InkWell(
      key: key,
      onTap: () => _startConversationWith(contact.code, contact.name),
      splashColor: const Color(0x1A6C5CE7),
      highlightColor: Colors.transparent,
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
            CircleAvatar(
              radius: 22,
              backgroundImage: (contact.avatarUrl ?? '').isNotEmpty
                  ? NetworkImage(contact.avatarUrl!)
                  : null,
              child: (contact.avatarUrl ?? '').isEmpty
                  ? Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                    )
                  : null,
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
                  if (contact.subtitle.isNotEmpty)
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
            const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }
}

class _FilteredContact {
  const _FilteredContact({
    required this.code,
    required this.name,
    required this.avatarUrl,
    required this.subtitle,
  });

  final String code;
  final String name;
  final String? avatarUrl;
  final String subtitle;
}

class SliverSelectionShimmerWrapper extends StatelessWidget {
  const SliverSelectionShimmerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Messaging tab fallback looks better with list shimmer
    return const MessagingShimmer();
  }
}
