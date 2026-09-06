// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'future_availability_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FutureAvailabilityGridModel _$FutureAvailabilityGridModelFromJson(
        Map<String, dynamic> json) =>
    FutureAvailabilityGridModel(
      schoolCode: _toStringOrEmpty(json['schoolCode']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      classrooms: json['classrooms'] == null
          ? const <FutureAvailabilityClassroomModel>[]
          : _readClassroomList(json['classrooms']),
      availability: json['availability'] == null
          ? const <FutureAvailabilityEntryModel>[]
          : _readEntryList(json['availability']),
    );

Map<String, dynamic> _$FutureAvailabilityGridModelToJson(
        FutureAvailabilityGridModel instance) =>
    <String, dynamic>{
      'schoolCode': instance.schoolCode,
      'startDate': _formatDateOnly(instance.startDate),
      'endDate': _formatDateOnly(instance.endDate),
      'classrooms': instance.classrooms.map((e) => e.toJson()).toList(),
      'availability': instance.availability.map((e) => e.toJson()).toList(),
    };

FutureAvailabilityClassroomModel _$FutureAvailabilityClassroomModelFromJson(
        Map<String, dynamic> json) =>
    FutureAvailabilityClassroomModel(
      code: _toStringOrEmpty(json['code']),
      name: _toStringOrEmpty(json['name']),
      capacity: _toInt(json['capacity']),
      logoAssetCode: json['logoAssetCode'] == null
          ? ''
          : _toStringOrEmpty(json['logoAssetCode']),
    );

Map<String, dynamic> _$FutureAvailabilityClassroomModelToJson(
        FutureAvailabilityClassroomModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'capacity': instance.capacity,
      'logoAssetCode': instance.logoAssetCode,
    };

FutureAvailabilityEntryModel _$FutureAvailabilityEntryModelFromJson(
        Map<String, dynamic> json) =>
    FutureAvailabilityEntryModel(
      classroomCode: _toStringOrEmpty(json['classroomCode']),
      date: _parseDate(json['date']),
      shift: _shiftFromApi(json['shift']),
      availableSpots: _toInt(json['availableSpots']),
      expectedStudentCount: _toInt(json['expectedStudentCount']),
      classroomCapacity: _toInt(json['classroomCapacity']),
      confirmedMovementCount: _toInt(json['confirmedMovementCount']),
      pendingMovementCount: _toInt(json['pendingMovementCount']),
      enrollmentCount: _toInt(json['enrollmentCount']),
    );

Map<String, dynamic> _$FutureAvailabilityEntryModelToJson(
        FutureAvailabilityEntryModel instance) =>
    <String, dynamic>{
      'classroomCode': instance.classroomCode,
      'date': _formatDateOnly(instance.date),
      'shift': _shiftToApi(instance.shift),
      'availableSpots': instance.availableSpots,
      'expectedStudentCount': instance.expectedStudentCount,
      'classroomCapacity': instance.classroomCapacity,
      'confirmedMovementCount': instance.confirmedMovementCount,
      'pendingMovementCount': instance.pendingMovementCount,
      'enrollmentCount': instance.enrollmentCount,
    };
