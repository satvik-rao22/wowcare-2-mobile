import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment, Message;
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_bubble_widget.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/message_entity_mapper.dart';

/// Builds a lightweight quoted [Message] from the denormalized reply context
/// (threadParentText / threadParentSender*) carried on [reply] itself, for when
/// the original message isn't in the loaded list (older, or just-arrived live).
/// The bubble only needs the quoted text + sender to render the quote preview.
Message? _denormalizedQuote(MessageEntity reply, String currentUserCode) {
  final code = reply.threadParentCode;
  final text = reply.threadParentText;
  if (code == null || code.isEmpty || text == null || text.isEmpty) return null;
  return Message(
    id: '',
    code: code,
    text: text,
    isSentByMe: reply.threadParentSenderCode == currentUserCode,
    time: reply.sentAt,
    senderName: reply.threadParentSenderName,
    senderUserCode: reply.threadParentSenderCode,
  );
}

/// Active recipients = participants still in the conversation (leftAt == null), excluding the
/// sender/current user. Drives the group read/delivered tick: a group message is delivered/read
/// only once ALL of these have delivered/read it.
int _activeRecipientCount(ConversationEntity? conversation, String currentUserCode) {
  if (conversation == null) return 0;
  return conversation.participants
      .where((p) => p.leftAt == null && p.userCode != currentUserCode)
      .length;
}

/// Renders a single [MessageBubble] driven by its own [BlocSelector] over
/// [ConversationThreadCubit], rather than the [MessageEntity] handed down
/// from the thread screen's top-level `BlocConsumer`.
///
/// Mirrors `ThreadMessageTile`'s pattern (the legacy/v1 equivalent over
/// [CommunicationCubit]) for the v2 stack: reactions, edits, deletes, and
/// read/delivery receipts all emit a brand-new [ConversationThreadState] for
/// the whole thread — without this, every visible bubble rebuilds on every
/// such change, even ones the mutation didn't touch. [MessageEntity] is
/// `Equatable`, so this selector's default `previous != current` check means
/// only the bubble whose own message (or quoted message) actually changed
/// value ever re-renders.
class EntityMessageTile extends StatelessWidget {
  const EntityMessageTile({
    super.key,
    required this.messageCode,
    required this.quotedMessageCode,
    required this.isGrouped,
    required this.reactionsController,
    required this.currentUserCode,
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
    this.isParentMessaging = false,
    this.senderIsOrgSide,
  });

  final String messageCode;
  final String? quotedMessageCode;
  final bool isGrouped;
  final ReactionsController reactionsController;
  final String currentUserCode;
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
  final bool isParentMessaging;

  /// See [MessageBubble.senderIsOrgSide].
  final bool? senderIsOrgSide;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ConversationThreadCubit,
      ConversationThreadState,
      _EntityBubbleSnapshot?
    >(
      selector: (state) {
        MessageEntity? message;
        MessageEntity? quoted;
        for (final m in state.messages) {
          if (m.code == messageCode) message = m;
          if (quotedMessageCode != null && m.code == quotedMessageCode) {
            quoted = m;
          }
        }
        if (message == null) return null;
        return _EntityBubbleSnapshot(message, quoted);
      },
      builder: (context, snapshot) {
        if (snapshot == null) return const SizedBox.shrink();
        final recipientCount = _activeRecipientCount(
          context.read<ConversationThreadCubit>().state.conversation,
          currentUserCode,
        );
        final message = mapMessageEntityToMessage(
          snapshot.message,
          currentUserCode,
          recipientCount: recipientCount,
        );
        // Prefer the full quoted message (found in the loaded list); otherwise
        // fall back to the denormalized quote context carried on the reply
        // itself (threadParentText/Sender…). Without this fallback a reply whose
        // original message isn't currently loaded — or that just arrived live —
        // rendered with no quote bubble.
        final quotedMessage = snapshot.quoted != null
            ? mapMessageEntityToMessage(snapshot.quoted!, currentUserCode)
            : _denormalizedQuote(snapshot.message, currentUserCode);
        return MessageBubble(
          message: message,
          isDeleted: snapshot.message.isDeleted,
          quotedMessage: quotedMessage,
          currentUserCode: currentUserCode,
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
          isParentMessaging: isParentMessaging,
          isGrouped: isGrouped,
          senderIsOrgSide: senderIsOrgSide,
        );
      },
    );
  }
}

class _EntityBubbleSnapshot extends Equatable {
  const _EntityBubbleSnapshot(this.message, this.quoted);

  final MessageEntity message;
  final MessageEntity? quoted;

  @override
  List<Object?> get props => [message, quoted];
}
