import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
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
    List<String> attachmentCodes,
    bool isPrivate,
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
}

class MessageEntityRemoteDataSourceImpl
    implements MessageEntityRemoteDataSource {
  final ApiClient apiClient;

  MessageEntityRemoteDataSourceImpl({required this.apiClient});

  static const String _base = ApiPaths.messagingMessages;
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
    final endpoint = _url(
      '$_base/conversation/$conversationCode?page=0&size=$size&sort=createdAt,desc$cursor',
    );

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
    List<String> attachmentCodes = const [],
    bool isPrivate = false,
    String? threadParentCode,
  }) async {
    final endpoint = _url(_base);
    final body = <String, dynamic>{
      'conversationCode': conversationCode,
      'type': 'TEXT',
      'content': text,
      if (attachmentCodes.isNotEmpty) 'attachmentCodes': attachmentCodes,
      if (isPrivate) 'isPrivate': true,
      if (threadParentCode != null) 'replyToMessageCode': threadParentCode,
    };

    final response = await apiClient.client.post(endpoint, data: body);
    _assertSuccess(response.data, 'Failed to send message');

    return MessageEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<MessageEntityDto> editMessage({
    required String messageCode,
    required String newText,
  }) async {
    final endpoint = _url('$_base/$messageCode');
    final response = await apiClient.client.put(
      endpoint,
      data: {'content': newText},
    );
    _assertSuccess(response.data, 'Failed to edit message');

    return MessageEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteMessage(String messageCode) async {
    final endpoint = _url('$_base/$messageCode');
    await apiClient.client.delete(endpoint);
  }

  @override
  Future<void> addReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final endpoint = _url('$_base/$messageCode/reactions');
    await apiClient.client.post(endpoint, data: {'emoji': emoji});
  }

  @override
  Future<void> removeReaction({
    required String messageCode,
    required String emoji,
  }) async {
    final endpoint = _url('$_base/$messageCode/reactions/$emoji');
    await apiClient.client.delete(endpoint);
  }

  @override
  Future<void> markMessageRead(String messageCode) async {
    final endpoint = _url('$_base/$messageCode/read');
    await apiClient.client.post(endpoint);
  }

  void _assertSuccess(dynamic data, String fallback) {
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? fallback);
    }
  }
}
