import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/role_aware_ownership.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_bubble_widget.dart';

/// Renders a single [MessageBubble] driven by its own [BlocSelector] over
/// [CommunicationCubit], rather than the [Message] handed down from the
/// thread screen's top-level `BlocBuilder`.
///
/// Reactions, edits, deletes, and read/delivery receipts all emit a
/// brand-new [CommunicationLoaded] for the whole thread — without this,
/// every visible bubble rebuilds on every such change, even ones the
/// mutation didn't touch. [Message] is `Equatable`, so this selector's
/// default `previous != current` check means only the bubble whose own
/// message (or quoted message) actually changed value ever re-renders.
class ThreadMessageTile extends StatelessWidget {
  const ThreadMessageTile({
    super.key,
    required this.threadId,
    required this.messageCode,
    required this.quotedMessageId,
    required this.isGrouped,
    required this.reactionsController,
    this.currentUserCode,
    this.onScrollToQuoted,
    this.onReply,
    this.onReplyFromMenu,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onInfo,
    this.onDeleteAttachment,
    this.onReactionAdded,
    this.onRemoveReaction,
    this.onReactionTap,
    this.onReactionsInfoTap,
    this.onRetry,
    this.isParentMessaging = false,
    this.isInactive = false,
    this.senderIsOrgSide,
    this.viewerIsOrgSide,
    this.participants,
    this.isGuardian,
  });

  final String threadId;
  final String messageCode;
  final String? quotedMessageId;
  final bool isGrouped;
  final ReactionsController reactionsController;
  final String? currentUserCode;
  final List<ConversationParticipant>? participants;

  /// Which persona the CURRENT screen instance is showing — see
  /// `ParentMessagingThread.isGuardian` and [withRoleAwareOwnership]. Null
  /// (the default, used by `StaffMessagingThread`'s always-1:1 threads,
  /// where persona ambiguity can't arise) skips the role-aware correction
  /// entirely, preserving the plain userCode-only ownership check.
  final bool? isGuardian;
  final void Function(String quotedId)? onScrollToQuoted;
  final VoidCallback? onReply;
  final VoidCallback? onReplyFromMenu;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onInfo;
  final void Function(ChatAttachment attachment)? onDeleteAttachment;
  final void Function(String emoji)? onReactionAdded;
  final void Function(String emoji)? onRemoveReaction;
  final VoidCallback? onReactionTap;
  final VoidCallback? onReactionsInfoTap;

  /// See [MessageBubble.onRetry]. Called with the failed/still-uploading
  /// [Message] itself so the caller can invoke
  /// `CommunicationCubit.retrySendMessage(threadId, message)`.
  final void Function(Message message)? onRetry;
  final bool isParentMessaging;
  final bool isInactive;

  /// See [MessageBubble.senderIsOrgSide].
  final bool? senderIsOrgSide;

  /// See [MessageBubble.viewerIsOrgSide].
  final bool? viewerIsOrgSide;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CommunicationCubit,
      CommunicationState,
      _BubbleSnapshot?
    >(
      selector: (state) {
        if (state is! CommunicationLoaded) return null;
        final thread = state.threads[threadId];
        if (thread == null) return null;

        Message? message;
        Message? quoted;
        for (final m in thread) {
          if (m.code == messageCode) message = m;
          // [quotedMessageId] is id-shaped when it came from the REST API's
          // `replyToMessageId`, but code-shaped when it came from a live
          // Firestore delta (`threadParentCode`/`parentMessageCode` — see
          // MessageFirestoreItem.fromFirestore and _mergeRealtimeMessage).
          // Matching only `m.id` silently never found the quoted message
          // for a reply that arrived live, so the reply preview never
          // rendered until a REST refresh replaced it with an id-shaped
          // value — match both identifier schemes instead.
          if (quotedMessageId != null &&
              (m.id == quotedMessageId || m.code == quotedMessageId)) {
            quoted = m;
          }
        }
        if (message == null) return null;
        final viewerPersona = isGuardian;
        if (viewerPersona != null) {
          message = withRoleAwareOwnership(
            message,
            viewingAsGuardian: viewerPersona,
          );
          if (quoted != null) {
            quoted = withRoleAwareOwnership(
              quoted,
              viewingAsGuardian: viewerPersona,
            );
          }
        }
        return _BubbleSnapshot(message, quoted);
      },
      builder: (context, snapshot) {
        if (snapshot == null) return const SizedBox.shrink();
        return MessageBubble(
          // Forces a fresh element (not an in-place patch) whenever which
          // side this bubble renders on changes for the same message code —
          // e.g. a cached message re-aligning once a corrected isMine value
          // arrives. Patching a mounted bubble's Row(textDirection: …)/Align
          // in place for a structural side flip is what was triggering
          // Flutter's semantics `parentDataDirty` assertion.
          key: ValueKey(
            '${snapshot.message.code}-${snapshot.message.isSentByMe}',
          ),
          message: snapshot.message,
          isDeleted: snapshot.message.isDeleted,
          quotedMessage: snapshot.quoted,
          currentUserCode: currentUserCode,
          participants: participants,
          reactionsController: reactionsController,
          onScrollToQuoted: onScrollToQuoted,
          onReply: onReply,
          onReplyFromMenu: onReplyFromMenu,
          onCopy: onCopy,
          onEdit: onEdit,
          onDelete: onDelete,
          onInfo: onInfo,
          onDeleteAttachment: onDeleteAttachment,
          onReactionAdded: onReactionAdded,
          onRemoveReaction: onRemoveReaction,
          onReactionTap: onReactionTap,
          onReactionsInfoTap: onReactionsInfoTap,
          onRetry:
              (snapshot.message.isFailed ||
                  snapshot.message.hasProcessingAttachments)
              ? () => onRetry?.call(snapshot.message)
              : null,
          isParentMessaging: isParentMessaging,
          isInactive: isInactive,
          isGrouped: isGrouped,
          senderIsOrgSide: senderIsOrgSide,
          viewerIsOrgSide: viewerIsOrgSide,
        );
      },
    );
  }
}

class _BubbleSnapshot extends Equatable {
  const _BubbleSnapshot(this.message, this.quoted);

  final Message message;
  final Message? quoted;

  @override
  List<Object?> get props => [message, quoted];
}
