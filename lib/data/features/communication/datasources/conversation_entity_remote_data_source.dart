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
    String? designation,
    String? staffStatus,
    String? classroom,
  });

  /// Returns the existing STAFF_DIRECT conversation between the current user
  /// and [recipientUserCode], or null if none exists.
  Future<ConversationEntityDto?> findStaffDirectConversation(
    String recipientUserCode,
  );

  /// Returns the existing active ROOM_CHAT conversation for [studentCode],
  /// optionally narrowed to [classroomCode], or null if none exists.
  ///
  /// Use this before [createConversation] to avoid duplicate per-student
  /// (or per-classroom, when known) rooms.
  Future<ConversationEntityDto?> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  });

  /// Returns the existing active ADMIN_CHAT conversation for [studentCode],
  /// or null if none exists.
  ///
  /// Use this before [createConversation] to avoid duplicate admin threads
  /// for the same student.
  Future<ConversationEntityDto?> findAdminChatConversation({
    required String studentCode,
  });

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
    String title,
    String description,
    String avatarUrl,
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

  Future<void> markConversationDelivered(String conversationCode);

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
    String? designation,
    String? staffStatus,
    String? classroom,
  }) async {
    final path = type != null
        ? ApiPaths.messagingConversationsByType(type.toApiString())
        : ApiPaths.messagingConversations;

    // Build query parameters
    var queryParams = 'status=$status&page=$page&size=$size';
    if (designation != null && designation.isNotEmpty) {
      queryParams += '&designation=${Uri.encodeComponent(designation)}';
    }
    if (staffStatus != null && staffStatus.isNotEmpty) {
      queryParams += '&staffStatus=${Uri.encodeComponent(staffStatus)}';
    }
    if (classroom != null && classroom.isNotEmpty) {
      queryParams += '&classroom=${Uri.encodeComponent(classroom)}';
    }

    final endpoint = _url('$path?$queryParams');

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
    // The `participantUserCode` query param on this endpoint isn't reliably
    // filtering server-side — it's been observed to just return whatever
    // the single most-recently-active STAFF_DIRECT conversation is,
    // regardless of who was actually asked for. That silently reopens the
    // wrong (most recent) chat for ANY "start a new chat" tap. Mirrors
    // findRoomChatConversation/findAdminChatConversation below: fetch the
    // list from the same endpoint already proven correct (it drives the
    // inbox) and verify the match against participants client-side instead
    // of trusting an unverified filter param.
    final conversations = await getConversations(
      type: ConversationType.staffDirect,
      status: 'ACTIVE',
      page: 0,
      size: 100,
    );
    for (final c in conversations) {
      if (c.participants.any((p) => p.userCode == recipientUserCode)) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<ConversationEntityDto?> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  }) async {
    // Reuses the already-proven student-scoped list endpoint and filters
    // client-side, rather than guessing at an unverified
    // `type/{type}?studentCode=...&classroomCode=...` query combination on
    // the backend.
    final conversations = await getConversationsForStudent(studentCode);
    for (final c in conversations) {
      final matchesClassroom =
          classroomCode == null ||
          classroomCode.isEmpty ||
          c.classroomCode == classroomCode;
      if (c.type == 'ROOM_CHAT' && matchesClassroom && c.status == 'ACTIVE') {
        return c;
      }
    }
    return null;
  }

  @override
  Future<ConversationEntityDto?> findAdminChatConversation({
    required String studentCode,
  }) async {
    final conversations = await getConversationsForStudent(studentCode);
    for (final c in conversations) {
      if (c.type == 'ADMIN_CHAT' && c.status == 'ACTIVE') {
        return c;
      }
    }
    return null;
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
    String title = '',
    String description = '',
    String avatarUrl = '',
  }) async {
    final endpoint = _url(ApiPaths.conversations);
    final body = <String, dynamic>{
      'type': type,
      'title': title,
      'description': description,
      if (organizationCode.isNotEmpty) 'organizationCode': organizationCode,
      if (schoolCode.isNotEmpty) 'schoolCode': schoolCode,
      if (studentCode.isNotEmpty) 'studentCode': studentCode,
      if (classroomCode != null && classroomCode.isNotEmpty)
        'classroomCode': classroomCode,
      if (participantCodes != null && participantCodes.isNotEmpty)
        'participantUserCodes': participantCodes,
      if (avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
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
  Future<void> markConversationDelivered(String conversationCode) async {
    final endpoint =
        _url(ApiPaths.messagingConversationMarkDelivered(conversationCode));
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
