import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_dto.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';

abstract class ConversationEntityRemoteDataSource {
  /// Mirrors the backend's `getConversationsByType` filter contract exactly
  /// (`classroomCodes`, `tagCodes`, `designations`, `studentStatuses`,
  /// `staffStatuses`, `search`, `unreadOnly`) — the same shape already used
  /// by the student (`classroomCodes`/`tagCodes`) and staff list endpoints,
  /// so the messaging conversation list can finally be filtered server-side
  /// instead of client-side against a separately-filtered roster.
  Future<List<ConversationEntityDto>> getConversations({
    ConversationType? type,
    String status,
    int page,
    int size,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
    bool? unreadOnly,
  });

  /// Returns the existing STAFF_DIRECT conversation between the current user
  /// and [recipientUserCode], or null if none exists.
  Future<ConversationEntityDto?> findStaffDirectConversation(
    String recipientUserCode,
  );

  /// Returns the existing ROOM_CHAT conversation for [studentCode],
  /// optionally narrowed to [classroomCode], or null if none exists.
  /// Matched by type only — NOT filtered by conversation status, so a
  /// conversation for a now-inactive student is still returned (and shown
  /// with the composer disabled) rather than treated as "doesn't exist".
  ///
  /// Use this before [createConversation] to avoid duplicate per-student
  /// (or per-classroom, when known) rooms.
  Future<ConversationEntityDto?> findRoomChatConversation({
    required String studentCode,
    String? classroomCode,
  });

  /// Returns the existing ADMIN_CHAT conversation for [studentCode], or null
  /// if none exists. Matched by type only — see [findRoomChatConversation].
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

  /// Get-or-create the classroom's CLASSROOM_CHAT and reconcile its staff roster
  /// (admins + classroom staff). Idempotent. [classroomName] is the chat title on first creation.
  Future<void> reconcileClassroomChat({
    required String classroomCode,
    String? classroomName,
  });

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

  /// Per-conversation unread counts, keyed by conversation code.
  Future<Map<String, int>> getUnreadCountsPerConversation();

