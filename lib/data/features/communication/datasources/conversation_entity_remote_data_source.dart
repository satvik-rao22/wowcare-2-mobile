import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_dto.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

abstract class ConversationEntityRemoteDataSource {
  Future<List<ConversationEntityDto>> getConversations({
    ConversationType? type,
    String status,
    int page,
    int size,
  });

  Future<ConversationEntityDto> getConversation(String conversationCode);

  Future<List<ConversationEntityDto>> getConversationsForStudent(
    String studentCode,
  );

  Future<List<ConversationEntityDto>> getConversationsForClassroom(
    String classroomCode,
  );

  Future<ConversationEntityDto> createConversation({
    required String type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
  });

  Future<List<ParticipantEntityDto>> addParticipants({
    required String conversationCode,
    required List<String> userCodes,
  });

  Future<void> removeParticipants({
    required String conversationCode,
    required List<String> userCodes,
  });

  Future<void> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  });

  Future<void> markConversationRead(String conversationCode);

  Future<Map<String, int>> getUnreadAggregates();
}

class ConversationEntityRemoteDataSourceImpl
    implements ConversationEntityRemoteDataSource {
  final ApiClient apiClient;

  ConversationEntityRemoteDataSourceImpl({required this.apiClient});

  // Base path — same microservice as existing communication datasource
  static const String _base = ApiPaths.messagingCreateMessage;

  String get _baseUrl => ApiConstants.communicationBaseUrl;

  String _url(String path) => ApiPaths.urlWithBase(path, _baseUrl);

  @override
  Future<List<ConversationEntityDto>> getConversations({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    final typePath =
        type != null ? '/type/${type.toApiString()}' : '';
    final endpoint = _url('$_base$typePath?status=$status&page=$page&size=$size');

    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversations');

    final content = response.data['data']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ConversationEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConversationEntityDto> getConversation(
    String conversationCode,
  ) async {
    final endpoint = _url('$_base/$conversationCode');
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversation');

    return ConversationEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ConversationEntityDto>> getConversationsForStudent(
    String studentCode,
  ) async {
    final endpoint = _url('$_base/student/$studentCode');
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversations for student');

    final content = response.data['data']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ConversationEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConversationEntityDto>> getConversationsForClassroom(
    String classroomCode,
  ) async {
    final endpoint = _url('$_base/classroom/$classroomCode');
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversations for classroom');

    final content = response.data['data']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ConversationEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConversationEntityDto> createConversation({
    required String type,
    required String studentCode,
    String? classroomCode,
    List<String>? participantCodes,
  }) async {
    final endpoint = _url(_base);
    final body = <String, dynamic>{
      'type': type,
      'studentCode': studentCode,
      if (classroomCode != null) 'classroomCode': classroomCode,
      if (participantCodes != null) 'participantCodes': participantCodes,
    };

    final response = await apiClient.client.post(endpoint, data: body);
    _assertSuccess(response.data, 'Failed to create conversation');

    return ConversationEntityDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ParticipantEntityDto>> addParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async {
    final endpoint = _url('$_base/$conversationCode/participants');
    final response = await apiClient.client.post(
      endpoint,
      data: {'userCodes': userCodes},
    );
    _assertSuccess(response.data, 'Failed to add participants');

    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ParticipantEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> removeParticipants({
    required String conversationCode,
    required List<String> userCodes,
  }) async {
    final endpoint = _url('$_base/$conversationCode/participants');
    await apiClient.client.delete(
      endpoint,
      data: {'userCodes': userCodes},
    );
  }

  @override
  Future<void> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    final endpoint = _url('$_base/$conversationCode/private-mode');
    await apiClient.client.patch(
      endpoint,
      data: {'activate': enable},
    );
  }

  @override
  Future<void> markConversationRead(String conversationCode) async {
    final endpoint = _url('$_base/$conversationCode/mark-read');
    await apiClient.client.post(endpoint);
  }

  @override
  Future<Map<String, int>> getUnreadAggregates() async {
    final endpoint = _url('/api/v1/messaging/unread/counts');
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load unread counts');

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  void _assertSuccess(dynamic data, String fallback) {
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? fallback);
    }
  }
}
