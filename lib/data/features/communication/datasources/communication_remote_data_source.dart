import 'package:dio/dio.dart';
import '../../../../app/di/di.dart';
import '../../../../core/network/api_client.dart';
import '../models/create_conversation_request.dart';
import '../models/conversation_model.dart';
import '../models/create_conversation_response.dart';
import '../models/get_conversations_response.dart';
import '../models/message_model.dart';
import '../models/edit_message_request.dart';
import '../models/message_reaction_request.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/user_details_school_roles.dart';

abstract class CommunicationRemoteDataSource {
  Future<List<MessageModel>> getMessages(
    String threadId, {
    String? currentUserId,
    int page = 0,
    int size = 100,
  });
  Future<MessageModel> sendMessage(String threadId, MessageModel message);
  Future<MessageModel> editMessage(String messageCode, String content);
  Future<void> markAsRead(String threadId, String messageId);
  Future<void> markAllAsDelivered(String threadId);
  Future<ConversationModel> createConversation(
    CreateConversationRequest request,
  );

  /// Mirrors the backend's `getConversationsByType` filter contract
  /// (`classroomCodes`, `tagCodes`, `designations`, `studentStatuses`,
  /// `staffStatuses`, `search`) — the same shape the student/staff list
  /// endpoints already use.
  Future<GetConversationsResponse> getConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
  });
  Future<GetConversationsResponse> searchConversations({
    required String query,
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 50,
  });
  Future<void> addReaction(String messageCode, String emoji);
  Future<void> deleteMessage(String messageCode);
  Future<void> removeReaction(String messageCode, String emoji);
  Future<void> deleteAttachment(int attachmentId);

  /// Per-conversation unread counts, keyed by conversation code. Backed by
  /// `/messages/unread-per-conversation` — confirmed reliable (unlike the
  /// conversation-list endpoint's own `unreadCount` field).
  Future<Map<String, int>> getUnreadCountsPerConversation();

  /// Full per-recipient-per-persona receipts for one message — see
  /// [ApiPaths.messagingMessageReceipts]'s doc comment for why this is
  /// fetched separately from the message list's own lighter `receipts`
  /// field. One network call; [parseRecipientStatuses] splits the same raw
  /// payload into delivered-only vs read.
  Future<({List<RecipientStatus> deliveredTo, List<RecipientStatus> readBy})>
  getMessageReceipts(String messageCode);
}

