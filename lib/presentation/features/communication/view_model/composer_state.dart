import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment;

/// The editable state of a message composer: the message being replied to
/// (quoted), the message being edited, and the not-yet-sent attachments.
///
/// Extracted from the three thread screens (staff / parent / conversation),
/// which each held this same cluster in `setState` fields (Mandate 2, Bucket
/// A). Generic over the message type [T] because the screens model a message
/// differently — the two staff/parent threads use `Message`, the conversation
/// thread uses `MessageEntity` — while all stage the same [ChatAttachment].
/// The full message is the single source of truth for a quote or an edit;
/// callers read `.id`/`.code` off it rather than tracking a separate id.
class ComposerState<T extends Object> extends Equatable {
  const ComposerState({
    this.quotedMessage,
    this.editingMessage,
    this.pendingAttachments = const [],
  });

  /// The message the draft is replying to, or null when not replying.
  final T? quotedMessage;

  /// The message currently being edited, or null when composing a new one.
  final T? editingMessage;

  /// Attachments picked for the draft but not yet sent.
  final List<ChatAttachment> pendingAttachments;

  bool get hasAttachments => pendingAttachments.isNotEmpty;
  bool get isQuoting => quotedMessage != null;
  bool get isEditing => editingMessage != null;
  bool get isEmpty =>
      quotedMessage == null && editingMessage == null && pendingAttachments.isEmpty;

  @override
  List<Object?> get props => [quotedMessage, editingMessage, pendingAttachments];
}
