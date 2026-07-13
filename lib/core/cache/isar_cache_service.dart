import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/communication/models/conversation_collection.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';
// Communication v2.1 schemas
import 'package:wowcare/data/features/communication/models/conversation_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/unread_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/sync_queue_collection.dart';

class IsarCacheService implements CacheService {
  late Isar _isar;

  /// Bump this whenever any `@collection` class's fields change (added,
  /// removed, retyped). Isar's on-disk format is tied to the exact schema
  /// it was written with — a device still holding rows from an older
  /// schema can make the *native* Rust storage engine panic while reading
  /// a record (`SIGABRT`, e.g. "range end index ... out of range for
  /// slice"), which is unrecoverable from Dart: a native panic aborts the
  /// whole process before any `try`/`catch` ever runs. The only safe fix is
  /// pre-emptive — detect the version mismatch and delete the database
  /// file *before* Isar ever opens/reads it, so corrupted bytes are never
  /// touched at all. Everything in this cache is a disposable projection
  /// of API/Firestore data, so wiping it just means the next load
  /// re-populates from the network.
  static const int _cacheSchemaVersion = 2;
  static const String _schemaVersionPrefsKey = 'isar_cache_schema_version';
  static const String _isarFilePrefix = 'default';

  /// Isar's on-disk binary layout is tied to the schema generated for each
  /// collection. A device that still has rows written under an older schema
  /// (e.g. before a field was added/removed) can make the native reader walk
  /// past the end of a record's buffer — surfacing as a `RangeError` deep
  /// inside `IsarReaderImpl`, not a Dart-catchable "this row is stale"
  /// signal. Since everything in this cache is a disposable projection of
  /// API/Firestore data (never the source of truth — see the call sites),
  /// the only sane recovery is: stop trusting this collection, wipe it, and
  /// let the next load re-populate it from the network. Without this, a
  /// single bad cached row would crash the app on every launch forever.
  Future<T> _readGuarded<T>(
    Type collectionType,
    Future<T> Function() read,
    T fallback,
    Future<void> Function() clearCollection,
  ) async {
    try {
      return await read();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[IsarCacheService] Corrupt/incompatible cache for $collectionType — '
        'clearing and falling back to network. Error: $e',
      );
      AppLogger.e(stackTrace.toString());
      try {
        await clearCollection();
      } catch (clearError) {
        AppLogger.e(
          '[IsarCacheService] Failed to clear corrupted $collectionType: $clearError',
        );
      }
      return fallback;
    }
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    await _wipeIfSchemaVersionMismatch(dir.path);
    _isar = await Isar.open([
      // Existing schemas — do not remove
      MessageCollectionSchema,
      ConversationCollectionSchema,
      // Communication v2.1 schemas
      ConversationEntityCollectionSchema,
      MessageEntityCollectionSchema,
      UnreadEntityCollectionSchema,
      SyncQueueCollectionSchema,
    ], directory: dir.path);
  }

  /// Deletes the on-disk Isar database (and any lock/WAL files alongside
  /// it) when the stored schema version doesn't match [_cacheSchemaVersion]
  /// — i.e. this device last wrote that file under a different schema.
  /// Must run *before* `Isar.open()` — see [_cacheSchemaVersion] doc for why
  /// this can't be handled reactively after the fact.
  Future<void> _wipeIfSchemaVersionMismatch(String directoryPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt(_schemaVersionPrefsKey);
      if (storedVersion == _cacheSchemaVersion) return;

      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        final entries = await dir.list().toList();
        for (final entry in entries) {
          if (entry is! File) continue;
          final name = entry.uri.pathSegments.last;
          if (name.startsWith(_isarFilePrefix) && name.contains('isar')) {
            try {
              await entry.delete();
            } catch (deleteError) {
              AppLogger.e(
                '[IsarCacheService] Failed to delete stale cache file '
                '$name: $deleteError',
              );
            }
          }
        }
      }

      await prefs.setInt(_schemaVersionPrefsKey, _cacheSchemaVersion);
    } catch (e) {
      // Never let cache-migration bookkeeping block app startup — worst
      // case, a genuinely stale file survives and the per-read guard in
      // [_readGuarded] (or, if it's bad enough to panic natively, the
      // version check next launch) recovers it instead.
      AppLogger.e('[IsarCacheService] Schema version check failed: $e');
    }
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
    return _readGuarded<T?>(
      T,
      () => _isar.collection<T>().get(id as Id),
      null,
      () => clear<T>(),
    );
  }

  @override
  Future<List<T>> getAll<T>() async {
    return _readGuarded<List<T>>(
      T,
      () => _isar.collection<T>().where().findAll(),
      const [],
      () => clear<T>(),
    );
  }

  @override
  Future<List<T>> getByField<T>(String fieldName, dynamic value) async {
    return _readGuarded<List<T>>(
      T,
      () => _getByFieldUnguarded<T>(fieldName, value),
      const [],
      () => clear<T>(),
    );
  }

  Future<List<T>> _getByFieldUnguarded<T>(
    String fieldName,
    dynamic value,
  ) async {
    if (T == MessageCollection) {
      if (fieldName == 'threadId') {
        return await _isar.messageCollections
                .filter()
                .threadIdEqualTo(value as String)
                .findAll()
            as List<T>;
      }
      if (fieldName == 'id') {
        return await _isar.messageCollections
                .filter()
                .idEqualTo(value as String)
                .findAll()
            as List<T>;
      }
      if (fieldName == 'code') {
        return await _isar.messageCollections
                .filter()
                .codeEqualTo(value as String)
                .findAll()
            as List<T>;
      }
    }
    if (T == ConversationCollection) {
      // Without this, getByField<ConversationCollection>('code', …) always
      // returned [] — so the Firestore inbox live-sync merge treated EVERY
      // conversation as "unknown", dropped them all (merged=0), and the
      // conversation list never updated live. Only the message thread synced
      // (MessageCollection was implemented above; ConversationCollection was not).
      if (fieldName == 'code') {
        return await _isar.conversationCollections
                .filter()
                .codeEqualTo(value as String)
                .findAll()
            as List<T>;
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
