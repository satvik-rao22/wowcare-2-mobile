import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/create_conversation_cubit.dart';
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

  String get _conversationType => 'STAFF_DIRECT';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClassroomCubit>().loadActiveClassrooms();
        context.read<StaffCubit>().loadInitial();
        context.read<StudentCubit>().loadInitial();
        context.read<CommunicationCubit>().loadConversations(
          type: _conversationType,
          size: _conversationPageSize,
        );
      }
    });

    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
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

              List<Conversation> conversationsToDisplay = [];

              if (communicationState is CommunicationConversationsLoaded) {
                final query = _searchController.text.trim().toLowerCase();
                final staffState = context.read<StaffCubit>().state;
                final studentState = context.read<StudentCubit>().state;

                final staffCodes = staffState.items.map((s) => s.code).toSet();
                final studentCodes = studentState.items
                    .map((s) => s.code)
                    .toSet();

                conversationsToDisplay = communicationState
                    .getConversations(_conversationType)
                    .where((conv) {
                      // Filter by search query
                      if (query.isNotEmpty &&
                          !conv.title.toLowerCase().contains(query)) {
                        return false;
                      }

                      // Filter by unread
                      if (_showUnread && conv.unreadCount == 0) return false;

                      // Filter by Staff vs Student/Parent
                      // final otherParticipants = conv.participants.where(
                      //   (p) => p.userCode != conv.createdBy,
                      // );
                      bool isStaffConv = false;
                      bool isStudentConv = false;

                      for (final p in conv.participants) {
                        if (staffCodes.contains(p.userCode)) isStaffConv = true;
                        if (studentCodes.contains(p.userCode))
                          isStudentConv = true;
                      }

                      // If we can't determine by codes, fallback to title or other logic
                      if (!isStaffConv && !isStudentConv) {
                        // This might be a new conversation not yet in our cached staff/student lists
                        // or a group. For now, we trust the tab flag.
                      }

                      if (widget.isStaffMessaging) {
                        return isStaffConv ||
                            (!isStudentConv); // Default to staff if ambiguous
                      } else {
                        return isStudentConv;
                      }
                    })
                    .toList();
              }

              if (conversationsToDisplay.isEmpty) {
                // Show Directory Fallback if no conversations found
                return _buildDirectoryFallback(context);
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
                                    'staffList': [],
                                    'privateModeParents': [],
                                  },
                                ),
                        ),
                      );
                      Navigator.of(context).push(route).then((_) async {
                        if (mounted) {
                          await context.read<CommunicationCubit>().refreshConversations(
                            type: _conversationType,
                            size: _conversationPageSize,
                          );
                        }
                      });
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

  Widget _buildDirectoryFallback(BuildContext context) {
    if (widget.isStaffMessaging) {
      return BlocBuilder<StaffCubit, StaffState>(
        builder: (context, staffState) {
          if (staffState.isLoading && staffState.items.isEmpty) {
            return const SliverSelectionShimmerWrapper();
          }

          final query = _searchController.text.trim().toLowerCase();
          final staff = staffState.items.where((s) {
            if (query.isNotEmpty && !s.name.toLowerCase().contains(query))
              return false;
            return true;
          }).toList();

          if (staff.isEmpty) {
            return const SliverFillRemaining(
              child: Center(child: Text('No staff found')),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final member = staff[index];
              return MessagingListTile(
                conversation: Conversation(
                  id: 0,
                  code: member.code,
                  title: member.name,
                  type: 'STAFF_DIRECT',
                  organizationCode: '',
                  schoolCode: '',
                  status: 'ACTIVE',
                  description: 'Start a new conversation',
                  avatarUrl: member.profileImage ?? '',
                  createdAt: DateTime.now(),
                  createdBy: '',
                  updatedAt: DateTime.now(),
                  updatedBy: '',
                  unreadCount: 0,
                  participantCount: 1,
                  lastMessagePreview: 'Tap to start chatting',
                  participants: [],
                ),
                onTap: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! AuthLoaded) return;

                  final currentUserCode = authState.loginResponse.userCode;
                  final firstRole = authState.loginResponse.roles.isNotEmpty
                      ? authState.loginResponse.roles.first
                      : null;
                  final orgCode = firstRole?.organizationCode ?? '';
                  final schoolCode = firstRole?.schoolCode ?? '';

                  final cubit = serviceLocator<CreateConversationCubit>();

                  final result = await cubit.createConversationAndReturn(
                    title: member.name,
                    type: 'STAFF_DIRECT',
                    description: '',
                    organizationCode: orgCode,
                    schoolCode: schoolCode,
                    participantUserCodes: [currentUserCode, member.code],
                    avatarUrl: '',
                  );

                  if (!context.mounted) return;

                  final conversationCode = result?.code ?? member.code;

                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider<CommunicationCubit>(
                            create: (context) =>
                                serviceLocator<CommunicationCubit>(),
                            child: StaffMessagingThread(
                              staffInfo: {
                                'name': member.name,
                                'avatar': member.profileImage,
                                'code': conversationCode,
                              },
                            ),
                          ),
                        ),
                      )
                      .then((_) async {
                        if (mounted) {
                          await context.read<CommunicationCubit>().refreshConversations(
                            type: _conversationType,
                            size: _conversationPageSize,
                          );
                        }
                      });
                },
              );
            }, childCount: staff.length),
          );
        },
      );
    } else {
      return BlocBuilder<StudentCubit, StudentState>(
        builder: (context, studentState) {
          if (studentState.isLoading && studentState.items.isEmpty) {
            return const SliverSelectionShimmerWrapper();
          }

          final query = _searchController.text.trim().toLowerCase();
          final students = studentState.items.where((s) {
            final fullName = '${s.firstName} ${s.lastName}'.toLowerCase();
            if (query.isNotEmpty && !fullName.contains(query)) return false;
            return true;
          }).toList();

          if (students.isEmpty) {
            return const SliverFillRemaining(
              child: Center(child: Text('No students found')),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final student = students[index];
              return MessagingListTile(
                conversation: Conversation(
                  id: 0,
                  code: student.code,
                  title: '${student.firstName} ${student.lastName}',
                  type: 'GROUP',
                  organizationCode: '',
                  schoolCode: '',
                  status: 'ACTIVE',
                  description: 'Parent Group Chat',
                  avatarUrl: student.profileImage ?? '',
                  createdAt: DateTime.now(),
                  createdBy: '',
                  updatedAt: DateTime.now(),
                  updatedBy: '',
                  unreadCount: 0,
                  participantCount: 1,
                  lastMessagePreview: 'Tap to start group chat',
                  participants: [],
                ),
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider<CommunicationCubit>(
                            create: (context) =>
                                serviceLocator<CommunicationCubit>(),
                            child: ParentMessagingThread(
                              parentInfo: {
                                'name':
                                    '${student.firstName} ${student.lastName}',
                                'avatar': student.profileImage,
                                'code': student.code,
                                'parents': [],
                                'staffList': [],
                                'privateModeParents': [],
                              },
                            ),
                          ),
                        ),
                      )
                      .then((_) async {
                        if (mounted) {
                          await context.read<CommunicationCubit>().refreshConversations(
                            type: _conversationType,
                            size: _conversationPageSize,
                          );
                        }
                      });
                },
              );
            }, childCount: students.length),
          );
        },
      );
    }
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
