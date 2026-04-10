import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';

class IsarCacheService implements CacheService {
  late Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([MessageCollectionSchema], directory: dir.path);
  }

  @override
  Future<void> put<T>(T item) async {
    await _isar.writeTxn(() async {
      if (item is MessageCollection) {
        await _isar.messageCollections.put(item);
      }
    });
  }

  @override
  Future<void> putAll<T>(List<T> items) async {
    await _isar.writeTxn(() async {
      if (items is List<MessageCollection>) {
        await _isar.messageCollections.putAll(items);
      }
    });
  }

  @override
  Future<T?> get<T>(dynamic id) async {
    if (T == MessageCollection) {
      return await _isar.messageCollections.get(id) as T?;
    }
    return null;
  }

  @override
  Future<List<T>> getAll<T>() async {
    if (T == MessageCollection) {
      return await _isar.messageCollections.where().findAll() as List<T>;
    }
    return [];
  }

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async {
    if (T == MessageCollection && fieldName == 'threadId') {
      return await _isar.messageCollections
          .filter()
          .threadIdEqualTo(value as String)
          .findAll() as List<T>;
    }
    return [];
  }

  @override
  Future<void> delete<T>(dynamic id) async {
    await _isar.writeTxn(() async {
      if (T == MessageCollection) {
        await _isar.messageCollections.delete(id);
      }
    });
  }

  @override
  Future<void> clear<T>() async {
    await _isar.writeTxn(() async {
      if (T == MessageCollection) {
        await _isar.messageCollections.clear();
      }
    });
  }
}
