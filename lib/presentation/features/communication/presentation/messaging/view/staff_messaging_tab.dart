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

  /// Fires after a background bulk-send job completes, so the new conversation
  /// appears without requiring a manual pull-to-refresh.
  StreamSubscription<String>? _conversationListChangedSub;

  String get _conversationType =>
      widget.isStaffMessaging ? 'STAFF_DIRECT' : 'ROOM_CHAT';

  @override
  bool get wantKeepAlive => true;

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
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<ClassroomCubit>().loadActiveClassrooms();
        context.read<StaffCubit>().loadInitial();
        context.read<StudentCubit>().loadInitial();
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

    // Reload the conversation list when the background bulk-send job finishes.
    // The job runs fire-and-forget after the compose screen is dismissed, so
    // refreshConversations() in MessagingTab fires before the job completes.
    // This subscription catches the job-done signal and does the real refresh.
    _conversationListChangedSub = MessagingEventService
        .instance.onConversationListChanged
        .listen((changedType) {
      if (!mounted) return;
      if (changedType != _conversationType) return;
      context.read<CommunicationCubit>().loadConversations(
        type: _conversationType,
        size: _conversationPageSize,
      );
    });
  }

  @override
  void dispose() {
    _conversationListChangedSub?.cancel();
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
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
                                          items: [
                                            'Kiosk',
                                            'Director',
                                            'Assistant Director',
                                            'Admin',
                                            'Lead Teacher',
                                            'Associate Teacher',
                                            'Assistant Teacher',
                                            'Owner',
                                            'Floater',
                                          ],
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
                          child: SvgPicture.asset(
                            MediaRes.filterIcon,
                            height: 20,
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

          SliverToBoxAdapter(child: const SizedBox(height: 15)),

          BlocBuilder<CommunicationCubit, CommunicationState>(
            builder: (context, communicationState) {
              if (communicationState is CommunicationConversationsLoading) {
                return const MessagingShimmer();
              }

              if (communicationState is CommunicationError) {
                return SliverFillRemaining(
                  child: Center(child: Text(communicationState.message)),
                );
              }

              // API already returns type-filtered conversations — no
              // client-side participant-code filtering needed.
              List<Conversation> conversationsToDisplay = [];

              if (communicationState is CommunicationConversationsLoaded) {
                final query = _searchController.text.trim().toLowerCase();

                conversationsToDisplay = communicationState
                    .getConversations(_conversationType)
                    .where((conv) {
                      if (query.isNotEmpty &&
                          !conv.title.toLowerCase().contains(query)) {
                        return false;
                      }
                      if (_showUnread && conv.unreadCount == 0) return false;
                      return true;
                    })
                    .toList();
              }

              if (conversationsToDisplay.isEmpty) {
                return _buildContactPicker(context);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final conversation = conversationsToDisplay[index];
                  return MessagingListTile(
                    conversation: conversation,
                    onTap: () {
                      final route = MaterialPageRoute(
                        builder: (_) => BlocProvider<CommunicationCubit>(
                          create: (context) =>
                              serviceLocator<CommunicationCubit>(),
                          child: widget.isStaffMessaging
                              ? StaffMessagingThread(
                                  staffInfo: {
                                    'name': conversation.title,
                                    'avatar': conversation.avatarUrl,
                                    'code': conversation.code,
                                  },
                                )
                              : ParentMessagingThread(
                                  parentInfo: {
                                    'name': conversation.title,
                                    'avatar': conversation.avatarUrl,
                                    'code': conversation.code,
                                    'parents': conversation.participants
                                        .map((p) => p.userName)
                                        .toList(),
                                    'participants': conversation.participants,
                                    'staffList': [],
                                    'privateModeParents': [],
                                  },
                                ),
                        ),
                      );
                      unawaited(
                        Navigator.of(context).push(route).then((_) async {
                          if (mounted) {
                            await context
                                .read<CommunicationCubit>()
                                .refreshConversations(
                                  type: _conversationType,
                                  size: _conversationPageSize,
                                );
                          }
                        }),
                      );
                    },
                  );
                }, childCount: conversationsToDisplay.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactPicker(BuildContext context) {
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
              widget.isStaffMessaging
                  ? 'No staff conversations yet'
                  : 'No conversations yet',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the + button to start one',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverSelectionShimmerWrapper extends StatelessWidget {
  const SliverSelectionShimmerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Messaging tab fallback looks better with list shimmer
    return const MessagingShimmer();
  }
}
