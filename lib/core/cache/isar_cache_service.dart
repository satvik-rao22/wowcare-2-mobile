import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/features/communication/models/conversation_collection.dart';
import '../../data/features/communication/models/message_collection.dart';
import 'cache_service.dart';

class IsarCacheService implements CacheService {
  final Isar _isar;

  IsarCacheService(this._isar);

  static Future<IsarCacheService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [MessageCollectionSchema, ConversationCollectionSchema],
      directory: dir.path,
      name: 'wowcare_cache',
    );
    return IsarCacheService(isar);
  }

  @override
  Future<void> put<T>(T item) async {
    if (item is MessageCollection) {
      await _isar.writeTxn(() => _isar.messageCollections.put(item));
      return;
    }
    if (item is ConversationCollection) {
      await _isar.writeTxn(() => _isar.conversationCollections.put(item));
      return;
    }
    throw UnsupportedError(
      'IsarCacheService: unsupported type: ${item.runtimeType}',
    );
  }

  @override
  Future<void> putAll<T>(List<T> items) async {
    if (items.isEmpty) return;

    final first = items.first;
    if (first is MessageCollection) {
      final list = items.cast<MessageCollection>();
      await _isar.writeTxn(() => _isar.messageCollections.putAll(list));
      return;
    }
    if (first is ConversationCollection) {
      final list = items.cast<ConversationCollection>();
      await _isar.writeTxn(() => _isar.conversationCollections.putAll(list));
      return;
    }
    throw UnsupportedError(
      'IsarCacheService: unsupported type: ${first.runtimeType}',
    );
  }

  @override
  Future<T?> get<T>(dynamic id) async {
    if (T == MessageCollection) {
      if (id is int) return await _isar.messageCollections.get(id) as T?;
      return null;
    }
    if (T == ConversationCollection) {
      if (id is int) return await _isar.conversationCollections.get(id) as T?;
      return null;
    }
    throw UnsupportedError('IsarCacheService: unsupported type: $T');
  }

  @override
  Future<List<T>> getAll<T>() async {
    if (T == MessageCollection) {
      return (await _isar.messageCollections.where().findAll()).cast<T>();
    }
    if (T == ConversationCollection) {
      return (await _isar.conversationCollections.where().findAll()).cast<T>();
    }
    throw UnsupportedError('IsarCacheService: unsupported type: $T');
  }

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async {
    if (T == MessageCollection) {
      if (fieldName == 'threadId' && value is String) {
        return (await _isar.messageCollections
                .where()
                .threadIdEqualTo(value)
                .findAll())
            .cast<T>();
      }
      if (fieldName == 'id' && value is String) {
        return (await _isar.messageCollections
                .filter()
                .idEqualTo(value)
                .findAll())
            .cast<T>();
      }
      return <T>[];
    }
    return <T>[];
  }

  @override
  Future<void> delete<T>(dynamic id) async {
    if (T == MessageCollection) {
      if (id is int) {
        await _isar.writeTxn(() => _isar.messageCollections.delete(id));
      }
      return;
    }
    if (T == ConversationCollection) {
      if (id is int) {
        await _isar.writeTxn(() => _isar.conversationCollections.delete(id));
      }
      return;
    }
    throw UnsupportedError('IsarCacheService: unsupported type: $T');
  }

  @override
  Future<void> clear<T>() async {
    if (T == MessageCollection) {
      await _isar.writeTxn(() => _isar.messageCollections.clear());
      return;
    }
    if (T == ConversationCollection) {
      await _isar.writeTxn(() => _isar.conversationCollections.clear());
      return;
    }
    throw UnsupportedError('IsarCacheService: unsupported type: $T');
  }
}
