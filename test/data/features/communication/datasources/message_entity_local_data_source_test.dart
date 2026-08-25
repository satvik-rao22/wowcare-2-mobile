import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/datasources/message_entity_local_data_source.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

// ── Fake cache (in-memory, mirrors the established hand-rolled-fake
// convention used elsewhere in this test suite — no real Isar instance) ──────

class _FakeCacheService implements CacheService {
  final Map<Type, List<dynamic>> _store = {};

  @override
  Future<void> put<T>(T item) async {
    _store.putIfAbsent(T, () => <T>[]);
    (_store[T] as List<T>).add(item);
  }

  @override
  Future<void> putAll<T>(List<T> items) async {
    _store.putIfAbsent(T, () => <T>[]);
    (_store[T] as List<T>).addAll(items);
  }

  @override
  Future<T?> get<T>(dynamic id) async => throw UnimplementedError();

  @override
  Future<List<T>> getAll<T>() async => List<T>.from(_store[T] ?? <T>[]);

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async =>
      throw UnimplementedError();

  @override
  Future<void> delete<T>(dynamic id) async => throw UnimplementedError();

  @override
  Future<void> clear<T>() async => _store[T]?.clear();
}

// ── Fixtures ───────────────────────────────────────────────────────────────────

const _org = 'ORG-1';
const _school = 'SCH-1';
const _conversation = 'CONV-1';

MessageEntityCollection _message({
  required String code,
  required DateTime sentAt,
  String conversationCode = _conversation,
  String organizationCode = _org,
  String schoolCode = _school,
}) {
  return MessageEntityCollection.fromEntity(
    MessageEntity(
      id: code,
      code: code,
      conversationCode: conversationCode,
      senderCode: 'USR-1',
      senderName: 'Sender',
      senderRole: ParticipantRole.staff,
      text: 'message $code',
      messageType: MessageType.text,
      status: MessageStatus.sent,
      sentAt: sentAt,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    ),
  );
}

void main() {
  late _FakeCacheService cacheService;
  late MessageEntityLocalDataSourceImpl dataSource;

  // 10 messages, oldest = MSG-0 (10 days ago) ... newest = MSG-9 (today).
  final baseTime = DateTime(2026, 1, 1);
  final seeded = List.generate(
    10,
    (i) => _message(
      code: 'MSG-$i',
      sentAt: baseTime.add(Duration(days: i)),
    ),
  );

  setUp(() async {
    cacheService = _FakeCacheService();
    dataSource = MessageEntityLocalDataSourceImpl(cacheService: cacheService);
    await cacheService.putAll<MessageEntityCollection>(seeded);
  });

  group('getMessages — limit', () {
    test('respects limit instead of returning the full cached set', () async {
      final result = await dataSource.getMessages(
        conversationCode: _conversation,
        organizationCode: _org,
        schoolCode: _school,
        limit: 3,
      );

      expect(result.length, 3);
    });

    test(
      'returns at most `limit` even when far fewer than the cache size',
      () async {
        final result = await dataSource.getMessages(
          conversationCode: _conversation,
          organizationCode: _org,
          schoolCode: _school,
          limit: 1,
        );

        expect(result.length, 1);
        expect(result.single.code, 'MSG-9'); // newest
      },
    );

    test('does not throw or truncate when limit exceeds cache size', () async {
      final result = await dataSource.getMessages(
        conversationCode: _conversation,
        organizationCode: _org,
        schoolCode: _school,
        limit: 1000,
      );

      expect(result.length, 10);
    });
  });

  group('getMessages — ordering', () {
    test('returns messages newest-first', () async {
      final result = await dataSource.getMessages(
        conversationCode: _conversation,
        organizationCode: _org,
        schoolCode: _school,
        limit: 10,
      );

      final codes = result.map((m) => m.code).toList();
      expect(codes, [
        'MSG-9',
        'MSG-8',
        'MSG-7',
        'MSG-6',
        'MSG-5',
        'MSG-4',
        'MSG-3',
        'MSG-2',
        'MSG-1',
        'MSG-0',
      ]);
    });
  });

  group('getMessages — tenancy scoping', () {
    test('excludes messages from other conversations/orgs/schools', () async {
      await cacheService.put(
        _message(
          code: 'OTHER-CONV',
          sentAt: baseTime.add(const Duration(days: 20)),
          conversationCode: 'CONV-OTHER',
        ),
      );
      await cacheService.put(
        _message(
          code: 'OTHER-ORG',
          sentAt: baseTime.add(const Duration(days: 20)),
          organizationCode: 'ORG-OTHER',
        ),
      );
      await cacheService.put(
        _message(
          code: 'OTHER-SCHOOL',
          sentAt: baseTime.add(const Duration(days: 20)),
          schoolCode: 'SCH-OTHER',
        ),
      );

      final result = await dataSource.getMessages(
        conversationCode: _conversation,
        organizationCode: _org,
        schoolCode: _school,
        limit: 50,
      );

      expect(result.length, 10);
      expect(result.any((m) => m.code.startsWith('OTHER')), isFalse);
    });
  });

  group('getMessages — cursor-based pagination (beforeMessageCode)', () {
    test('returns only messages strictly older than the cursor', () async {
      // Cursor = MSG-6 (7th newest). Strictly older: MSG-5..MSG-0 (6 items).
      final result = await dataSource.getMessages(
        conversationCode: _conversation,
        organizationCode: _org,
        schoolCode: _school,
        limit: 50,
        beforeMessageCode: 'MSG-6',
      );

      final codes = result.map((m) => m.code).toList();
      expect(codes, ['MSG-5', 'MSG-4', 'MSG-3', 'MSG-2', 'MSG-1', 'MSG-0']);
    });

    test(
      'combines cursor with limit for a single page of older messages',
      () async {
        final result = await dataSource.getMessages(
          conversationCode: _conversation,
          organizationCode: _org,
          schoolCode: _school,
          limit: 2,
          beforeMessageCode: 'MSG-6',
        );

        final codes = result.map((m) => m.code).toList();
        expect(codes, ['MSG-5', 'MSG-4']);
      },
    );

    test(
      'returns an empty list when the cursor message is not cached',
      () async {
        final result = await dataSource.getMessages(
          conversationCode: _conversation,
          organizationCode: _org,
          schoolCode: _school,
          limit: 50,
          beforeMessageCode: 'MSG-NOT-IN-CACHE',
        );

        expect(result, isEmpty);
      },
    );

    test(
      'two consecutive paginated fetches cover every message exactly once '
      '(no duplicates, no gaps) — mirrors loadOlderMessages() usage',
      () async {
        final page1 = await dataSource.getMessages(
          conversationCode: _conversation,
          organizationCode: _org,
          schoolCode: _school,
          limit: 4,
        );
        expect(page1.map((m) => m.code).toList(), [
          'MSG-9',
          'MSG-8',
          'MSG-7',
          'MSG-6',
        ]);

        final page2 = await dataSource.getMessages(
          conversationCode: _conversation,
          organizationCode: _org,
          schoolCode: _school,
          limit: 4,
          beforeMessageCode: page1.last.code, // 'MSG-6'
        );
        expect(page2.map((m) => m.code).toList(), [
          'MSG-5',
          'MSG-4',
          'MSG-3',
          'MSG-2',
        ]);

        final allCodes = [...page1, ...page2].map((m) => m.code).toSet();
        expect(allCodes.length, 8); // no duplicates across the two pages
      },
    );
  });
}
