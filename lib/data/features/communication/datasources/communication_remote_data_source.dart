import '../../../../core/network/api_client.dart';
import '../models/create_conversation_request.dart';
import '../models/conversation_model.dart';
import '../models/create_conversation_response.dart';
import '../models/get_conversations_response.dart';
import '../models/message_model.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<MessageModel>> getMessages(
    String threadId, {
    String? currentUserId,
  });
  Future<MessageModel> sendMessage(String threadId, MessageModel message);
  Future<MessageModel> editMessage(String messageCode, String content);
  Future<void> markAsRead(String threadId, String messageId);
  Future<String> uploadAttachment(ChatAttachmentModel attachment);
  Future<ConversationModel> createConversation(
    CreateConversationRequest request,
  );
  Future<GetConversationsResponse> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  });
  Future<void> addReaction(String messageCode, String emoji);
}

class CommunicationRemoteDataSourceImpl
    implements CommunicationRemoteDataSource {
  final ApiClient apiClient;

  CommunicationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MessageModel>> getMessages(
    String threadId, {
    String? currentUserId,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/conversation/$threadId?page=0&size=50&sort=createdAt,asc',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.get(endpoint);

    if (response.data != null && response.data['success'] == true) {
      final List<dynamic> messagesJson = response.data['data']['messages'];
      return messagesJson
          .map(
            (json) => MessageModel.fromJson(
              json as Map<String, dynamic>,
              currentUserId: currentUserId,
            ),
          )
          .toList();
    } else {
      throw Exception(response.data?['message'] ?? 'Failed to load messages');
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String threadId,
    MessageModel message,
  ) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingMessages,
      ApiConstants.communicationBaseUrl,
    );

    final body = {
      'conversationCode': threadId,
      'type': 'TEXT',
      'content': message.text,
      if (message.quotedMessageId != null)
        'replyToMessageId': message.quotedMessageId,
    };

    final response = await apiClient.client.post(endpoint, data: body);

    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final parsed = MessageModel.fromJson(data);
      // The sender is always the current user for outbound messages.
      return MessageModel(
        id: parsed.id,
        code: parsed.code,
        conversationCode: parsed.conversationCode,
        senderUserCode: parsed.senderUserCode,
        text: parsed.text,
        isSentByMe: true,
        time: parsed.time,
        quotedMessageId: parsed.quotedMessageId,
        attachments: parsed.attachments,
        reactions: parsed.reactions,
        senderName: parsed.senderName,
      );
    } else {
      throw Exception(response.data?['message'] ?? 'Failed to send message');
    }
  }

  @override
  Future<MessageModel> editMessage(String messageCode, String content) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/$messageCode',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.put(
      endpoint,
      data: {'content': content},
    );

    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final parsed = MessageModel.fromJson(data);
      return MessageModel(
        id: parsed.id,
        code: parsed.code,
        conversationCode: parsed.conversationCode,
        senderUserCode: parsed.senderUserCode,
        text: parsed.text,
        isSentByMe: true,
        time: parsed.time,
        quotedMessageId: parsed.quotedMessageId,
        attachments: parsed.attachments,
        reactions: parsed.reactions,
        senderName: parsed.senderName,
      );
    } else {
      throw Exception(response.data?['message'] ?? 'Failed to edit message');
    }
  }

  @override
  Future<void> markAsRead(String threadId, String messageId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<String> uploadAttachment(ChatAttachmentModel attachment) async {
    await Future.delayed(const Duration(seconds: 1));
    return "https://example.com/mock-upload/${attachment.name}";
  }

  @override
  Future<ConversationModel> createConversation(
    CreateConversationRequest request,
  ) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingCreateMessage,
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.post(
      endpoint,
      data: request.toJson(),
    );

    final apiResponse = CreateConversationResponse.fromJson(response.data);

    if (apiResponse.success && apiResponse.data != null) {
      final conversation = apiResponse.data!;

      // Some backends accept `initialMessage` in the create request but don't
      // actually create a first message (response shows lastMessageAt/Preview null).
      // Ensure the first message exists by sending it explicitly.
      final initial = request.initialMessage.trim();
      if (initial.isNotEmpty) {
        try {
          final messageEndpoint = ApiPaths.urlWithBase(
            ApiPaths.messagingMessages,
            ApiConstants.communicationBaseUrl,
          );
          await apiClient.client.post(
            messageEndpoint,
            data: {
              'conversationCode': conversation.code,
              'type': 'TEXT',
              'content': initial,
            },
          );
        } catch (_) {
          // Conversation is created; message send can be retried separately.
        }
      }

      return conversation;
    } else {
      throw Exception(apiResponse.message);
    }
  }

  @override
  Future<GetConversationsResponse> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    final path = type != null
        ? '${ApiPaths.messagingCreateMessage}/type/$type'
        : ApiPaths.messagingCreateMessage;

    final endpoint = ApiPaths.urlWithBase(
      '$path?status=$status&page=$page&size=$size',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.get(endpoint);

    return GetConversationsResponse.fromJson(response.data);
  }

  @override
  Future<void> addReaction(String messageCode, String emoji) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/$messageCode/reactions',
      ApiConstants.communicationBaseUrl,
    );

    await apiClient.client.post(endpoint, data: {'emoji': emoji});
  }
}
