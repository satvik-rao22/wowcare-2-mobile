import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';

/// DI wiring for [ConversationListCubit], kept OUT of the presentation layer
/// (Mandate 5: views reference no `serviceLocator`).
///
/// Resolves every dependency from the service locator exactly as the list
/// screens used to resolve them inline — same registered instances, same
/// construction. Callers that own the cubit (nested list widgets) keep owning
/// it; only the `serviceLocator` calls have moved here into the app DI layer.
ConversationListCubit buildConversationListCubit({
  required ConversationType conversationType,
}) {
  return ConversationListCubit(
    conversationType: conversationType,
    watchConversationsUseCase: serviceLocator(),
    getConversationsUseCase: serviceLocator(),
    getCachedConversationsUseCase: serviceLocator(),
    conversationRepository: serviceLocator(),
    storageService: serviceLocator(),
    createOrOpenConversationUseCase: serviceLocator(),
    getTagNameCodeMapUseCase: serviceLocator(),
  );
}
