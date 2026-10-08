import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_v2/data/mappers/overview_mapper.dart';
import 'package:wowcare/modules/attendance_v2/domain/entities/attendance_day.dart';

/// Regression guard for the "Something went wrong" blank screen: the overview
/// mapper must never throw on a 200 response whose field *types* differ from
/// the happy-path contract — a throw there is swallowed into a generic message
/// with no API error log, which is undebuggable.
void main() {
  final from = DateTime(2026, 9, 1);
  final to = DateTime(2026, 9, 30);

  dynamic map(Map<String, dynamic> body) => OverviewMapper.fromResponse(
        body,
        fallbackStaffCode: 'STF_1',
        fallbackStaffName: 'Fallback Name',
        rangeStart: from,
        rangeEnd: to,
      );

  test('happy path parses days + summary', () {
    final p = map({
      'success': true,
      'data': {
        'staff': {'staffCode': 'STF_9', 'staffName': 'Devi V', 'todayStatus': 'PRESENT'},
        'period': {'timeZone': 'America/New_York'},
        'summary': {'attendedDays': 1, 'regularMinutes': 480, 'overtimeMinutes': 16},
        'days': [
          {
            'date': '2026-09-11',
            'status': 'SIGNED_OUT',
            'regularMinutes': 480,
            'overtimeMinutes': 16,
            'totalMinutes': 496,
            'hasOvertime': true,
          },
        ],
      },
    });
    expect(p.staffCode, 'STF_9');
    expect(p.days.single.regularMinutes, 480);
    expect(p.aggregation.totalOvertimeMinutes, 16);
  });

  test('numeric staffCode / stringified minutes do not throw', () {
    final p = map({
      'data': {
        'staff': {'staffCode': 12345, 'staffName': 42, 'designation': ['LEAD_TEACHER']},
        'days': [
          {'date': '2026-09-11', 'status': 'SIGNED_OUT', 'regularMinutes': '480'},
        ],
      },
    });
    expect(p.staffCode, '12345');
    expect(p.designation, 'Lead Teacher');
    expect(p.days.single.regularMinutes, 480);
  });

  test('paginated days envelope is unwrapped', () {
    final p = map({
      'data': {
        'staff': {'staffCode': 'STF_9'},
        'days': {
          'content': [
            {'date': '2026-09-11', 'status': 'SIGNED_OUT', 'totalMinutes': 480},
          ],
          'totalElements': 1,
        },
      },
    });
    expect(p.days, hasLength(1));
  });

  test('Jackson array dates and `type` instead of `status` are handled', () {
    final p = map({
      'data': {
        'days': [
          {'date': [2026, 9, 11], 'type': 'ATTENDED', 'totalMinutes': 480},
          {'date': [2026, 9, 12], 'type': 'ABSENT'},
        ],
      },
    });
    expect(p.days, hasLength(2));
    expect(p.days.first.date, DateTime(2026, 9, 12));
    expect(p.days.first.status, DayStatus.absent);
    expect(p.days.last.status, DayStatus.signedOut);
  });

  test('empty / unexpected envelopes degrade instead of throwing', () {
    expect(map({'success': false, 'message': 'no data'}).days, isEmpty);
    expect(map({'data': []}).days, isEmpty);
    expect(map({'data': {'days': 'none'}}).days, isEmpty);
    expect(
      OverviewMapper.fromResponse(null,
          fallbackStaffCode: 'STF_1',
          fallbackStaffName: 'N',
          rangeStart: from,
          rangeEnd: to).staffCode,
      'STF_1',
    );
  });
}