  /// Per-conversation unread counts summed by conversation type (e.g.
  /// `{'STAFF_DIRECT': 1, 'ROOM_CHAT': 3, 'ADMIN_CHAT': 11}`), from the
  /// same `/messages/unread-per-conversation` endpoint as
  /// [getUnreadCountsPerConversation] — used to force an immediate,
  /// authoritative top-bar badge refresh right after a conversation is
  /// marked read, instead of waiting for Firestore's own aggregate stream
  /// to eventually catch up.
  Future<Map<String, int>> getUnreadCountsByType();
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
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
    bool? unreadOnly,
  }) async {
    final path = type != null
        ? ApiPaths.messagingConversationsByType(type.toApiString())
        : ApiPaths.messagingConversations;

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
    if (unreadOnly == true) {
      queryParameters['unreadOnly'] = true;
    }

    final endpoint = _url(path);

    // Spring expects repeated query keys for collections, e.g.
    // tagCodes=T1&tagCodes=T2 — not bracket or CSV serialization. Mirrors
    // the student/staff list datasources' pattern (see
    // StudentRemoteDataSourceImpl.getStudentPage).
    final response = await apiClient.client.get(
      endpoint,
      queryParameters: queryParameters,
      options: Options(listFormat: ListFormat.multi),
    );
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

    return content
        .map((e) {
          final m = e as Map<String, dynamic>;
          final userObj = m['user'] as Map<String, dynamic>?;
          return MessagingStaffResult(
            userCode:
                (userObj?['userCode'] ??
                        userObj?['code'] ??
                        m['userCode'] ??
                        '')
                    .toString(),
            staffCode: (m['code'] ?? m['staffCode'] ?? '').toString(),
            name: '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim(),
            designation: (m['designation'] ?? '').toString(),
            status: (m['status'] ?? 'ACTIVE').toString(),
            avatarAssetCode: (m['profilePhotoAssetCode'] as String?),
          );
        })
        .where((s) => s.userCode.isNotEmpty)
        .toList();
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
    //
    // Deliberately does NOT require `c.status == 'ACTIVE'` — a conversation
    // whose student has become inactive still needs to be found and shown
    // (with the composer disabled via studentStatus, see
    // ConversationThreadScreen/ParentMessagingThread's `_studentInactive`),
    // not treated as "doesn't exist" and silently replaced by the
    // start-a-new-chat draft view.
    final conversations = await getConversationsForStudent(studentCode);
    for (final c in conversations) {
      final matchesClassroom =
          classroomCode == null ||
          classroomCode.isEmpty ||
          c.classroomCode == classroomCode;
      if (c.type == 'ROOM_CHAT' && matchesClassroom) {
        return c;
      }
    }
    return null;
  }

  @override
  Future<ConversationEntityDto?> findAdminChatConversation({
    required String studentCode,
  }) async {
    // See findRoomChatConversation above — no `status == 'ACTIVE'` filter,
    // for the same reason.
    final conversations = await getConversationsForStudent(studentCode);
    for (final c in conversations) {
      if (c.type == 'ADMIN_CHAT') {
        return c;
      }
    }
    return null;
  }

  @override
  Future<ConversationEntityDto> getConversation(String conversationCode) async {
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
    final endpoint = _url(
      ApiPaths.messagingConversationsByStudent(studentCode),
    );
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
    final endpoint = _url(
      ApiPaths.messagingConversationsByClassroom(classroomCode),
    );
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(response.data, 'Failed to load conversations for classroom');

    final content = response.data['data']['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ConversationEntityDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> reconcileClassroomChat({
    required String classroomCode,
    String? classroomName,
  }) async {
    final base = _url(ApiPaths.messagingClassroomReconcile(classroomCode));
    final endpoint = (classroomName != null && classroomName.isNotEmpty)
        ? '$base?classroomName=${Uri.encodeQueryComponent(classroomName)}'
        : base;
    final response = await apiClient.client.post(
      endpoint,
      data: <String, dynamic>{},
    );
    _assertSuccess(response.data, 'Failed to provision classroom chat');
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
    // ROOM_CHAT/ADMIN_CHAT are always scoped to a student (and optionally a
    // classroom) — the backend resolves the actual participants (the
    // student's guardians, the classroom's staff, the creator) from
    // studentCode/classroomCode server-side, so sending an explicit
    // participantUserCodes list here is both unnecessary and not what the
    // backend contract expects for these two types; send an empty
    // `participants` instead. STAFF_DIRECT has no such scope to resolve
    // from, so it still needs the explicit recipient list.
    final isScopedChat = type == 'ROOM_CHAT' || type == 'ADMIN_CHAT';
    final body = <String, dynamic>{
      'title': title,
      'type': type,
      if (organizationCode.isNotEmpty) 'organizationCode': organizationCode,
      if (schoolCode.isNotEmpty) 'schoolCode': schoolCode,
      if (studentCode.isNotEmpty) 'studentCode': studentCode,
      if (classroomCode != null && classroomCode.isNotEmpty)
        'classroomCode': classroomCode,
      if (isScopedChat)
        'participants': const <String>[]
      else ...{
        'description': description,
        if (participantCodes != null && participantCodes.isNotEmpty)
          'participantUserCodes': participantCodes,
      },
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
    final endpoint = _url(
      ApiPaths.messagingConversationParticipants(conversationCode),
    );
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
    final endpoint = _url(
      ApiPaths.messagingConversationPrivateMode(conversationCode),
    );
    await apiClient.client.patch(endpoint, data: {'activate': enable});
  }

  @override
  Future<void> markConversationRead(String conversationCode) async {
    final endpoint = _url(
      ApiPaths.messagingConversationMarkRead(conversationCode),
    );
    await apiClient.client.post(endpoint);
  }

  @override
  Future<void> markConversationDelivered(String conversationCode) async {
    final endpoint = _url(
      ApiPaths.messagingConversationMarkDelivered(conversationCode),
    );
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

  @override
  Future<Map<String, int>> getUnreadCountsPerConversation() async {
    final endpoint = _url(ApiPaths.messagesUnreadPerConversation);
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(
      response.data,
      'Failed to load per-conversation unread counts',
    );

    final data = response.data['data'];
    final result = <String, int>{};
    // Shape hasn't been exercised in production yet (this endpoint was
    // previously unused) — accept either a {conversationCode: count} map or
    // a list of {conversationCode/code, unreadCount} objects, whichever the
    // backend actually returns.
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
  Future<Map<String, int>> getUnreadCountsByType() async {
    final endpoint = _url(ApiPaths.messagesUnreadPerConversation);
    final response = await apiClient.client.get(endpoint);
    _assertSuccess(
      response.data,
      'Failed to load per-conversation unread counts',
    );

    final data = response.data['data'];
    final result = <String, int>{};
    // Confirmed shape: a list of {conversationCode, unreadCount,
    // conversationType} objects (see getUnreadCountsPerConversation's own
    // doc — the flat-map shape it also tolerates carries no type, so it
    // can't contribute here).
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final type = item['conversationType'] as String?;
        if (type == null || type.isEmpty) continue;
        final rawCount = item['unreadCount'];
        final count = rawCount is num
            ? rawCount.toInt()
            : int.tryParse('$rawCount') ?? 0;
        result[type] = (result[type] ?? 0) + count;
      }
    }
    return result;
  }

  void _assertSuccess(dynamic data, String fallback) {
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? fallback);
    }
  }
}
