import 'package:wowcare/core/network/api_logger.dart';

import '../../../../core/network/api_client.dart';
import '../models/create_conversation_request.dart';
import '../models/conversation_model.dart';
import '../models/create_conversation_response.dart';
import '../models/get_conversations_response.dart';
import '../models/message_model.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<MessageModel>> getMessages(String threadId, {String? currentUserId});
  Future<MessageModel> sendMessage(String threadId, MessageModel message);
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
  Future<void> addReaction(String messageId, String emoji);
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

    ApiLogger.logResponse(url: endpoint, method: 'GET');

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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return message; // In mock, we just return what was sent
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
      ApiLogger.logResponse(
        url: endpoint,
        method: 'POST',
        statusCode: response.statusCode,
        data: response.data,
      );
      return apiResponse.data!;
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

    ApiLogger.logResponse(url: endpoint, method: 'GET');

    return GetConversationsResponse.fromJson(response.data);
  }

  @override
  Future<void> addReaction(String messageId, String emoji) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/$messageId/react',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.post(
      endpoint,
      data: {'emoji': emoji},
    );

    ApiLogger.logResponse(
      url: endpoint,
      method: 'POST',
      statusCode: response.statusCode,
      data: response.data,
    );
  }
}