class CommunicationRemoteDataSourceImpl
    implements CommunicationRemoteDataSource {
  final ApiClient apiClient;

  CommunicationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MessageModel>> getMessages(
    String threadId, {
    String? currentUserId,
    int page = 0,
    int size = 100,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/conversation/$threadId?page=$page&size=$size&sort=createdAt,asc',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.get(endpoint);

    if (response.data != null && response.data['success'] == true) {
      final dataMap = response.data['data'] as Map<String, dynamic>?;
      final List<dynamic> messagesJson =
          (dataMap?['messages'] as List<dynamic>?) ?? [];
      // ignore: avoid_print
      print(
        '[Messages] conversation=$threadId page=$page received=${messagesJson.length}',
      );
      final messages = messagesJson
          .map(
            (json) => MessageModel.fromJson(
              json as Map<String, dynamic>,
              currentUserId: currentUserId,
            ),
          )
          .toList();
      // ignore: avoid_print
      print('[Messages] mapped=${messages.length}');

      // Marking-as-read only makes sense for the latest window (page 0) —
      // an older-history page fetch shouldn't re-trigger it.
      if (page == 0) {
        try {
          final readEndpoint = ApiPaths.urlWithBase(
            ApiPaths.messagingConversationMarkRead(threadId),
            ApiConstants.communicationBaseUrl,
          );
          await apiClient.client.post(readEndpoint);
        } catch (_) {}
      }

      return messages;
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

    // The messaging service tracks attachments by its own integer id
    // (assigned when the asset is registered against the conversation —
    // see ChatAttachmentUploader.upload), not by the document service's
    // asset `code`. It also expects `type: TEXT` even for attachment-only
    // messages — confirmed against the working web-app request.
    final attachmentIds = message.attachments
        .map((a) => a.attachmentId)
        .whereType<int>()
        .toList();

    // Belt-and-suspenders alongside the x-role header: the messaging service
    // has been observed attributing a sent message to a dual-role account's
    // OTHER persona (e.g. GUARDIAN) even when the request headers are
    // unambiguously the active persona (e.g. ORGANIZATION_ADMIN) — mirrors
    // why the notification inbox needed an explicit `role` param, not just
    // the header, to get a correctly-scoped response. Uses the same active-
    // persona resolution as the header itself, so the two can never disagree.
    final activeRole = await resolveActiveBackendRole(
      serviceLocator<StorageService>(),
    );

    final body = {
      'conversationCode': threadId,
      'type': 'TEXT',
      'content': message.text,
      if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
      if (message.quotedMessageId != null)
        'replyToMessageId': message.quotedMessageId,
      if (message.isPrivate) 'isPrivate': true,
      // Scope the private message to the target guardian's thread. Without this a STAFF/ADMIN
      // private message has no target, so the backend stores it as a normal (group) message and
      // it shows up in the Group tab; a guardian's own message also loses its thread scope.
      if (message.privateParentUserCode != null &&
          message.privateParentUserCode!.isNotEmpty)
        'privateParentUserCode': message.privateParentUserCode,
      if (activeRole.isNotEmpty) 'role': activeRole,
    };

    final response = await apiClient.client.post(endpoint, data: body);

    if (response.data != null && response.data['success'] == true) {
      final data = response.data['data'] as Map<String, dynamic>;
      final parsed = MessageModel.fromJson(data);
      AppLogger.i(
        '[CHAT ATTACHMENT] MESSAGE SENT — code=${parsed.code}, attachmentIds=$attachmentIds',
      );
      // The create-message response doesn't echo back resolved attachment
      // objects (the document is still processing asynchronously at this
      // point), so trusting `parsed.attachments` here would make the
      // attachment the user just saw uploading disappear from the bubble
      // the instant the optimistic message is replaced. We already have the
      // complete, locally-known attachment (including `localPath` for an
      // immediate preview) from the upload step, so keep using it whenever
      // this message carried one.
      final attachments = message.attachments.isNotEmpty
          ? message.attachments
          : parsed.attachments;
      // The sender is always the current user for outbound messages. Prefer
      // the response's own senderRole, but fall back to `activeRole` — the
      // role this exact request was sent under (see `body['role']` above,
      // and Message.senderRole's doc comment on why this can't just be
      // "whichever role the account holds") — since that's known with
      // certainty regardless of whether the backend echoes it back.
      return MessageModel(
        id: parsed.id,
        code: parsed.code,
        conversationCode: parsed.conversationCode,
        senderUserCode: parsed.senderUserCode,
        text: parsed.text,
        isSentByMe: true,
        time: parsed.time,
        quotedMessageId: parsed.quotedMessageId,
        attachments: attachments,
        reactions: parsed.reactions,
        senderName: parsed.senderName,
        senderRole: (parsed.senderRole?.isNotEmpty ?? false)
            ? parsed.senderRole
            : (activeRole.isNotEmpty ? activeRole : null),
        isPrivate: parsed.isPrivate,
        privateParentUserCode: parsed.privateParentUserCode,
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
      data: EditMessageRequest(content: content).toJson(),
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
    // POST /api/v1/messages/conversation/{conversationCode}/receipts/read-all
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingConversationMarkRead(threadId),
      ApiConstants.communicationBaseUrl,
    );
    try {
      await apiClient.client.post(endpoint);
    } catch (_) {
      // Non-fatal — read receipts failing should not surface to the user.
    }
  }

  @override
  Future<void> markAllAsDelivered(String threadId) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingConversationMarkDelivered(threadId),
      ApiConstants.communicationBaseUrl,
    );
    try {
      await apiClient.client.post(endpoint);
    } catch (_) {
      // Non-fatal — delivery receipts failing should not surface to the user.
    }
  }

  @override
  Future<ConversationModel> createConversation(
    CreateConversationRequest request,
  ) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.conversations,
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.post(
      endpoint,
      data: request.toJson(),
    );

    final apiResponse = CreateConversationResponse.fromJson(response.data);

    if (apiResponse.success && apiResponse.data != null) {
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
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
  }) async {
    final path = type != null
        ? '${ApiPaths.messagingCreateMessage}/type/$type'
        : ApiPaths.messagingCreateMessage;

    final endpoint = ApiPaths.urlWithBase(
      path,
      ApiConstants.communicationBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'status': status,
      'page': page,
      'size': size,
    };

    List<String>? clean(List<String>? values) {
      final result = values?.where((v) => v.trim().isNotEmpty).toList();
      return (result != null && result.isNotEmpty) ? result : null;
    }

    final cleanClassrooms = clean(classroomCodes);
    if (cleanClassrooms != null) {
      queryParameters['classroomCodes'] = cleanClassrooms;
    }
    final cleanTags = clean(tagCodes);
    if (cleanTags != null) {
      queryParameters['tagCodes'] = cleanTags;
    }
    final cleanDesignations = clean(designations);
    if (cleanDesignations != null) {
      queryParameters['designations'] = cleanDesignations;
    }
    final cleanStudentStatuses = clean(studentStatuses);
    if (cleanStudentStatuses != null) {
      queryParameters['studentStatuses'] = cleanStudentStatuses;
    }
    final cleanStaffStatuses = clean(staffStatuses);
    if (cleanStaffStatuses != null) {
      queryParameters['staffStatuses'] = cleanStaffStatuses;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    // Spring expects repeated query keys for collections, e.g.
    // tagCodes=T1&tagCodes=T2 — not bracket or CSV serialization. Mirrors
    // the student/staff list datasources' pattern.
    final response = await apiClient.client.get(
      endpoint,
      queryParameters: queryParameters,
      options: Options(listFormat: ListFormat.multi),
    );

    return GetConversationsResponse.fromJson(response.data);
  }

  @override
  Future<GetConversationsResponse> searchConversations({
    required String query,
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 50,
  }) async {
    final typeParam = type != null ? '&type=$type' : '';
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingConversationsSearch}'
      '?q=${Uri.encodeQueryComponent(query)}$typeParam'
      '&status=$status&page=$page&size=$size',
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

    // No `success`-envelope check here, unlike the other mutation endpoints
    // in this file — this endpoint's response shape has never actually been
    // confirmed against a live sample (unlike delete-message/delete-
    // attachment/remove-reaction, which were). A wrong assumption here
    // previously made every successful add throw, which the repository
    // treats as a failure and rolls back — i.e. the reaction would
    // optimistically appear and then immediately get reverted. Dio's own
    // status-code-based exception (4xx/5xx) is the only failure signal
    // until the real shape is confirmed.
    await apiClient.client.post(endpoint, data: MessageReactionRequest(emoji: emoji).toJson());
  }

  @override
  Future<void> deleteMessage(String messageCode) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/$messageCode',
      ApiConstants.communicationBaseUrl,
    );
    final response = await apiClient.client.delete(endpoint);
    // This endpoint's success body has no `data` payload — just
    // {success, message, timestamp} — so the only thing worth checking is
    // `success` itself.
    if (response.data != null && response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete message');
    }
  }

  @override
  Future<void> removeReaction(String messageCode, String emoji) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.messagingMessages}/$messageCode/reactions/${Uri.encodeComponent(emoji)}',
      ApiConstants.communicationBaseUrl,
    );
    final response = await apiClient.client.delete(endpoint);
    if (response.data != null && response.data['success'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to remove reaction');
    }
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingAttachmentPath(attachmentId),
      ApiConstants.communicationBaseUrl,
    );
    final response = await apiClient.client.delete(endpoint);
    if (response.data != null && response.data['success'] != true) {
      throw Exception(
        response.data['message'] ?? 'Failed to delete attachment',
      );
    }
  }

  @override
  Future<Map<String, int>> getUnreadCountsPerConversation() async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagesUnreadPerConversation,
      ApiConstants.communicationBaseUrl,
    );
    final response = await apiClient.client.get(endpoint);
    if (response.data == null || response.data['success'] != true) {
      throw Exception(
        response.data?['message'] ??
            'Failed to load per-conversation unread counts',
      );
    }

    final data = response.data['data'];
    final result = <String, int>{};
    // Shape hasn't been exercised in production yet (this endpoint was
    // previously unused) — accept either a {conversationCode: count} map or
    // a list of {conversationCode/code, unreadCount} objects.
    if (data is Map) {
      data.forEach((key, value) {
        final count = value is num
            ? value.toInt()
            : int.tryParse('$value') ?? 0;
        result[key as String] = count;
      });
    } else if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final code = (item['conversationCode'] ?? item['code']) as String?;
        if (code == null || code.isEmpty) continue;
        final rawCount = item['unreadCount'];
        result[code] = rawCount is num
            ? rawCount.toInt()
            : int.tryParse('$rawCount') ?? 0;
      }
    }
    return result;
  }

  @override
  Future<({List<RecipientStatus> deliveredTo, List<RecipientStatus> readBy})>
  getMessageReceipts(String messageCode) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.messagingMessageReceipts(messageCode),
      ApiConstants.communicationBaseUrl,
    );
    final response = await apiClient.client.get(endpoint);
    if (response.data == null || response.data['success'] != true) {
      throw Exception(
        response.data?['message'] ?? 'Failed to load message receipts',
      );
    }
    final receipts = response.data['data'];
    return (
      deliveredTo: parseRecipientStatuses(receipts, onlyRead: false),
      readBy: parseRecipientStatuses(receipts, onlyRead: true),
    );
  }
}
