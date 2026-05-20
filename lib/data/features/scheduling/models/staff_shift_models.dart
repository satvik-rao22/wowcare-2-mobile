import 'package:flutter/material.dart';

import '../../../../domain/features/scheduling/entities/staff_shift.dart';

/// Wire-format `{hour, minute, second, nano}` block.
class TimeOfDayModel {
  const TimeOfDayModel({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  factory TimeOfDayModel.fromTimeOfDay(TimeOfDay value) {
    return TimeOfDayModel(hour: value.hour, minute: value.minute);
  }

  /// Accepts either the structured `{hour, minute, ...}` shape or the
  /// `"HH:mm[:ss]"` string shape (some backends switch between them).
  static TimeOfDayModel? tryParse(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      final hour = (raw['hour'] as num?)?.toInt();
      final minute = (raw['minute'] as num?)?.toInt();
      if (hour == null || minute == null) return null;
      return TimeOfDayModel(
        hour: hour,
        minute: minute,
        second: (raw['second'] as num?)?.toInt() ?? 0,
        nano: (raw['nano'] as num?)?.toInt() ?? 0,
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDayModel(
        hour: hour,
        minute: minute,
        second: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
        'second': second,
        'nano': nano,
      };

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);
}

/// Request body for `POST /api/v1/staff-shifts`.
class StaffShiftRequestModel {
  StaffShiftRequestModel(this._request);

  final StaffShiftCreateRequest _request;

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Backend expects `java.time.LocalTime` as `"HH:mm"` strings — sending the
  /// `{hour, minute, second, nano}` object trips a JSON parse error.
  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'staffCode': _request.staffCode,
      'classroomCode': _request.classroomCode,
      'schoolCode': _request.schoolCode,
      'organizationCode': _request.organizationCode,
      'shiftDate': _formatDate(_request.shiftDate),
      'startTime': _formatTime(_request.startTime),
      'endTime': _formatTime(_request.endTime),
      'publish': _request.publish,
      'repeat': _request.repeat,
      'overrideConflicts': _request.overrideConflicts,
      'forceAdd': _request.forceAdd,
    };
    if (_request.breakStartTime != null) {
      json['breakStartTime'] = _formatTime(_request.breakStartTime!);
    }
    if (_request.breakEndTime != null) {
      json['breakEndTime'] = _formatTime(_request.breakEndTime!);
    }
    if (_request.repeat) {
      json['repeatDays'] = _request.repeatDays;
      if (_request.repeatUntilDate != null) {
        json['repeatUntilDate'] = _formatDate(_request.repeatUntilDate!);
      }
    }
    final notes = _request.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      json['notes'] = notes;
    }
    return json;
  }
}

/// Wire model for a shift row returned by either GET or POST endpoints.
class StaffShiftModel {
  const StaffShiftModel({
    required this.shiftCode,
    required this.staffCode,
    required this.classroomCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.classroomName = '',
    this.staffName = '',
    this.notes,
    this.isPublished = false,
    this.seriesCode,
    this.isRecurring = false,
  });

  final String shiftCode;
  final String staffCode;
  final String classroomCode;
  final String classroomName;
  final String staffName;
  final String shiftDate;
  final TimeOfDayModel startTime;
  final TimeOfDayModel endTime;
  final TimeOfDayModel? breakStartTime;
  final TimeOfDayModel? breakEndTime;
  final String? notes;
  final bool isPublished;
  final String? seriesCode;
  final bool isRecurring;

