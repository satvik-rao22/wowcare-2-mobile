import 'dart:convert';

import 'package:wowcare/core/storage/secure_storage_backend.dart';

/// Typed, namespaced, cached access to the platform secure store.
///
/// This is the class app code reaches for when it needs to persist anything:
/// `StorageServiceImpl` is a thin adapter over it and the auth stores use it
/// directly. It owns three concerns the raw [SecureStorageBackend] does not.
///
/// **Types.** The backend stores opaque strings. Ints, bools, doubles, JSON
/// maps and string lists are encoded here in one canonical form (`'42'`,
/// `'true'`, `'1.5'`, JSON) and decoded leniently: a value that does not parse
/// as the requested type reads back as `null`, never as an exception. A plain
/// string written by older code (the auth token keys) reads back unchanged.
///
/// **Namespaces.** A namespaced view prefixes every key (`app.email`) so
/// [clear] and [keys] operate on one logical store without touching another.
/// The general-purpose app store lives under [appNamespace]; the auth tokens
/// and "Remember me" credentials stay at the root, which is why a logout
/// (`StorageService.clear`) cannot take the remembered password with it.
/// Every view shares one backend and one cache.
///
/// **Caching.** `SharedPreferences` answered reads from memory; the secure
/// store is a platform round-trip per call, and the request interceptor alone
/// reads half a dozen keys per HTTP request. A write-through cache, primed
/// once from [SecureStorageBackend.readAll], keeps reads in-process. Writes
/// update the cache first so a reader sees them immediately (the
/// `SharedPreferences` contract) and roll back if the backend rejects them.
/// The cache is per isolate: a WorkManager isolate builds its own instance
/// and reads a fresh snapshot.
///
/// Platform failures surface as [SecureStorageException]; the adapter decides
/// whether to swallow them. An empty key is a programming error and throws
/// [ArgumentError] synchronously.
class SecureStorage {
  /// The root (un-namespaced) view over [backend].
  SecureStorage(SecureStorageBackend backend)
    : this._(_SecureStorageCore(backend), '');

  SecureStorage._(this._core, this.namespace)
    : _prefix = namespace.isEmpty ? '' : '$namespace$namespaceSeparator';

  /// Separator between a namespace and the key it scopes.
  static const String namespaceSeparator = '.';

  /// Namespace of the general-purpose app store behind `StorageService`.
  static const String appNamespace = 'app';

  final _SecureStorageCore _core;

  /// Empty for the root view.
  final String namespace;
  final String _prefix;

  bool get isRoot => namespace.isEmpty;

  /// A view scoped to [namespace] that shares this instance's backend and
  /// cache.
  SecureStorage namespaced(String namespace) {
    if (namespace.isEmpty) {
      throw ArgumentError.value(namespace, 'namespace', 'must not be empty');
    }
    if (namespace.contains(namespaceSeparator)) {
      throw ArgumentError.value(
        namespace,
        'namespace',
        'must not contain "$namespaceSeparator"',
      );
    }
    return SecureStorage._(_core, namespace);
  }

  /// The root view over the same backend and cache.
  SecureStorage get root => isRoot ? this : SecureStorage._(_core, '');

  // ── strings ────────────────────────────────────────────────────────────────

  Future<String?> readString(String key) => _core.read(_qualify(key));

  Future<void> writeString(String key, String value) =>
      _core.write(_qualify(key), value);

  // ── ints ───────────────────────────────────────────────────────────────────

