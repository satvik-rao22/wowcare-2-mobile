import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_important_date.dart';

void main() {
  group('StaffImportantDate.toPayload', () {
    test('completed physical checkup includes completedDate AND status', () {
      const date = StaffImportantDate(
        importantDateType: 'PHYSICAL_CHECKUP',
        dueDate: '2026-02-06',
        completedDate: '2026-02-06',
        status: 'COMPLETED',
      );

      expect(date.toPayload(), {
        'importantDateType': 'PHYSICAL_CHECKUP',
        'dueDate': '2026-02-06',
        'completedDate': '2026-02-06',
        'status': 'COMPLETED',
      });
    });

    test('hire-style entry (completedDate set, no status) omits status', () {
      const date = StaffImportantDate(
        importantDateType: 'HIRE_DATE',
        dueDate: '2026-01-01',
        completedDate: '2026-01-01',
      );

      final payload = date.toPayload();
      expect(payload, {
        'importantDateType': 'HIRE_DATE',
        'dueDate': '2026-01-01',
        'completedDate': '2026-01-01',
      });
      expect(payload.containsKey('status'), isFalse);
    });

    test('scheduled entry (status set, no completedDate) omits completedDate', () {
      const date = StaffImportantDate(
        importantDateType: 'PHYSICAL_CHECKUP',
        dueDate: '2026-05-01',
        status: 'SCHEDULED',
      );

      final payload = date.toPayload();
      expect(payload, {
        'importantDateType': 'PHYSICAL_CHECKUP',
        'dueDate': '2026-05-01',
        'status': 'SCHEDULED',
      });
      expect(payload.containsKey('completedDate'), isFalse);
    });

    test('null completedDate is omitted; empty status is omitted', () {
      const date = StaffImportantDate(
        importantDateType: 'CDA',
        dueDate: '2026-09-09',
        completedDate: null,
        status: '',
      );

      expect(date.toPayload(), {
        'importantDateType': 'CDA',
        'dueDate': '2026-09-09',
      });
    });
  });

  group('StaffImportantDate.fromMap round-trips through toPayload', () {
    test('full entry with completedDate + status', () {
      final sample = <String, dynamic>{
        'importantDateType': 'PHYSICAL_CHECKUP',
        'dueDate': '2026-02-06',
        'completedDate': '2026-02-06',
        'status': 'COMPLETED',
      };

      expect(StaffImportantDate.fromMap(sample).toPayload(), sample);
    });

    test('entry with only type + dueDate', () {
      final sample = <String, dynamic>{
        'importantDateType': 'FIRST_AID_CPR',
        'dueDate': '2026-07-01',
      };

      expect(StaffImportantDate.fromMap(sample).toPayload(), sample);
    });

    test('missing type/dueDate coerce to empty strings', () {
      final parsed = StaffImportantDate.fromMap(const <String, dynamic>{});
      expect(parsed.importantDateType, '');
      expect(parsed.dueDate, '');
      expect(parsed.completedDate, isNull);
      expect(parsed.status, isNull);
      expect(parsed.toPayload(), {'importantDateType': '', 'dueDate': ''});
    });
  });
}
