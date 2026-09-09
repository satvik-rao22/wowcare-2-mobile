import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment;
import 'package:wowcare/presentation/features/communication/view_model/composer_state.dart';

/// Holds the message-composer state (quote / edit / pending attachments) for a
/// thread screen, replacing the `setState` fields the three thread screens
/// each carried (Mandate 2, Bucket A). Generic over the message type [T] (see
/// [ComposerState]).
///
/// The `TextEditingController` deliberately stays in the view: it is a Flutter
/// controller, not screen state. On [startEdit] the view seeds the controller
/// text; on [cancelEdit] / [reset] the view clears it. This cubit owns only
/// the data (what is quoted, what is being edited, which attachments are
/// staged) so that data survives a widget rebuild and is testable in isolation.
class ComposerCubit<T extends Object> extends Cubit<ComposerState<T>> {
  ComposerCubit() : super(ComposerState<T>());

  /// Reply to [message]. Replaces any existing quote; leaves an in-progress
  /// edit and staged attachments untouched.
  void quote(T message) {
    emit(
      ComposerState<T>(
        quotedMessage: message,
        editingMessage: state.editingMessage,
        pendingAttachments: state.pendingAttachments,
      ),
    );
  }

  /// Cancel the current reply. No-op when not quoting.
  void clearQuote() {
    if (state.quotedMessage == null) return;
    emit(
      ComposerState<T>(
        editingMessage: state.editingMessage,
        pendingAttachments: state.pendingAttachments,
      ),
    );
  }

  /// Begin editing [message]. The view is responsible for seeding the
  /// controller with the message text.
  void startEdit(T message) {
    emit(
      ComposerState<T>(
        quotedMessage: state.quotedMessage,
        editingMessage: message,
        pendingAttachments: state.pendingAttachments,
      ),
    );
  }

  /// Cancel the in-progress edit. No-op when not editing.
  void cancelEdit() {
    if (state.editingMessage == null) return;
    emit(
      ComposerState<T>(
        quotedMessage: state.quotedMessage,
        pendingAttachments: state.pendingAttachments,
      ),
    );
  }

  /// Append newly picked [attachments] to the staged list. No-op when empty.
  void addAttachments(List<ChatAttachment> attachments) {
    if (attachments.isEmpty) return;
    emit(
      ComposerState<T>(
        quotedMessage: state.quotedMessage,
        editingMessage: state.editingMessage,
        pendingAttachments: [...state.pendingAttachments, ...attachments],
      ),
    );
  }

  /// Remove the staged attachment at [index]. No-op for an out-of-range index.
  void removeAttachment(int index) {
    if (index < 0 || index >= state.pendingAttachments.length) return;
    final next = [...state.pendingAttachments]..removeAt(index);
    emit(
      ComposerState<T>(
        quotedMessage: state.quotedMessage,
        editingMessage: state.editingMessage,
        pendingAttachments: next,
      ),
    );
  }

  /// Clear everything — used after a successful send.
  void reset() {
    if (state.isEmpty) return;
    emit(ComposerState<T>());
  }
}
