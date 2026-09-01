import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';
import 'package:wowcare/data/features/communication/models/message_entity_dto.dart';

abstract class MessageEntityRemoteDataSource {
  Future<List<MessageEntityDto>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size,
  });

  Future<MessageEntityDto> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds,
    bool isPrivate,
    String? privateParentUserCode,
    String? threadParentCode,
  });

  Future<MessageEntityDto> editMessage({
    required String messageCode,
    required String newText,
  });

  Future<void> deleteMessage(String messageCode);

  Future<void> addReaction({
    required String messageCode,
    required String emoji,
  });

  Future<void> removeReaction({
    required String messageCode,
    required String emoji,
  });

  Future<void> markMessageRead(String messageCode);

  /// Removes a single attachment (by the messaging-service attachment id)
  /// from its message without deleting the whole message. Same endpoint
  /// legacy's `CommunicationRemoteDataSource.deleteAttachment` calls.
  Future<void> deleteAttachment(int attachmentId);

  /// Full per-recipient-per-persona receipts for one message — see
  /// [ApiPaths.messagingMessageReceipts]'s doc comment for why this is
  /// fetched separately from the message list's own lighter `receipts`
  /// field.
  Future<List<ReadReceiptEntityDto>> getMessageReceipts(String messageCode);
}

class MessageEntityRemoteDataSourceImpl
    implements MessageEntityRemoteDataSource {
  final ApiClient apiClient;

  MessageEntityRemoteDataSourceImpl({required this.apiClient});

  String get _baseUrl => ApiConstants.communicationBaseUrl;
  String _url(String path) => ApiPaths.urlWithBase(path, _baseUrl);

  @override
  Future<List<MessageEntityDto>> getMessages({
    required String conversationCode,
    String? beforeMessageCode,
    int size = 50,
  }) async {
    final cursor = beforeMessageCode != null
        ? '&beforeMessageCode=$beforeMessageCode'
        : '';
    final path =
        '${ApiPaths.messagingMessages}/conversation/$conversationCode'
        '?page=0&size=$size&sort=createdAt,desc$cursor';
    final endpoint = _url(path);

    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load messages');

    final list = response.data['data']['messages'] as List<dynamic>? ?? [];
    return list
        .map((e) => MessageEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageEntityDto> sendMessage({
    required String conversationCode,
    required String text,
    List<int> attachmentIds = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
    String? threadParentCode,
  }) async {
    final endpoint = _url(ApiPaths.messagingMessages);

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

    final body = <String, dynamic>{
      'conversationCode': conversationCode,
      'type': 'TEXT',
      'content': _wrapAsHtml(text),
      // Backend tracks attachments by the messaging-service's own integer id
      // (assigned at registration — see ChatAttachmentUploader.upload), not
      // by the document-service asset code. Matches
      // CommunicationRemoteDataSource.sendMessage's confirmed-working
      // contract for this same endpoint.
      if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
      if (isPrivate) 'isPrivate': true,
      if (privateParentUserCode != null)
        'privateParentUserCode': privateParentUserCode,
      // Backend expects 'replyToMessageCode' on create (distinct from the
      // 'replyToMessageId' key it echoes back on read — see
      // MessageEntityDto.fromJson).
      if (threadParentCode != null) 'replyToMessageCode': threadParentCode,
      if (activeRole.isNotEmpty) 'role': activeRole,
    };

    final response = await apiClient.client.post(endpoint, data: body);
    _assertSuccess(response.data, 'Failed to send message');

    return MessageEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Wraps plain/inline-formatted content in a block-level `<p>` tag, which
  /// the messaging service requires — sending un-wrapped content (even a
  /// single word like "Hi") 500s.
  static String _wrapAsHtml(String content) {
    final trimmed = content.trim();
    if (RegExp(
      r'^<(p|div|ul|ol|blockquote)[\s>]',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return trimmed;
    }
    return '<p>$trimmed</p>';
  }

  @override
  Future<MessageEntityDto> editMessage({
    required String messageCode,
    required String newText,
  }) async {
    final endpoint = _url(ApiPaths.messagingMessage(messageCode));
    final response = await apiClient.client.put(
      endpoint,
      data: {'content': _wrapAsHtml(newText)},
    );
    _assertSuccess(response.data, 'Failed to edit message');

    return MessageEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteMessage(String messageCode) async {
    final endpoint = _url(ApiPaths.messagingMessage(messageCode));
    await apiClient.client.delete(endpoint);
  }

  @override
  Future<void> addReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final endpoint = _url(ApiPaths.messagingMessageReactions(messageCode));
    await apiClient.client.post(endpoint, data: {'emoji': emoji});
  }

  @override
  Future<void> removeReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final endpoint = _url(
      ApiPaths.messagingMessageReaction(messageCode, emoji),
    );
    await apiClient.client.delete(endpoint);
  }

  @override
  Future<void> markMessageRead(String messageCode) async {
    final endpoint = _url(ApiPaths.messagingMessageRead(messageCode));
    await apiClient.client.post(endpoint);
  }

  @override
  Future<void> deleteAttachment(int attachmentId) async {
    final endpoint = _url(ApiPaths.messagingAttachmentPath(attachmentId));
    await apiClient.client.delete(endpoint);
  }

  @override
  Future<List<ReadReceiptEntityDto>> getMessageReceipts(
    String messageCode,
  ) async {
    final endpoint = _url(ApiPaths.messagingMessageReceipts(messageCode));
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load message receipts');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ReadReceiptEntityDto.fromJson(
            json,
            fallbackMessageCode: messageCode,
          ),
        )
        .toList();
  }

  void _assertSuccess(dynamic data, String fallback) {
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? fallback);
    }
  }
}
