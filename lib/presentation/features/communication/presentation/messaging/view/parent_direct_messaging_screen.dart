import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_state.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import '../../../../../../domain/features/communication/entities/conversation.dart';

/// Parent/Guardian messaging entry point.
///
/// Bypasses the conversation list and goes straight to the thread for the
/// selected student. A dropdown at the top lets the parent switch children.
/// Each student switch destroys and recreates the thread widget so messages
/// reload cleanly for the new conversation.
///
/// The `+` button lets the parent start a new Room Chat conversation when
/// no conversation exists yet for their student.
class ParentDirectMessagingScreen extends StatefulWidget {
  const ParentDirectMessagingScreen({super.key});

  @override
  State<ParentDirectMessagingScreen> createState() =>
      _ParentDirectMessagingScreenState();
}

class _ParentDirectMessagingScreenState
    extends State<ParentDirectMessagingScreen> {
  late final ConversationListCubit _listCubit;
  ConversationEntity? _selectedConversation;

  // Used only when no conversation exists yet — keeps the input bar visible.
  final TextEditingController _emptyInputController = TextEditingController();
  final FocusNode _emptyInputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _listCubit = ConversationListCubit(
      conversationType: ConversationType.roomChat,
      watchConversationsUseCase: serviceLocator<WatchConversationsUseCase>(),
      getConversationsUseCase: serviceLocator<GetConversationsEntityUseCase>(),
      getCachedConversationsUseCase:
          serviceLocator<GetCachedConversationsEntityUseCase>(),
      conversationRepository: serviceLocator(),
      storageService: serviceLocator(),
    );
    _listCubit.startWatching();
  }

  @override
  void dispose() {
    _listCubit.close();
    _emptyInputController.dispose();
    _emptyInputFocus.dispose();
    super.dispose();
  }

  /// Syncs the selected conversation to [child] by matching [studentCode].
  ///
  /// Never shows a conversation that isn't confirmed to belong to [child] —
  /// if there's no match (including while [child] is still null/unresolved),
  /// the screen shows its empty/loading state rather than guessing at some
  /// other conversation in the list (e.g. a different child's, or one from
  /// another persona context entirely).
  ///
  /// [explicit] forces the screen to update even when the resulting
  /// conversation's code hasn't changed from what's already selected — used
  /// when the user (or a persona switch) actually changed which child is
  /// selected, so a null result still clears any stale thread immediately.
  void _syncToChild(
    ParentChildRef? child,
    List<ConversationEntity> conversations, {
    bool explicit = false,
  }) {
    ConversationEntity? match;
    if (child != null) {
      for (final c in conversations) {
        if (c.studentCode == child.code) {
          match = c;
          break;
        }
      }
    }

    if (explicit || match?.code != _selectedConversation?.code) {
      setState(() => _selectedConversation = match);
    }
  }

  /// Converts a v2 [ConversationEntity] into the legacy [parentInfo] map that
  /// [ParentMessagingThread] expects.
  Map<String, dynamic> _buildParentInfo(ConversationEntity conv) {
    final legacyParticipants = conv.participants.map((p) {
      final roleStr = p.role == ParticipantRole.parent
          ? 'GUARDIAN'
          : p.role.name.toUpperCase();
      return ConversationParticipant(
        id: 0,
        conversationId: 0,
        userCode: p.userCode,
        userName: p.userName,
        role: roleStr,
        joinedAt: DateTime.now(),
        muted: false,
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        privateModeEnabled: conv.isPrivateModeEnabledFor(p.userCode),
      );
    }).toList();

    final parentNames = legacyParticipants
        .where((p) => p.role == 'GUARDIAN' || p.role == 'PARENT')
        .map((p) => p.userName)
        .toList();
    final guardians = legacyParticipants
        .where((p) => p.role == 'GUARDIAN' || p.role == 'PARENT')
        .toList();

    final staffCodes = legacyParticipants
        .where(
          (p) =>
              p.role == 'STAFF' ||
              p.role == 'ADMIN' ||
              p.role == 'DIRECTOR' ||
              p.role == 'TEACHER',
        )
        .map((p) => p.userCode)
        .toList();

    final privateModeParentNames = legacyParticipants
        .where(
          (p) =>
              (p.role == 'GUARDIAN' || p.role == 'PARENT') &&
              p.privateModeEnabled,
        )
        .map((p) => p.userName)
        .toList();

    return {
      'name': conv.title,
      'avatar': conv.avatarUrl,
      'code': conv.code,
      'parents': parentNames,
      'guardianMap': {
        for (final guardian in guardians) guardian.userCode: guardian.userName,
      },
      'participants': legacyParticipants,
      'staffList': staffCodes,
      'privateModeParents': privateModeParentNames,
      'privateModeActive': conv.privateModeActive,
      'privateModeActivatedBy': conv.privateModeActivatedBy,
      'privateModeActivatedAt': conv.privateModeActivatedAt,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationListCubit>.value(
      value: _listCubit,
      child: BlocListener<ParentChildCubit, ParentChildState>(
        // Also fire the very first time isLoaded flips to true (not just on
        // a selectedChild code change) — covers the case where the resolved
        // child ends up being the same code an earlier race already guessed
        // wrong via the "first conversation" fallback below, which a
        // code-only comparison would otherwise treat as a no-op.
        listenWhen: (prev, curr) =>
            prev.selectedChild?.code != curr.selectedChild?.code ||
            (!prev.isLoaded && curr.isLoaded),
        listener: (context, childState) {
          _syncToChild(
            childState.selectedChild,
            _listCubit.state.conversations,
            explicit: true,
          );
        },
        child: BlocConsumer<ConversationListCubit, ConversationListState>(
          listener: (context, state) {
            if (_selectedConversation == null &&
                state.conversations.isNotEmpty) {
              final childState = context.read<ParentChildCubit>().state;
              // Skip while ParentChildCubit is still resolving (e.g. right
              // after a persona switch, which calls invalidate() then
              // reloads asynchronously) — _syncToChild itself never guesses
              // at an unmatched conversation, but there's no point matching
              // against a null/stale selectedChild before it's ready; the
              // BlocListener above (or a later emission here) runs once it
              // actually resolves.
              if (!childState.isLoaded) return;
              _syncToChild(childState.selectedChild, state.conversations);
            }
          },
          builder: (context, state) {
            debugPrint(
              '[REALTIME-DEBUG][ParentConversationList] widget rebuilt | '
              'conversationCount=${state.conversations.length}',
            );
            return RefreshIndicator(
              onRefresh: _listCubit.refresh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.errorMessage != null)
                    _buildErrorBanner(state.errorMessage!),
                  Expanded(child: _buildThreadArea(state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: CustomTextWidget(
              text: message,
              fontSize: 12,
              fontColor: const Color(0xFFB71C1C),
              unlimitedLines: true,
            ),
          ),
          const SizedBox(width: 8),
          CustomTextWidget(
            text: 'Pull to retry',
            fontSize: 11,
            fontColor: const Color(0xFFE53935),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadArea(ConversationListState state) {
    final selected = _selectedConversation;

    if (selected == null) {
      if (state.isLoading) {
        return const ChatThreadShimmer();
      }
      if (state.errorMessage != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.grey.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              const CustomTextWidget(
                text: 'Could not load conversations',
                fontSize: 15,
                fontColor: Colors.grey,
              ),
              const SizedBox(height: 8),
              const CustomTextWidget(
                text: 'Pull down to try again',
                fontSize: 13,
                fontColor: Colors.grey,
              ),
            ],
          ),
        );
      }
      // No conversation yet for this child — show the same card layout as the
      // active thread but with a "no conversation" placeholder instead of bubbles.
      return _buildNoConversationThread(context);
    }

    // Provide a dedicated CommunicationCubit for the thread so its state
    // (messages) is isolated from any outer cubit used for the list.
    return BlocProvider<CommunicationCubit>(
      create: (_) => serviceLocator<CommunicationCubit>(),
      child: ParentMessagingThread(
        key: ValueKey(selected.code),
        parentInfo: _buildParentInfo(selected),
        showOwnScaffold: false,
        isGuardian: true,
      ),
    );
  }

  /// Shows the same card layout as the active thread but with a centered
  /// "not yet created" placeholder in the message area.
  Widget _buildNoConversationThread(BuildContext context) {
    final childName =
        context.read<ParentChildCubit>().state.selectedChild?.name ?? '';
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF4F7FD),
            ),
            child: Column(
              children: [
                // Header — mirrors _buildParticipantHeader in the thread
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          childName.isNotEmpty
                              ? childName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextWidget(
                          text: childName.isNotEmpty ? childName : 'Student',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab bar placeholder
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'Group',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE9ECEF)),
                // Centered empty state
                Expanded(
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
                        const CustomTextWidget(
                          text: 'Room Chat not yet created',
                          fontSize: 15,
                          fontColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ChatInputBar(
              controller: _emptyInputController,
              focusNode: _emptyInputFocus,
              onSend: () {},
              onAttachmentTap: () {},
              pendingAttachments: const [],
              quotedMessage: null,
              onCancelQuote: () {},
              onRemoveAttachment: (_) {},
              editingMessage: null,
              onCancelEdit: () {},
            ),
          ),
        ),
      ],
    );
  }
}
