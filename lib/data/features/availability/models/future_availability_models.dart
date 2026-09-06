import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';

part 'future_availability_models.g.dart';

// explicitToJson: nested classroom/availability lists must be
// deep-serialized to maps — otherwise toJson() emits raw model objects,
// which then fail to parse back via fromCacheJson (the cache round-trip).
@JsonSerializable(explicitToJson: true)
class FutureAvailabilityGridModel {
  const FutureAvailabilityGridModel({
    required this.schoolCode,
    required this.startDate,
    required this.endDate,
    this.classrooms = const <FutureAvailabilityClassroomModel>[],
    this.availability = const <FutureAvailabilityEntryModel>[],
  });

  @JsonKey(fromJson: _toStringOrEmpty)
  final String schoolCode;
  @JsonKey(fromJson: _parseDate, toJson: _formatDateOnly)
  final DateTime startDate;
  @JsonKey(fromJson: _parseDate, toJson: _formatDateOnly)
  final DateTime endDate;
  @JsonKey(fromJson: _readClassroomList)
  final List<FutureAvailabilityClassroomModel> classrooms;
  @JsonKey(fromJson: _readEntryList)
  final List<FutureAvailabilityEntryModel> availability;

  /// The API wraps the grid in a `data` envelope; the cache copy (written by
  /// [toJson]) does not, so both factories delegate to the same generated
  /// field mapping — just with a different (already-unwrapped) input map.
  factory FutureAvailabilityGridModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return _$FutureAvailabilityGridModelFromJson(data);
  }

  factory FutureAvailabilityGridModel.fromCacheJson(Map<String, dynamic> json) =>
      _$FutureAvailabilityGridModelFromJson(json);

  Map<String, dynamic> toJson() => _$FutureAvailabilityGridModelToJson(this);

  FutureAvailabilityGrid toEntity() {
    return FutureAvailabilityGrid(
      schoolCode: schoolCode,
      startDate: startDate,
      endDate: endDate,
      classrooms: classrooms.map((e) => e.toEntity()).toList(),
      availability: availability.map((e) => e.toEntity()).toList(),
    );
  }
}

List<FutureAvailabilityClassroomModel> _readClassroomList(dynamic value) {
  if (value is! List) return const <FutureAvailabilityClassroomModel>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(FutureAvailabilityClassroomModel.fromJson)
      .toList();
}

List<FutureAvailabilityEntryModel> _readEntryList(dynamic value) {
  if (value is! List) return const <FutureAvailabilityEntryModel>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(FutureAvailabilityEntryModel.fromJson)
      .toList();
}

@JsonSerializable()
class FutureAvailabilityClassroomModel {
  const FutureAvailabilityClassroomModel({
    required this.code,
    required this.name,
    required this.capacity,
    this.logoAssetCode = '',
  });

  @JsonKey(fromJson: _toStringOrEmpty)
  final String code;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String name;
  @JsonKey(fromJson: _toInt)
  final int capacity;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String logoAssetCode;

  factory FutureAvailabilityClassroomModel.fromJson(Map<String, dynamic> json) =>
      _$FutureAvailabilityClassroomModelFromJson(json);

  Map<String, dynamic> toJson() => _$FutureAvailabilityClassroomModelToJson(this);

  FutureAvailabilityClassroom toEntity() {
    return FutureAvailabilityClassroom(
      code: code,
      name: name,
      capacity: capacity,
      logoAssetCode: logoAssetCode,
    );
  }
}

@JsonSerializable()
class FutureAvailabilityEntryModel {
  const FutureAvailabilityEntryModel({
    required this.classroomCode,
    required this.date,
    required this.shift,
    required this.availableSpots,
    required this.expectedStudentCount,
    required this.classroomCapacity,
    required this.confirmedMovementCount,
    required this.pendingMovementCount,
    required this.enrollmentCount,
  });

  @JsonKey(fromJson: _toStringOrEmpty)
  final String classroomCode;
  @JsonKey(fromJson: _parseDate, toJson: _formatDateOnly)
  final DateTime date;
  @JsonKey(fromJson: _shiftFromApi, toJson: _shiftToApi)
  final FutureAvailabilityShift shift;
  @JsonKey(fromJson: _toInt)
  final int availableSpots;
  @JsonKey(fromJson: _toInt)
  final int expectedStudentCount;
  @JsonKey(fromJson: _toInt)
  final int classroomCapacity;
  @JsonKey(fromJson: _toInt)
  final int confirmedMovementCount;
  @JsonKey(fromJson: _toInt)
  final int pendingMovementCount;
  @JsonKey(fromJson: _toInt)
  final int enrollmentCount;

  factory FutureAvailabilityEntryModel.fromJson(Map<String, dynamic> json) =>
      _$FutureAvailabilityEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$FutureAvailabilityEntryModelToJson(this);

  FutureAvailabilityEntry toEntity() {
    return FutureAvailabilityEntry(
      classroomCode: classroomCode,
      date: date,
      shift: shift,
      availableSpots: availableSpots,
      expectedStudentCount: expectedStudentCount,
      classroomCapacity: classroomCapacity,
      confirmedMovementCount: confirmedMovementCount,
      pendingMovementCount: pendingMovementCount,
      enrollmentCount: enrollmentCount,
    );
  }
}

String _toStringOrEmpty(dynamic value) => (value ?? '').toString();

DateTime _parseDate(dynamic raw) {
  final dateString = (raw ?? '').toString().trim();
  if (dateString.isEmpty) return AppTime.today();
  return DateTime.tryParse(dateString) ?? AppTime.today();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

FutureAvailabilityShift _shiftFromApi(dynamic shift) {
  switch (shift.toString().trim().toUpperCase()) {
    case 'MORNING':
      return FutureAvailabilityShift.morning;
    case 'AFTERNOON':
      return FutureAvailabilityShift.afternoon;
    case 'ALL':
      return FutureAvailabilityShift.all;
    case 'TWO_SHIFTS':
      return FutureAvailabilityShift.twoShifts;
    case 'FULL_DAY':
    default:
      return FutureAvailabilityShift.fullDay;
  }
}

String _shiftToApi(FutureAvailabilityShift shift) {
  switch (shift) {
    case FutureAvailabilityShift.morning:
      return 'MORNING';
    case FutureAvailabilityShift.afternoon:
      return 'AFTERNOON';
    case FutureAvailabilityShift.all:
      return 'ALL';
    case FutureAvailabilityShift.fullDay:
      return 'FULL_DAY';
    case FutureAvailabilityShift.twoShifts:
      return 'TWO_SHIFTS';
  }
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
