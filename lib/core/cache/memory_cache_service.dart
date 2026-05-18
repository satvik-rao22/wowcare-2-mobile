import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/Schedule-Classroom/models/staff_shift_collection.dart';
import 'package:wowcare/data/features/communication/models/conversation_collection.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';

class MemoryCacheService implements CacheService {
  final Map<Type, Map<dynamic, dynamic>> _store =
      <Type, Map<dynamic, dynamic>>{};

  Map<dynamic, dynamic> _bucketFor(Type type) =>
      _store.putIfAbsent(type, () => <dynamic, dynamic>{});

  dynamic _cacheIdForItem(Object item) {
    if (item is MessageCollection) return item.id;
    if (item is ConversationCollection) return item.id;
    if (item is StaffShiftCollection) {
      return item.shiftCode ??
          '${item.staffCode}_${item.shiftDate}_${item.startTime}';
    }
    throw UnsupportedError(
      'MemoryCacheService: unsupported cache type: ${item.runtimeType}',
    );
  }

  @override
  Future<void> put<T>(T item) async {
    final bucket = _bucketFor(T);
    bucket[_cacheIdForItem(item as Object)] = item;
  }

  @override
  Future<void> putAll<T>(List<T> items) async {
    final bucket = _bucketFor(T);
    for (final item in items) {
      bucket[_cacheIdForItem(item as Object)] = item;
    }
  }

  @override
  Future<T?> get<T>(dynamic id) async {
    final bucket = _bucketFor(T);
    return bucket[id] as T?;
  }

  @override
  Future<List<T>> getAll<T>() async {
    final bucket = _bucketFor(T);
    return bucket.values.cast<T>().toList(growable: false);
  }

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async {
    final bucket = _bucketFor(T);
    final values = bucket.values;

    if (T == MessageCollection) {
      if (fieldName == 'threadId') {
        return values
            .whereType<MessageCollection>()
            .where((m) => m.threadId == value)
            .cast<T>()
            .toList(growable: false);
      }
      if (fieldName == 'id') {
        return values
            .whereType<MessageCollection>()
            .where((m) => m.id == value)
            .cast<T>()
            .toList(growable: false);
      }
    }

    return <T>[];
  }

  @override
  Future<void> delete<T>(dynamic id) async {
    final bucket = _bucketFor(T);
    bucket.remove(id);
  }

  @override
  Future<void> clear<T>() async {
    final bucket = _bucketFor(T);
    bucket.clear();
  }
}
