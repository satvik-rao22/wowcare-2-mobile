import '../../../../core/utils/app_time.dart';
import '../../../../domain/features/scheduling/entities/staff_shift_hours_entry.dart';
import 'scheduling_json_parsing.dart';

class StaffShiftHoursRangeRequestModel {
  const StaffShiftHoursRangeRequestModel({
    required this.startDate,
    required this.endDate,
    required this.schoolCode,
    required this.organizationCode,
    required this.publishedOnly,
    this.staffCodes = const <String>[],
  });

  final String startDate;
  final String endDate;
  final String schoolCode;
  final String organizationCode;
  final bool publishedOnly;
  final List<String> staffCodes;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'startDate': startDate,
      'endDate': endDate,
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'publishedOnly': publishedOnly,
    };
    if (staffCodes.isNotEmpty) {
      json['staffCode'] = staffCodes;
    }
    return json;
  }
}

class StaffShiftHoursEntryModel {
  const StaffShiftHoursEntryModel({
    required this.staffCode,
    required this.shiftDate,
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
  });

  final String staffCode;
  final String shiftDate;
  final double availableHours;
  final double scheduledHours;
  final double unscheduledHours;

  factory StaffShiftHoursEntryModel.fromJson(Map<String, dynamic> json) {
    return StaffShiftHoursEntryModel(
      staffCode: SchedulingJsonParsing.string(json['staffCode']),
      shiftDate: SchedulingJsonParsing.string(json['shiftDate']),
      availableHours: SchedulingJsonParsing.doubleValue(json['availableHours']),
      scheduledHours: SchedulingJsonParsing.doubleValue(json['scheduledHours']),
      unscheduledHours:
          SchedulingJsonParsing.doubleValue(json['unscheduledHours']),
    );
  }

  StaffShiftHoursEntry toEntity() {
    final parsed = DateTime.tryParse(shiftDate);
    final date = parsed != null
        ? DateTime(parsed.year, parsed.month, parsed.day)
        : AppTime.today();

    return StaffShiftHoursEntry(
      staffCode: staffCode,
      shiftDate: date,
      availableHours: availableHours,
      scheduledHours: scheduledHours,
      unscheduledHours: unscheduledHours,
    );
  }
}
