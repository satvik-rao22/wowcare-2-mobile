import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_dto.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';

abstract class ConversationEntityRemoteDataSource {
  Future<List<ConversationEntityDto>> getConversations({
    ConversationType? type,
    String status,
    int page,
    int size,
  });

  /// Returns the existing STAFF_DIRECT conversation between the current user
  /// and [recipientUserCode], or null if none exists.
  Future<ConversationEntityDto?> findStaffDirectConversation(
    String recipientUserCode,
  );

  /// Search active and upcoming staff by name fragment.
  ///
  /// Used by the Staff Messaging inbox to let users start a new conversation
  /// with a staff member they have never messaged before.
  Future<List<MessagingStaffResult>> searchStaffForMessaging({
    required String query,
    required String organizationCode,
    required String schoolCode,
    int size = 30,
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
    String organizationCode,
    String schoolCode,
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

  String get _baseUrl => ApiConstants.communicationBaseUrl;

  String _url(String path) => ApiPaths.urlWithBase(path, _baseUrl);

  @override
  Future<List<ConversationEntityDto>> getConversations({
    ConversationType? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    final path = type != null
        ? ApiPaths.messagingConversationsByType(type.toApiString())
        : ApiPaths.messagingConversations;
    final endpoint = _url('$path?status=$status&page=$page&size=$size');

    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversations');

    final content = response.data['data']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ConversationEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MessagingStaffResult>> searchStaffForMessaging({
    required String query,
    required String organizationCode,
    required String schoolCode,
    int size = 30,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );
    final response = await apiClient.client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'search': query.trim(),
        'status': ['ACTIVE', 'UPCOMING'],
        'page': 0,
        'size': size,
        'sort': 'firstName,asc',
      },
    );

    final data = response.data as Map<String, dynamic>?;
    final content =
        (data?['data']?['content'] ?? data?['content']) as List<dynamic>? ?? [];

    return content.map((e) {
      final m = e as Map<String, dynamic>;
      final userObj = m['user'] as Map<String, dynamic>?;
      return MessagingStaffResult(
        userCode: (userObj?['userCode'] ?? userObj?['code'] ?? m['userCode'] ?? '').toString(),
        staffCode: (m['code'] ?? m['staffCode'] ?? '').toString(),
        name: '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim(),
        designation: (m['designation'] ?? '').toString(),
        status: (m['status'] ?? 'ACTIVE').toString(),
        avatarAssetCode: (m['profilePhotoAssetCode'] as String?),
      );
    }).where((s) => s.userCode.isNotEmpty).toList();
  }

  @override
  Future<ConversationEntityDto?> findStaffDirectConversation(
    String recipientUserCode,
  ) async {
    final path = ApiPaths.messagingConversationsByType('STAFF_DIRECT');
    final endpoint = _url(
      '$path?status=ACTIVE&participantUserCode=$recipientUserCode&page=0&size=1',
    );
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to search direct conversation');

    final content =
        response.data['data']['content'] as List<dynamic>? ?? [];
    if (content.isEmpty) return null;
    return ConversationEntityDto.fromJson(
      content.first as Map<String, dynamic>,
    );
  }

  @override
  Future<ConversationEntityDto> getConversation(
    String conversationCode,
  ) async {
    final endpoint = _url(ApiPaths.messagingConversation(conversationCode));
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
    final endpoint = _url(ApiPaths.messagingConversationsByStudent(studentCode));
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
    final endpoint =
        _url(ApiPaths.messagingConversationsByClassroom(classroomCode));
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
    String organizationCode = '',
    String schoolCode = '',
  }) async {
    final endpoint = _url(ApiPaths.conversations);
    final body = <String, dynamic>{
      'type': type,
      if (organizationCode.isNotEmpty) 'organizationCode': organizationCode,
      if (schoolCode.isNotEmpty) 'schoolCode': schoolCode,
      if (studentCode.isNotEmpty) 'studentCode': studentCode,
      if (classroomCode != null && classroomCode.isNotEmpty)
        'classroomCode': classroomCode,
      if (participantCodes != null && participantCodes.isNotEmpty)
        'participantUserCodes': participantCodes,
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
    final endpoint =
        _url(ApiPaths.messagingConversationParticipants(conversationCode));
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
    // New contract: DELETE /api/v1/conversations/{code}/participants/{userCode}
    // One request per user code — loop through all.
    for (final userCode in userCodes) {
      final endpoint = _url(
        ApiPaths.conversationParticipant(conversationCode, userCode),
      );
      await apiClient.client.delete(endpoint);
    }
  }

  @override
  Future<void> togglePrivateMode({
    required String conversationCode,
    required bool enable,
  }) async {
    final endpoint =
        _url(ApiPaths.messagingConversationPrivateMode(conversationCode));
    await apiClient.client.patch(
      endpoint,
      data: {'activate': enable},
    );
  }

  @override
  Future<void> markConversationRead(String conversationCode) async {
    final endpoint =
        _url(ApiPaths.messagingConversationMarkRead(conversationCode));
    await apiClient.client.post(endpoint);
  }

  @override
  Future<Map<String, int>> getUnreadAggregates() async {
    final endpoint = _url(ApiPaths.messagingUnreadCounts);
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
