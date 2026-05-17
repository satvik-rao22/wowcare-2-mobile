import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/util/api_constants.dart';
import '../entities/schedule_entry.dart';
import '../entities/staff_shift.dart';
import 'staff_scheduling_repository.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
  /// ===============================
  /// FETCH CLASSROOMS
  /// ===============================

  @override
  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/classroom/all')
        .replace(
          queryParameters: {
            'school': schoolCode,
            'status': 'ACTIVE',
            'type': 'CLASSROOM',
          },
        );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List data = decoded['data'];

      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch classrooms');
    }
  }

  /// ===============================
  /// FETCH SCHOOL TIMEZONE
  /// ===============================

  Future<String> fetchSchoolTimeZone(String schoolCode) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/v1/schools/$schoolCode/timezone',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      return decoded['data']['timeZone'] ?? '';
    } else {
      throw Exception('Failed to fetch timezone');
    }
  }

  /// ===============================
  /// OTHER METHODS
  /// ===============================

  @override
  Future<void> addSchedule(Map<String, dynamic> data) async {}

  @override
  Future<void> editSchedule(String id, Map<String, dynamic> data) async {}

  @override
  Future<List<ScheduleEntryEntity>> getClassroomSchedules() async {
    return [];
  }

  @override
  Future<List<StaffShiftEntity>> getStaffShifts({
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
  }) async {
    return [];
  }
}
