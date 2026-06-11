import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/events/models/event_models.dart';
import 'package:wowcare/data/features/events/models/holiday_models.dart';

/// Development stand-in for the future events remote datasource: returns
/// the bundled `mock-data.json` payload in the same shape the API is
/// expected to use, so swapping in a Dio-backed implementation later only
/// changes where the JSON comes from.
abstract class EventSeedDataSource {
  Future<List<EventModel>> fetchEvents();

  Future<List<HolidayModel>> fetchHolidays();
}

class EventSeedDataSourceImpl implements EventSeedDataSource {
  static const String _assetPath = 'assets/data/events/mock-data.json';

  @override
  Future<List<EventModel>> fetchEvents() async {
    final rawEvents = await _loadSection('events');
    return rawEvents
        .whereType<Map>()
        .map((m) =>
            EventModel.fromJson(m.map((k, v) => MapEntry(k.toString(), v))))
        .where((e) => e.code.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<HolidayModel>> fetchHolidays() async {
    final rawHolidays = await _loadSection('holidays');
    return rawHolidays
        .whereType<Map>()
        .map((m) =>
            HolidayModel.fromJson(m.map((k, v) => MapEntry(k.toString(), v))))
        .where((h) => h.code.isNotEmpty && h.name.isNotEmpty)
        .toList();
  }

  Future<List<dynamic>> _loadSection(String key) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      final section = decoded is Map ? decoded[key] : null;
      return section is List ? section : const [];
    } catch (e) {
      AppLogger.e('[Events] Failed to load mock seed data ($key): $e');
      return const [];
    }
  }
}
