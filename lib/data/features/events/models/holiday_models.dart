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
    required this.createdAt,
    required this.updatedAt,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic raw) =>
        raw == null ? null : DateTime.tryParse(raw.toString());
    final start = parse(json['startDate']) ?? DateTime.now();
    return HolidayModel(
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString(),
      startDate: start,
      endDate: parse(json['endDate']) ?? start,
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: json['status']?.toString(),
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
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'description': description,
        'type': type,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Holiday toEntity() => Holiday(
        code: code,
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
        type: HolidayType.fromValue(type),
        status: HolidayStatus.fromValue(status),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [code, name, startDate, endDate, type, status];
}