  Future<int?> readInt(String key) async {
    final raw = await readString(key);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> writeInt(String key, int value) =>
      writeString(key, value.toString());

  // ── bools ──────────────────────────────────────────────────────────────────

  Future<bool?> readBool(String key) async {
    return switch (await readString(key)) {
      'true' => true,
      'false' => false,
      _ => null,
    };
  }

  Future<void> writeBool(String key, bool value) =>
      writeString(key, value ? 'true' : 'false');

  // ── doubles ────────────────────────────────────────────────────────────────

  Future<double?> readDouble(String key) async {
    final raw = await readString(key);
    return raw == null ? null : double.tryParse(raw);
  }

  Future<void> writeDouble(String key, double value) =>
      writeString(key, value.toString());

  // ── json ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await readString(key);
    if (raw == null) return null;
    final decoded = _tryDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      writeString(key, jsonEncode(value));

  // ── string lists ───────────────────────────────────────────────────────────

  Future<List<String>?> readStringList(String key) async {
    final raw = await readString(key);
    if (raw == null) return null;
    final decoded = _tryDecode(raw);
    if (decoded is! List || decoded.any((e) => e is! String)) return null;
    return List<String>.from(decoded);
  }

  Future<void> writeStringList(String key, List<String> value) =>
      writeString(key, jsonEncode(value));

  // ── keys ───────────────────────────────────────────────────────────────────

  Future<bool> containsKey(String key) async => await readString(key) != null;

  Future<void> delete(String key) => _core.delete(_qualify(key));

  /// Every key in this namespace, with the namespace prefix stripped.
  Future<Set<String>> keys() async {
    final all = await _core.keys();
    if (_prefix.isEmpty) return all;
    return <String>{
      for (final key in all)
        if (key.startsWith(_prefix)) key.substring(_prefix.length),
    };
  }

  /// Deletes every key in this namespace and nothing outside it.
  ///
  /// Not available on the root view, where "this namespace" would be every
  /// namespace at once: that is [wipeAll], and callers must ask for it by name.
  Future<void> clear() {
    if (isRoot) {
      throw UnsupportedError(
        'clear() on the root view would erase every namespace; '
        'call wipeAll() if that is really intended',
      );
    }
    return _core.deleteWhere((key) => key.startsWith(_prefix));
  }

  /// Deletes everything in every namespace. Fresh-install reset only.
  Future<void> wipeAll() => _core.wipeAll();

  String _qualify(String key) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
    return '$_prefix$key';
  }

  static Object? _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}

/// Backend plus write-through cache, shared by every [SecureStorage] view
/// created from the same root.
class _SecureStorageCore {
  _SecureStorageCore(this.backend);

  final SecureStorageBackend backend;

  /// Known state per fully-qualified key. A `String` is the stored value;
  /// `null` means the key is known to be absent (negative cache), so a hot
  /// path reading an optional key does not hit the platform every time.
  final Map<String, String?> _cache = <String, String?>{};

  bool _primed = false;
  Future<void>? _priming;

  /// Bumped by [wipeAll] so a `readAll` that was in flight when the store was
  /// wiped cannot resurrect pre-wipe values into the cache.
  int _generation = 0;

  Future<void> _ensurePrimed() {
    if (_primed) return Future<void>.value();
    return _priming ??= _prime();
  }

  Future<void> _prime() async {
    final generation = _generation;
    try {
      final all = await backend.readAll();
      if (generation != _generation) return;
      // A write or delete that landed while readAll was in flight is newer
      // than the snapshot, so existing entries win.
      all.forEach((key, value) => _cache.putIfAbsent(key, () => value));
      _primed = true;
    } finally {
      _priming = null;
    }
  }

  Future<String?> read(String key) async {
    await _ensurePrimed();
    if (_cache.containsKey(key)) return _cache[key];
    // Not in the snapshot: either genuinely absent, or (iOS) stored under an
    // accessibility class the snapshot query did not cover. Ask once, then
    // remember the answer either way.
    final value = await backend.read(key);
    return _cache.putIfAbsent(key, () => value);
  }

  Future<void> write(String key, String value) async {
    final hadEntry = _cache.containsKey(key);
    final previous = _cache[key];
    _cache[key] = value;
    try {
      await backend.write(key, value);
    } catch (_) {
      _rollback(key, hadEntry, previous, ifStill: value);
      rethrow;
    }
  }

  Future<void> delete(String key) async {
    final hadEntry = _cache.containsKey(key);
    final previous = _cache[key];
    _cache[key] = null;
    try {
      await backend.delete(key);
    } catch (_) {
      _rollback(key, hadEntry, previous, ifStill: null);
      rethrow;
    }
  }

  /// Undoes an optimistic cache update whose backend call failed, unless a
  /// later write has already replaced it (then the later write owns the
  /// entry and will roll itself back if it fails too).
  void _rollback(
    String key,
    bool hadEntry,
    String? previous, {
    required String? ifStill,
  }) {
    if (!_cache.containsKey(key) || !identical(_cache[key], ifStill)) return;
    if (hadEntry) {
      _cache[key] = previous;
    } else {
      _cache.remove(key);
    }
  }

  Future<Set<String>> keys() async {
    await _ensurePrimed();
    return <String>{
      for (final entry in _cache.entries)
        if (entry.value != null) entry.key,
    };
  }

  Future<void> deleteWhere(bool Function(String key) test) async {
    // keys() returns a fresh Set, so deleting while iterating is safe.
    for (final key in (await keys()).where(test)) {
      await delete(key);
    }
  }

  Future<void> wipeAll() async {
    _generation++;
    await backend.deleteAll();
    _cache.clear();
    _primed = false;
  }
}
