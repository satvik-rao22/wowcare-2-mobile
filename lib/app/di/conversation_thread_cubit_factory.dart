import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_thread_cubit.dart';

/// DI wiring for [ConversationThreadCubit], kept OUT of the presentation layer
/// (Mandate 5: views/routes reference no `serviceLocator`).
///
/// Every dependency is resolved from the service locator exactly as
/// `ConversationThreadScreen`'s `initState` used to resolve it inline — same
/// registered instances, same construction, same argument values. The screen
/// now calls this builder instead of newing the cubit itself, so its carefully
/// ordered start-up sequence (and cubit ownership/`close()`) is unchanged; only
/// the `serviceLocator` calls have moved here, into the app DI layer.
ConversationThreadCubit buildConversationThreadCubit({
  required ConversationEntity conversation,
  required String currentUserCode,
  bool isDraft = false,
  Future<ConversationEntity?> Function()? onResolveConversation,
}) {
  return ConversationThreadCubit(
    conversationCode: conversation.code,
    currentUserCode: currentUserCode,
    // Seed the full conversation so the realtime listener uses THIS
    // conversation's own org/school for the Firestore path — matches the
    // previous inline construction.
    conversation: conversation,
    watchMessagesUseCase: serviceLocator(),
    getMessagesUseCase: serviceLocator(),
    sendMessageUseCase: serviceLocator(),
    editMessageUseCase: serviceLocator(),
    deleteMessageUseCase: serviceLocator(),
    deleteAttachmentUseCase: serviceLocator(),
    getMessageReceiptsUseCase: serviceLocator(),
    addReactionUseCase: serviceLocator(),
    removeReactionUseCase: serviceLocator(),
    markConversationReadUseCase: serviceLocator(),
    attachmentUploader: serviceLocator(),
    cacheDraftMessageUseCase: serviceLocator(),
    markDraftMessageFailedUseCase: serviceLocator(),
    getCachedMessagesEntityUseCase: serviceLocator(),
    storageService: serviceLocator(),
    conversationRepository: serviceLocator(),
    getClassroomRosterUseCase: serviceLocator(),
    isDraft: isDraft,
    onResolveConversation: onResolveConversation,
  );
}
