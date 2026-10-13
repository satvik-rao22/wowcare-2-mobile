import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/communication_providers.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';
import 'package:wowcare/app/di/conversation_list_cubit_factory.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_state.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

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
  const ParentDirectMessagingScreen({
    super.key,
    this.conversationType = ConversationType.roomChat,
    this.notCreatedLabel = AppStrings.roomChatNotCreated,
  });

  /// Which student-scoped chat this is — ROOM_CHAT (default) or ADMIN_CHAT.
  /// The flow is identical; only the conversation type + empty-state label differ.
  final ConversationType conversationType;

  /// Empty-state heading shown when no conversation exists yet for the child.
  final String notCreatedLabel;

  @override
  State<ParentDirectMessagingScreen> createState() =>
      _ParentDirectMessagingScreenState();
}

class _ParentDirectMessagingScreenState
    extends State<ParentDirectMessagingScreen>
    with SchoolSwitchReloadMixin {
  late final ConversationListCubit _listCubit;
  // Screen view-state (Mandate 2): which conversation is shown, the draft
  // attachments, and the two loading flags. ValueNotifiers rather than
  // `setState` so the body rebuilds off one merged listenable — the same
  // triggers the removed setStates fired on.
  final ValueNotifier<ConversationEntity?> _selectedConversation =
      ValueNotifier<ConversationEntity?>(null);

  // Used only when no conversation exists yet — keeps the input bar visible
  // and lets the parent draft the first message (text + attachments) before
  // any conversation has been created server-side.
  final HtmlAwareTextController _emptyInputController =
      HtmlAwareTextController();
  final FocusNode _emptyInputFocus = FocusNode();
  final ValueNotifier<List<ChatAttachment>> _pendingNewConversationAttachments =
      ValueNotifier<List<ChatAttachment>>([]);
  final ValueNotifier<bool> _isStartingConversation = ValueNotifier<bool>(
    false,
  );

  // Authoritative, server-side resolve of the existing conversation for the
  // selected child. The Firestore/Isar list match (_syncToChild) can be stale
  // (cached before a backfill), missing a denormalized field, or simply race
  // the first frame — which made an existing chat open in the "start a chat"
  // draft view. This lookup is the source of truth; while it's in flight we
  // hold the shimmer instead of prematurely showing the draft view.
  String? _resolvedForChildCode;
  final ValueNotifier<bool> _resolvingExistence = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // Cubit deps resolved by an app-DI factory (Mandate 5: no serviceLocator in
    // views). This State still owns/closes the cubit — only construction moved.
    _listCubit = buildConversationListCubit(
      conversationType: widget.conversationType,
    );
    _listCubit.startWatching();
    // If a child is already selected when this screen mounts, the child listener
    // won't fire a transition — resolve its existing conversation from the server
    // directly so we don't briefly show the draft view for an existing chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolveExistingConversation(
        context.read<ParentChildCubit>().state.selectedChild,
      );
    });
  }

  @override
  void dispose() {
    _listCubit.close();
    _emptyInputController.dispose();
    _emptyInputFocus.dispose();
    _selectedConversation.dispose();
    _pendingNewConversationAttachments.dispose();
    _isStartingConversation.dispose();
    _resolvingExistence.dispose();
    super.dispose();
  }

  /// This screen is kept alive in the shell's IndexedStack across a persona
  /// switch (e.g. admin <-> guardian for the same account/school) — it never
  /// re-mounts on its own, so [_listCubit]'s Firestore subscription, opened
  /// once in [initState], would otherwise keep resolving unread counts under
  /// the persona active when this screen was FIRST built rather than the one
  /// now active. Restarting it re-reads the current persona (see
  /// ConversationEntityRepositoryImpl's `_unreadRoleBucket`) so an
  /// ADMIN_CHAT conversation's unreadByRole-based count updates for the
  /// persona actually looking at it now. Also re-runs the authoritative
  /// existence lookup for the current child, since that too was gated on
  /// "already resolved for this child code" and would otherwise skip
  /// re-checking after switching back to a persona that can see this
  /// conversation type.
  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    unawaited(_listCubit.startWatching());
    _resolvedForChildCode = null;
    _resolveExistingConversation(
      context.read<ParentChildCubit>().state.selectedChild,
    );
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

    if (explicit || match?.code != _selectedConversation.value?.code) {
      _selectedConversation.value = match;
    }
  }

  /// Authoritatively resolve the child's existing conversation from the server
  /// (the same lookup the send flow uses), independent of the Firestore/Isar
  /// list. This is what prevents an existing chat from opening in the draft
  /// view when the list is stale or hasn't matched yet. Runs once per child.
  Future<void> _resolveExistingConversation(ParentChildRef? child) async {
    final code = child?.code.trim() ?? '';
    if (code.isEmpty || _resolvedForChildCode == code) return;
    _resolvedForChildCode = code;
    if (mounted) _resolvingExistence.value = true;

    final isAdmin = widget.conversationType == ConversationType.adminChat;
    final result = isAdmin
        ? await _listCubit.findAdminChatConversation(code)
        : await _listCubit.findRoomChatConversation(code);

    if (!mounted) return;
    // Ignore if the selected child changed while the lookup was in flight.
    final currentCode = context
        .read<ParentChildCubit>()
        .state
        .selectedChild
        ?.code
        .trim();
    if (currentCode != code) {
      _resolvingExistence.value = false;
      return;
    }
    result.fold(
      (
        _,
      ) {}, // on failure keep whatever the list match found; draft stays a fallback
      (conv) {
        if (conv != null && conv.code != _selectedConversation.value?.code) {
          _selectedConversation.value = conv;
        }
      },
    );
    _resolvingExistence.value = false;
  }

  /// Converts a v2 [ConversationEntity] into the legacy [parentInfo] map that
  /// [ParentMessagingThread] expects.

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
          _resolveExistingConversation(childState.selectedChild);
        },
        child: BlocConsumer<ConversationListCubit, ConversationListState>(
          listener: (context, state) {
            if (_selectedConversation.value == null &&
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
            // Rebuild on the view-state notifiers (selected conversation,
            // draft attachments, loading flags) alongside the cubit state.
            return ListenableBuilder(
              listenable: Listenable.merge([
                _selectedConversation,
                _resolvingExistence,
                _isStartingConversation,
                _pendingNewConversationAttachments,
              ]),
              builder: (context, _) {
                final childState = context.watch<ParentChildCubit>().state;
                debugPrint(
                  'ParentLoaded=${childState.isLoaded}, '
                  'ConversationLoading=${state.isLoading}, '
                  'SelectedConversation=${_selectedConversation.value?.code}',
                );
                final body = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.errorMessage != null)
                      _buildErrorBanner(state.errorMessage!),
                    Expanded(
                      child: _buildThreadArea(
                        state,
                        isChildLoaded: childState.isLoaded,
                      ),
                    ),
                  ],
                );
                // Once a thread is open, ParentMessagingThread owns its own
                // pull-to-refresh (refreshing messages AND, via
                // onRefreshConversationList below, this list) — wrapping it
                // again here would register two nested RefreshIndicators for
                // the same drag gesture, firing the list refresh twice while
                // neither necessarily wins the gesture cleanly. Only wrap here
                // for the loading/error/no-conversation states, which have no
                // refresh indicator of their own.
                final content = _selectedConversation.value != null
                    ? body
                    : CustomRefreshIndicator(
                        onRefresh: _listCubit.refresh,
                        child: body,
                      );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRefreshHeader(),
                    Expanded(child: content),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Discoverable manual refresh — mirrors the pull-to-refresh
  /// ([_listCubit.refresh]) so the parent isn't limited to the pull gesture,
  /// which isn't obvious and can't be triggered once a thread is open (that
  /// state owns its own pull-to-refresh instead — see the doc above where
  /// this is used). Matches the discoverable refresh icon on the
  /// staff/admin side (staff_messaging_tab.dart, admin_chat_host_screen.dart);
  /// this screen (Room Chat AND Admin Chat, for the parent persona — see
  /// [AdminChatHostScreen]) previously had no equivalent.
  Widget _buildRefreshHeader() {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.transparentColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            unawaited(_listCubit.refresh());
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Refreshing…',
              duration: const Duration(milliseconds: 1200),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSizes.xs),
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.messagingSearchFieldBg,
            ),
            child: const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.xs),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSizes.xsPlus),
      decoration: BoxDecoration(
        color: AppColors.messagingErrorSoftBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.messagingErrorSoftBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.messagingErrorRed, size: 18),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: CustomTextWidget(
              text: message,
              fontSize: 12,
              fontColor: AppColors.messagingErrorDarkText,
              unlimitedLines: true,
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          CustomTextWidget(
            text: AppStrings.pullToRetry,
            fontSize: 11,
            fontColor: AppColors.messagingErrorRed,
          ),
        ],
      ),
    );
  }

  Widget _buildThreadArea(
    ConversationListState state, {
    required bool isChildLoaded,
  }) {
    final selected = _selectedConversation.value;

    if (selected == null) {
      // Hold the shimmer while the list is loading, the child isn't ready, OR
      // the authoritative server existence-check is still in flight — so the
      // "start a chat" draft view only appears once we're sure none exists.
      if (state.isLoading || !isChildLoaded || _resolvingExistence.value) {
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
                color: AppColors.messagingIconMuted.withValues(alpha: 0.35),
              ),
              const SizedBox(height: AppSizes.sm),
              const CustomTextWidget(
                text: AppStrings.couldNotLoadConversations,
                fontSize: 15,
                fontColor: AppColors.messagingIconMuted,
              ),
              const SizedBox(height: AppSizes.xs),
              const CustomTextWidget(
                text: AppStrings.pullDownToTryAgain,
                fontSize: 13,
                fontColor: AppColors.messagingIconMuted,
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
    // Total active participants minus the viewer themselves — seeded so
    // this fresh cubit's read/delivered-by-all tick aggregation has a
    // recipient count to work with. See
    // CommunicationCubit.seedRecipientCount's own doc for why this is
    // required, not just an optimization.
    final recipientCount =
        selected.participants.where((p) => p.isActive).length - 1;
    return BlocProvider<CommunicationCubit>(
      create: (_) =>
          resolveCommunicationCubit()
            ..seedRecipientCount(selected.code, recipientCount),
      child: ParentMessagingThread(
        key: ValueKey(selected.code),
        parentInfo: buildParentThreadInfo(selected),
        showOwnScaffold: false,
        isGuardian: true,
        conversationType: widget.conversationType,
        // This screen no longer wraps the thread in its own
        // RefreshIndicator (see the builder above) — the thread's pull-to-
        // refresh triggers this too, so the list (and its cache) actually
        // updates instead of only the currently-open thread's messages.
        onRefreshConversationList: _listCubit.refresh,
      ),
    );
  }

  /// Attachment picker for the pre-conversation composer — mirrors
  /// [ParentMessagingThread._showAttachmentSheet] since there's no thread
  /// state yet to attach this to.
  void _showAttachmentSheetForNewConversation() {
    MessageAttachmentBottomSheet.show(
      context,
      onAttachmentsSelected: (attachments) {
        if (attachments.isEmpty) return;
        // Add to whatever's already staged — picking multiple photos/videos
        // together (or picking again before sending) must accumulate, not
        // discard everything but the newest single file.
        _pendingNewConversationAttachments.value = [
          ..._pendingNewConversationAttachments.value,
          ...attachments,
        ];
      },
      onEmojiSelected: (emoji) {
        final pos = _emptyInputController.selection.isValid
            ? _emptyInputController.selection.baseOffset
            : _emptyInputController.text.length;
        final text = _emptyInputController.text;
        _emptyInputController.value = _emptyInputController.value.copyWith(
          text: text.substring(0, pos) + emoji + text.substring(pos),
          selection: TextSelection.collapsed(offset: pos + emoji.length),
        );
      },
      // No participants to show yet — the conversation doesn't exist.
      onViewParticipants: null,
    );
  }

  /// Creates the Room Chat conversation for the selected child (idempotent —
  /// reuses an existing one if a race already created it) and sends the
  /// drafted text/attachment as its first message. This is the parent-side
  /// "conversation auto-creates on first send" flow — there is no separate
  /// "create conversation" step the parent has to do first.
  Future<void> _sendFirstMessage() async {
    if (_isStartingConversation.value) return;
    final text = _emptyInputController.text.trim();
    final attachments = _pendingNewConversationAttachments.value;
    if (text.isEmpty && attachments.isEmpty) return;

    final child = context.read<ParentChildCubit>().state.selectedChild;
    if (child == null) return;

    _isStartingConversation.value = true;

    // Same call shape as the Admin/Staff "start conversation" flow
    // (staff_messaging_tab.dart's room-chat branch): type + studentCode
    // only, participantCodes left empty. Participant computation (all
    // admins/directors + currently allowed classroom staff + all guardians)
    // happens server-side from studentCode alone, identically regardless of
    // which persona's client sent the request — so a parent-created Room
    // Chat ends up with the same full participant set as a staff-created
    // one.
    final createResult = await _listCubit.createOrOpenConversation(
      type: widget.conversationType,
      studentCode: child.code,
      classroomCode: child.classroomCode,
      participantCodes: const [],
      // Backend requires a non-empty title ("Title is required");
      // staff_messaging_tab.dart's equivalent call passes the
      // other party's display name — here that's the student's.
      title: child.name,
    );

    if (!mounted) return;

    await createResult.fold(
      (failure) async {
        _isStartingConversation.value = false;
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              failure.message ?? 'Could not start the conversation. Try again.',
          isError: true,
        );
      },
      (conversation) async {
        final parentInfo = buildParentThreadInfo(conversation);
        final authState = context.read<AuthCubit>().state;
        final senderName = authState is AuthLoaded
            ? authState.loginResponse.displayName
            : null;
        final storedUserCode = (await _listCubit.readCurrentUserCode() ?? '')
            .trim();
        final senderUserCode = authState is AuthLoaded
            ? authState.loginResponse.userCode
            : (storedUserCode.isNotEmpty ? storedUserCode : null);

        final receivers = <String>[
          ...parentInfo.staffList,
          ...parentInfo.parents,
        ];

        // A short-lived cubit just to drive this one send — the real,
        // long-lived per-thread cubit takes over once the screen swaps to
        // ParentMessagingThread below. MUST be awaited: `sendMessage` emits
        // more than once internally (an optimistic emit, then a
        // confirmed/failed emit once the POST resolves) — closing the cubit
        // right after firing it without awaiting raced that second emit
        // against `close()` below, crashing with "Bad state: Cannot emit new
        // states after calling close" and silently losing the very first
        // message a parent ever sends for a brand-new conversation.
        final sendCubit = resolveCommunicationCubit();
        await sendCubit.sendMessage(
          conversation.code,
          text,
          attachments: attachments,
          senderName: senderName,
          senderUserCode: senderUserCode,
          receivers: receivers,
        );

        if (!mounted) return;
        _isStartingConversation.value = false;
        _emptyInputController.clear();
        _pendingNewConversationAttachments.value = [];
        // Switch over to the real thread immediately rather than waiting
        // for the list stream to refresh — _listCubit.refresh() below
        // keeps the conversation list (sidebar/badges elsewhere) in sync,
        // but the screen itself shouldn't sit on the "not yet created"
        // placeholder while that round-trip happens.
        _selectedConversation.value = conversation;
        await sendCubit.close();
        unawaited(_listCubit.refresh());
      },
    );
  }

  /// Shows the same card layout as the active thread but with a centered
  /// "not yet created" placeholder in the message area.
  Widget _buildNoConversationThread(BuildContext context) {
    final selectedChild = context.read<ParentChildCubit>().state.selectedChild;
    final childName = selectedChild?.name ?? '';
    final childCode = selectedChild?.code;
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.messagingMessageBoxBg,
            ),
            child: Column(
              children: [
                // Header — mirrors _buildParticipantHeader in the thread
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.transparentColor,
                    border: Border(
                      bottom: BorderSide(color: AppColors.messagingBorderSubtle, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.xxs, AppSizes.xs),
                  child: Row(
                    children: [
                      DocumentImageWidget(
                        disableAttendanceStatusLookup: true,
                        fileUuid: '',
                        studentCode: (childCode ?? '').trim().isNotEmpty
                            ? childCode
                            : null,
                        name: childName,
                        size: 34,
                        fontSize: 15,
                      ),
                      const SizedBox(width: AppSizes.xsPlus),
                      Expanded(
                        child: CustomTextWidget(
                          text: childName.isNotEmpty ? childName : AppStrings.studentFallback,
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
                    horizontal: AppSizes.sm,
                    vertical: 6,
                  ),
                  child: Text(
                    AppStrings.group,
                    style: AppTextStyles.size14.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.messagingBorderSubtle),
                // Centered empty state
                Expanded(
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
                        CustomTextWidget(
                          text: widget.notCreatedLabel,
                          fontSize: 15,
                          fontColor: AppColors.messagingIconMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xsPlus),
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ChatInputBar(
              controller: _emptyInputController,
              focusNode: _emptyInputFocus,
              isSending: _isStartingConversation.value,
              onSend: _sendFirstMessage,
              onAttachmentTap: _showAttachmentSheetForNewConversation,
              pendingAttachments: _pendingNewConversationAttachments.value,
              quotedMessage: null,
              onCancelQuote: () {},
              onRemoveAttachment: (i) {
                final next = [..._pendingNewConversationAttachments.value]
                  ..removeAt(i);
                _pendingNewConversationAttachments.value = next;
              },
              editingMessage: null,
              onCancelEdit: () {},
            ),
          ),
        ),
      ],
    );
  }
}

/// Builds the thread info the parent-tab thread screen renders from a v2
/// conversation. Shared by the Messages tab and the staff recent-chat entry.
ParentThreadInfo buildParentThreadInfo(ConversationEntity conv) {
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
      joinedAt: AppTime.now(),
      // Was missing entirely — every participant defaulted to
      // leftAt: null / active: true regardless of the real backend
      // values, silently defeating every `isActive`-based filter/count
      // downstream (chip bars, "N participants" header, tab chips).
      leftAt: p.leftAt,
      active: p.active,
      muted: false,
      notificationsEnabled: true,
      createdAt: AppTime.now(),
      updatedAt: AppTime.now(),
      privateModeEnabled: conv.isPrivateModeEnabledFor(p.userCode),
      avatarUrl: p.avatarUrl,
      staffCode: p.staffCode,
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

  return ParentThreadInfo(
    name: conv.title,
    avatar: conv.avatarUrl,
    code: conv.code,
    // The conversation's own org/school — used to build the realtime
    // (Firestore) watch path correctly even when the session's currently
    // active org/school differs (multi-school parent, recent switch).
    organizationCode: conv.organizationCode,
    schoolCode: conv.schoolCode,
    parents: parentNames,
    guardianMap: {
      for (final guardian in guardians) guardian.userCode: guardian.userName,
    },
    participants: legacyParticipants,
    staffList: staffCodes,
    privateModeParents: privateModeParentNames,
    privateModeActive: conv.privateModeActive,
    privateModeActivatedBy: conv.privateModeActivatedBy,
    privateModeActivatedAt: conv.privateModeActivatedAt,
    studentStatus: conv.studentStatus,
  );
}
