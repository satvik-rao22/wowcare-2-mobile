import 'package:flutter/painting.dart';

import 'package:wowcare/core/cache/cache_service.dart';
import 'package:wowcare/data/features/communication/models/conversation_collection.dart';
import 'package:wowcare/data/features/communication/models/message_collection.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Non–SharedPreferences caches (Isar, RAM, image cache) cleared on session end.
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

    try {
      await _cacheService.clear<MessageCollection>();
    } catch (_) {}
    try {
      await _cacheService.clear<ConversationCollection>();
    } catch (_) {}

    try {
      _staffRepository.clearSessionVolatileCaches();
    } catch (_) {}
  }
}
