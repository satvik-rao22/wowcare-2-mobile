import 'package:flutter/painting.dart';

import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/conversation_collection.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/data/features/communication/models/unread_entity_collection.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Non–StorageService caches (Isar, RAM, image cache) cleared on session end.
///
/// [StorageService.clear] is invoked separately from auth; this runs after that.
class SessionLocalCacheWiper {
  SessionLocalCacheWiper({
    required CacheService cacheService,
    required StaffRepository staffRepository,
  }) : _cacheService = cacheService,
       _staffRepository = staffRepository;

  final CacheService _cacheService;
  final StaffRepository _staffRepository;

  Future<void> wipe() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    // Legacy v1 messaging stack.
    try {
      await _cacheService.clear<MessageCollection>();
    } catch (_) {}
    try {
      await _cacheService.clear<ConversationCollection>();
    } catch (_) {}

    // v2 messaging stack (Admin Chat, ConversationListCubit-backed Room
    // Chat) — has its own separate Isar schema and was never wiped here,
    // so those screens kept showing the previous school/persona's cached
    // conversations/messages/unread counts until Isar happened to be
    // rebuilt for some other reason.
    try {
      await _cacheService.clear<ConversationEntityCollection>();
    } catch (_) {}
    try {
      await _cacheService.clear<MessageEntityCollection>();
    } catch (_) {}
    try {
      await _cacheService.clear<UnreadEntityCollection>();
    } catch (_) {}

    // NOTE: SyncQueueCollection (pending offline-sent message operations) is
    // deliberately NOT cleared here — it's a durability queue for not-yet-
    // synced outbound sends, not a read cache; wiping it on switch would
    // silently drop a user's unsent message instead of just showing stale
    // data.

    try {
      _staffRepository.clearSessionVolatileCaches();
    } catch (_) {}
  }
}
