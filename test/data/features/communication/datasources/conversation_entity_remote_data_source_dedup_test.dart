import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/data/features/communication/datasources/conversation_entity_remote_data_source.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_dto.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

/// Exercises the Phase 6 scale-hardening fix for `findStaffDirectConversation`:
/// it must keep paginating past the first 100-conversation page instead of
/// silently giving up, so a staff member with many active STAFF_DIRECT
/// threads doesn't get a duplicate conversation created for someone they
/// already have a chat with, just because that chat wasn't on page 0.
///
/// Overrides `getConversations` (the only thing `findStaffDirectConversation`
/// calls) rather than hitting the network — the query params/behaviour of
/// `getConversations` itself are untouched by this change.
class _PagedFakeDataSource extends ConversationEntityRemoteDataSourceImpl {
  _PagedFakeDataSource(this._pages) : super(apiClient: ApiClient(baseUrl: 'https://test.invalid'));

  /// One entry per page, each a list of conversations "returned" for that page.
  final List<List<ConversationEntityDto>> _pages;
  final List<int> requestedPages = [];

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
    requestedPages.add(page);
    if (page >= _pages.length) return const [];
    return _pages[page];
  }
}

ConversationEntityDto _conversation(String code, {required String participantCode}) {
  final now = DateTime(2026, 1, 1);
  return ConversationEntityDto(
    id: code.hashCode,
    code: code,
    title: 'Direct chat',
    type: 'STAFF_DIRECT',
    organizationCode: 'ORG-1',
    schoolCode: 'SCH-1',
    status: 'ACTIVE',
    description: '',
    avatarUrl: '',
    createdAt: now,
    createdBy: 'USR-0',
    updatedAt: now,
    updatedBy: 'USR-0',
    participantCount: 1,
    unreadCount: 0,
    lastMessagePreview: '',
    participants: [
      ParticipantEntityDto(
        id: 1,
        conversationId: code.hashCode,
        userCode: participantCode,
        userName: 'Someone',
        role: 'STAFF',
        joinedAt: now,
        muted: false,
        notificationsEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

/// Builds a full page of [size] conversations, none matching [target], used
/// to simulate "page is full, keep going" for pagination tests.
List<ConversationEntityDto> _fullPageOfNonMatches(int size) => List.generate(
      size,
      (i) => _conversation('CONV-filler-$i', participantCode: 'USR-other-$i'),
    );

void main() {
  test('finds a match on page 0 without requesting further pages', () async {
    final ds = _PagedFakeDataSource([
      [_conversation('CONV-1', participantCode: 'USR-target')],
    ]);

    final result = await ds.findStaffDirectConversation('USR-target');

    expect(result?.code, 'CONV-1');
    expect(ds.requestedPages, [0]);
  });

  test(
      'keeps paginating past a full first page to find a match beyond page 0 '
      '(regression test for the size:100-only dedup bug)', () async {
    final page0 = _fullPageOfNonMatches(100);
    final page1 = [
      ..._fullPageOfNonMatches(50),
      _conversation('CONV-found', participantCode: 'USR-target'),
    ];
    final ds = _PagedFakeDataSource([page0, page1]);

    final result = await ds.findStaffDirectConversation('USR-target');

    expect(result?.code, 'CONV-found');
    expect(ds.requestedPages, [0, 1]);
  });

  test('returns null once a short (non-full) page is exhausted with no match',
      () async {
    final ds = _PagedFakeDataSource([
      _fullPageOfNonMatches(100),
      _fullPageOfNonMatches(30), // short page -> no more pages after this
    ]);

    final result = await ds.findStaffDirectConversation('USR-target');

    expect(result, isNull);
    expect(ds.requestedPages, [0, 1]);
  });

  test('stops after the safety cap instead of paginating forever', () async {
    // Every page is a full 100-item page with no match, forever.
    final ds = _PagedFakeDataSource(
      List.generate(1000, (_) => _fullPageOfNonMatches(100)),
    );

    final result = await ds.findStaffDirectConversation('USR-target');

    expect(result, isNull);
    expect(ds.requestedPages.length, lessThanOrEqualTo(50));
  });
}
