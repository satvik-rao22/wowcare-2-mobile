import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

/// JSON-serializable holiday DTO, same conventions as [EventModel]:
/// ISO-8601 dates and uppercase enum codes, ready for the future API.
class HolidayModel extends Equatable {
  const HolidayModel({
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description = '',
    required this.type,
    this.status,
    this.version = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic raw) =>
        raw == null ? null : DateTime.tryParse(raw.toString());
    // Accept version as a number or a numeric string without throwing on
    // unexpected shapes — a malformed value must not blow up the whole parse.
    int parseVersion(dynamic raw) {
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final start = parse(json['startDate']) ?? DateTime.now();
    return HolidayModel(
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString(),
      startDate: start,
      endDate: parse(json['endDate']) ?? start,
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: json['status']?.toString(),
      version: parseVersion(json['version']),
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      updatedAt: parse(json['updatedAt']) ?? DateTime.now(),
    );
  }

  factory HolidayModel.fromEntity(Holiday holiday) {
    return HolidayModel(
      code: holiday.code,
      name: holiday.name,
      startDate: holiday.startDate,
      endDate: holiday.endDate,
      description: holiday.description,
      type: holiday.type.value,
      status: holiday.status?.value,
      version: holiday.version,
      createdAt: holiday.createdAt,
      updatedAt: holiday.updatedAt,
    );
  }

  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final String type;
  final String? status;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `YYYY-MM-DD` — the wire format the holidays API expects for dates.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Body for `POST /api/v1/holidays` (create school holiday). The server
  /// assigns `code`, `type`, `status` and `version`.
  static Map<String, dynamic> createBody({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) => <String, dynamic>{
        'name': name,
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
        'description': description,
      };

  Holiday toEntity() => Holiday(
        code: code,
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        type: HolidayType.fromValue(type),
        status: HolidayStatus.fromValue(status),
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props =>
      [code, name, startDate, endDate, type, status, version];
}
