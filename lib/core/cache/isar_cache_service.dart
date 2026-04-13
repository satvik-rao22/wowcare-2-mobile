import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';

class IsarCacheService implements CacheService {
  late Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [MessageCollectionSchema],
      directory: dir.path,
    );
  }

  @override
  Future<void> put<T>(T item) async {
    await _isar.writeTxn(() async {
      await _isar.collection<T>().put(item);
    });
  }

  @override
  Future<void> putAll<T>(List<T> items) async {
    await _isar.writeTxn(() async {
      await _isar.collection<T>().putAll(items);
    });
  }

  @override
  Future<T?> get<T>(dynamic id) async {
    return await _isar.collection<T>().get(id as Id);
  }

  @override
  Future<List<T>> getAll<T>() async {
    return await _isar.collection<T>().where().findAll();
  }

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async {
    // Isar requires specific generated filters for each field.
    // For a centralized system, we map the fields for each collection here.
    if (T == MessageCollection) {
      if (fieldName == 'threadId') {
        return await _isar.messageCollections
            .filter()
            .threadIdEqualTo(value as String)
            .findAll() as List<T>;
      }
      if (fieldName == 'id') {
         return await _isar.messageCollections
            .filter()
            .idEqualTo(value as String)
            .findAll() as List<T>;
      }
    }
    return [];
  }

  @override
  Future<void> delete<T>(dynamic id) async {
    await _isar.writeTxn(() async {
      await _isar.collection<T>().delete(id as Id);
    });
  }

  @override
  Future<void> clear<T>() async {
    await _isar.writeTxn(() async {
      await _isar.collection<T>().clear();
    });
  }
}
