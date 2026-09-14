import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/attendance/models/student_attendance_absent_view_response_model.dart';

void main() {
  group('StudentAttendanceAbsentViewResponseModel.fromJson fidelity', () {
    test('parses a full record + last + number like the old inline reads', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [
            {
              'studentCode': 'STU_1',
              'studentName': 'Alice',
              'classroomCode': 'CLS_1',
              'classroomName': 'Sunflower',
              'absenceDate': '2026-08-20',
              'absentDays': 3,
              'markedAbsentTime': '08:00:00',
              'markedAbsentByName': 'Ms. Bee',
              'absenceNote': 'sick leave',
            },
          ],
          'last': false,
          'number': 0,
        },
      };

      final response = StudentAttendanceAbsentViewResponseModel.fromJson(raw);

      expect(response.last, false);
      expect(response.number, 0);
      expect(response.content.length, 1);

      final record = response.content.single;
      expect(record.studentCode, 'STU_1');
      expect(record.studentName, 'Alice');
      expect(record.classroomCode, 'CLS_1');
      expect(record.classroomName, 'Sunflower');
      expect(record.absenceDate, '2026-08-20');
      expect(record.absentDays, 3);
      expect(record.markedAbsentTime, '08:00:00');
      expect(record.markedAbsentByName, 'Ms. Bee');
      expect(record.absenceNote, 'sick leave');
    });

    test('preserves an object-shaped markedAbsentTime as raw', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [
            {
              'markedAbsentTime': {'hour': 8, 'minute': 30, 'second': 15},
            },
          ],
          'last': true,
          'number': 2,
        },
      };

      final response = StudentAttendanceAbsentViewResponseModel.fromJson(raw);
      final record = response.content.single;
      // No cast applied — the raw object survives for the screen's parseTime.
      expect(record.markedAbsentTime, <String, dynamic>{
        'hour': 8,
        'minute': 30,
        'second': 15,
      });
      expect(response.last, true);
      expect(response.number, 2);
    });

    test('missing record keys fall back to the inline defaults', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [<String, dynamic>{}],
        },
      };

      final response = StudentAttendanceAbsentViewResponseModel.fromJson(raw);
      final record = response.content.single;

      expect(record.absenceDate, '');
      expect(record.studentCode, '');
      expect(record.studentName, '');
      expect(record.absentDays, 0);
      expect(record.markedAbsentByName, '');
      expect(record.classroomName, isNull);
      expect(record.classroomCode, isNull);
      expect(record.absenceNote, isNull);
      expect(record.markedAbsentTime, isNull);
      // last/number absent -> null (screen applies its own ?? true / ?? page).
      expect(response.last, isNull);
      expect(response.number, isNull);
    });

    test('missing `data` key yields empty content + null page fields', () {
      final response = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{},
      );
      expect(response.content, isEmpty);
      expect(response.last, isNull);
      expect(response.number, isNull);
    });

    test('an empty `data` object yields empty content', () {
      final response = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{'data': <String, dynamic>{}},
      );
      expect(response.content, isEmpty);
      expect(response.last, isNull);
      expect(response.number, isNull);
    });

    test('toJson round-trips faithfully for the cache path', () {
      final raw = <String, dynamic>{
        'data': {
          'content': [
            {
              'studentCode': 'STU_9',
              'studentName': 'Bob',
              'classroomCode': 'CLS_2',
              'classroomName': 'Rose',
              'absenceDate': '2026-08-25',
              'absentDays': 5,
              'markedAbsentTime': {'hour': 9, 'minute': 5, 'second': 3},
              'markedAbsentByName': 'Mr. Cee',
              'absenceNote': null,
            },
          ],
          'last': false,
          'number': 1,
        },
      };

      final original = StudentAttendanceAbsentViewResponseModel.fromJson(raw);
      final reparsed = StudentAttendanceAbsentViewResponseModel.fromJson(
        original.toJson(),
      );

      expect(reparsed, equals(original));
      expect(reparsed.content, equals(original.content));

      final r = reparsed.content.single;
      expect(r.studentCode, 'STU_9');
      expect(r.studentName, 'Bob');
      expect(r.classroomCode, 'CLS_2');
      expect(r.classroomName, 'Rose');
      expect(r.absenceDate, '2026-08-25');
      expect(r.absentDays, 5);
      // object-shaped time preserved across the toJson/fromJson round-trip.
      expect(r.markedAbsentTime, <String, dynamic>{
        'hour': 9,
        'minute': 5,
        'second': 3,
      });
      expect(r.markedAbsentByName, 'Mr. Cee');
      expect(r.absenceNote, isNull);
      expect(reparsed.last, false);
      expect(reparsed.number, 1);
    });

    test('value equality via Equatable props', () {
      final a = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{
          'data': {'content': const <dynamic>[], 'last': true, 'number': 0},
        },
      );
      final b = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{
          'data': {'content': const <dynamic>[], 'last': true, 'number': 0},
        },
      );
      expect(a, equals(b));
    });

    test('toEntity maps every field onto the domain entity', () {
      final model = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{
          'data': {
            'content': [
              {
                'studentCode': 'STU_1',
                'studentName': 'Alice',
                'classroomCode': 'CLS_1',
                'classroomName': 'Sunflower',
                'absenceDate': '2026-08-20',
                'absentDays': 3,
                'markedAbsentTime': '08:00:00',
                'markedAbsentByName': 'Ms. Bee',
                'absenceNote': 'sick leave',
              },
            ],
            'last': false,
            'number': 0,
          },
        },
      );

      final entity = model.toEntity();

      expect(entity.last, model.last);
      expect(entity.number, model.number);
      expect(entity.content.length, model.content.length);

      final entityRecord = entity.content.single;
      final modelRecord = model.content.single;
      expect(entityRecord.studentCode, modelRecord.studentCode);
      expect(entityRecord.studentName, modelRecord.studentName);
      expect(entityRecord.classroomCode, modelRecord.classroomCode);
      expect(entityRecord.classroomName, modelRecord.classroomName);
      expect(entityRecord.absenceDate, modelRecord.absenceDate);
      expect(entityRecord.absentDays, modelRecord.absentDays);
      expect(entityRecord.markedAbsentTime, modelRecord.markedAbsentTime);
      expect(entityRecord.markedAbsentByName, modelRecord.markedAbsentByName);
      expect(entityRecord.absenceNote, modelRecord.absenceNote);
    });

    test('fromEntity round-trips back to an equal model', () {
      final model = StudentAttendanceAbsentViewResponseModel.fromJson(
        <String, dynamic>{
          'data': {
            'content': [
              {
                'studentCode': 'STU_2',
                'studentName': 'Bob',
                'absenceDate': '2026-08-21',
              },
            ],
            'last': true,
            'number': 1,
          },
        },
      );

      final roundTripped = StudentAttendanceAbsentViewResponseModel.fromEntity(
        model.toEntity(),
      );

      expect(roundTripped, equals(model));
    });
  });
}
