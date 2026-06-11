import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

part 'holiday_collection.g.dart';

@collection
class HolidayCollection {
  Id get isarId => fastHash(code);

  @Index(unique: true, replace: true)
  late String code;
  late String name;
  @Index()
  late DateTime startDate;
  late DateTime endDate;
  late String description;
  late String type;
  String? status;
  late DateTime createdAt;
  late DateTime updatedAt;

  HolidayCollection();

  factory HolidayCollection.fromEntity(Holiday holiday) {
    return HolidayCollection()
      ..code = holiday.code
      ..name = holiday.name
      ..startDate = holiday.startDate
      ..endDate = holiday.endDate
      ..description = holiday.description
      ..type = holiday.type.value
      ..status = holiday.status?.value
      ..createdAt = holiday.createdAt
      ..updatedAt = holiday.updatedAt;
  }

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
}