  factory StaffShiftModel.fromJson(Map<String, dynamic> json) {
    final start = TimeOfDayModel.tryParse(json['startTime']);
    final end = TimeOfDayModel.tryParse(json['endTime']);
    if (start == null || end == null) {
      throw const FormatException('Shift is missing startTime or endTime');
    }
    final publishedRaw = json['publish'] ?? json['isPublished'] ?? json['published'];
    final repeatRaw = json['repeat'] ?? json['isRecurring'] ?? json['recurring'];
    final seriesCode = (json['seriesCode'] ??
            json['shiftSeriesCode'] ??
            json['recurringSeriesCode'])
        ?.toString();
    return StaffShiftModel(
      shiftCode: (json['shiftCode'] ?? json['code'] ?? '').toString(),
      staffCode: (json['staffCode'] ?? '').toString(),
      classroomCode: (json['classroomCode'] ?? '').toString(),
      classroomName: (json['classroomName'] ?? '').toString(),
      staffName: (json['staffName'] ?? '').toString(),
      shiftDate: (json['shiftDate'] ?? json['date'] ?? '').toString(),
      startTime: start,
      endTime: end,
      breakStartTime: TimeOfDayModel.tryParse(json['breakStartTime']),
      breakEndTime: TimeOfDayModel.tryParse(json['breakEndTime']),
      notes: json['notes']?.toString(),
      isPublished: publishedRaw is bool ? publishedRaw : false,
      seriesCode: (seriesCode ?? '').isEmpty ? null : seriesCode,
      isRecurring: repeatRaw is bool
          ? repeatRaw
          : (seriesCode != null && seriesCode.isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() => {
        'shiftCode': shiftCode,
        'staffCode': staffCode,
        'classroomCode': classroomCode,
        'classroomName': classroomName,
        'staffName': staffName,
        'shiftDate': shiftDate,
        'startTime': startTime.toJson(),
        'endTime': endTime.toJson(),
        if (breakStartTime != null) 'breakStartTime': breakStartTime!.toJson(),
        if (breakEndTime != null) 'breakEndTime': breakEndTime!.toJson(),
        if (notes != null) 'notes': notes,
        'publish': isPublished,
        if (seriesCode != null) 'seriesCode': seriesCode,
        'repeat': isRecurring,
      };

  StaffShift toEntity() {
    return StaffShift(
      shiftCode: shiftCode,
      staffCode: staffCode,
      classroomCode: classroomCode,
      classroomName: classroomName,
      staffName: staffName,
      shiftDate: DateTime.tryParse(shiftDate) ?? DateTime.now(),
      startTime: startTime.toTimeOfDay(),
      endTime: endTime.toTimeOfDay(),
      breakStartTime: breakStartTime?.toTimeOfDay(),
      breakEndTime: breakEndTime?.toTimeOfDay(),
      notes: notes,
      isPublished: isPublished,
      seriesCode: seriesCode,
      isRecurring: isRecurring,
    );
  }
}

/// Envelope returned by `POST /api/v1/staff-shifts`.
class StaffShiftCreateResultModel {
  const StaffShiftCreateResultModel({
    this.createdCount = 0,
    this.skippedCount = 0,
    this.overriddenCount = 0,
    this.seriesCode,
    this.createdShiftCodes = const <String>[],
    this.skippedDates = const <String>[],
    this.overriddenDates = const <String>[],
    this.warnings = const <String>[],
  });

  final int createdCount;
  final int skippedCount;
  final int overriddenCount;
  final String? seriesCode;
  final List<String> createdShiftCodes;
  final List<String> skippedDates;
  final List<String> overriddenDates;
  final List<String> warnings;

  factory StaffShiftCreateResultModel.fromJson(Map<String, dynamic> json) {
    List<String> asStringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return StaffShiftCreateResultModel(
      createdCount: (json['createdCount'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      overriddenCount: (json['overriddenCount'] as num?)?.toInt() ?? 0,
      seriesCode: json['seriesCode']?.toString(),
      createdShiftCodes: asStringList(json['createdShiftCodes']),
      skippedDates: asStringList(json['skippedDates']),
      overriddenDates: asStringList(json['overriddenDates']),
      warnings: asStringList(json['warnings']),
    );
  }

  StaffShiftCreateResult toEntity() {
    DateTime? parse(String raw) => DateTime.tryParse(raw);
    return StaffShiftCreateResult(
      createdCount: createdCount,
      skippedCount: skippedCount,
      overriddenCount: overriddenCount,
      seriesCode: seriesCode,
      createdShiftCodes: createdShiftCodes,
      skippedDates: skippedDates
          .map(parse)
          .whereType<DateTime>()
          .toList(growable: false),
      overriddenDates: overriddenDates
          .map(parse)
          .whereType<DateTime>()
          .toList(growable: false),
      warnings: warnings,
    );
  }
}
