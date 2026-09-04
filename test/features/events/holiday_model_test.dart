import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/holiday_models.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

void main() {
  group('HolidayType.fromValue', () {
    test('maps known codes case-insensitively', () {
      expect(HolidayType.fromValue('FEDERAL'), HolidayType.federal);
      expect(HolidayType.fromValue('federal'), HolidayType.federal);
      expect(HolidayType.fromValue('  School  '), HolidayType.school);
    });

    test('falls back to school for unknown or null input', () {
      expect(HolidayType.fromValue('GALACTIC'), HolidayType.school);
      expect(HolidayType.fromValue(''), HolidayType.school);
      expect(HolidayType.fromValue(null), HolidayType.school);
    });
  });

  group('HolidayStatus.fromValue', () {
    test('maps known codes case-insensitively', () {
      expect(HolidayStatus.fromValue('PENDING'), HolidayStatus.pending);
      expect(HolidayStatus.fromValue('considered'), HolidayStatus.considered);
      expect(HolidayStatus.fromValue(' REJECTED '), HolidayStatus.rejected);
    });

    test('returns null for unknown or null input', () {
      expect(HolidayStatus.fromValue('MAYBE'), isNull);
      expect(HolidayStatus.fromValue(''), isNull);
      expect(HolidayStatus.fromValue(null), isNull);
    });

    test('exposes human labels', () {
      expect(HolidayStatus.pending.label, 'Pending');
      expect(HolidayStatus.considered.label, 'Observed');
      expect(HolidayStatus.rejected.label, 'Not Observed');
    });
  });

  group('Holiday.isObserved', () {
    Holiday holiday({
      required HolidayType type,
      HolidayStatus? status,
    }) => Holiday(
      code: 'H1',
      name: 'x',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 1),
      type: type,
      status: status,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('school holidays are always observed', () {
      expect(holiday(type: HolidayType.school).isObserved, isTrue);
    });

    test('federal holidays are observed only when considered', () {
      expect(
        holiday(type: HolidayType.federal, status: HolidayStatus.considered)
            .isObserved,
        isTrue,
      );
      expect(
        holiday(type: HolidayType.federal, status: HolidayStatus.pending)
            .isObserved,
        isFalse,
      );
      expect(
        holiday(type: HolidayType.federal, status: HolidayStatus.rejected)
            .isObserved,
        isFalse,
      );
    });
  });

  group('Holiday.coversDay', () {
    final holiday = Holiday(
      code: 'H1',
      name: 'Winter Break',
      startDate: DateTime(2026, 12, 20),
      endDate: DateTime(2026, 12, 24),
      type: HolidayType.school,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('includes the first and last day (inclusive bounds)', () {
      expect(holiday.coversDay(DateTime(2026, 12, 20)), isTrue);
      expect(holiday.coversDay(DateTime(2026, 12, 24)), isTrue);
      expect(holiday.coversDay(DateTime(2026, 12, 22)), isTrue);
    });

    test('excludes days outside the range', () {
      expect(holiday.coversDay(DateTime(2026, 12, 19)), isFalse);
      expect(holiday.coversDay(DateTime(2026, 12, 25)), isFalse);
    });

    test('ignores the time component', () {
      expect(holiday.coversDay(DateTime(2026, 12, 24, 23, 59)), isTrue);
      expect(holiday.coversDay(DateTime(2026, 12, 20, 0, 0, 1)), isTrue);
    });
  });

  group('Holiday.copyWith status semantics', () {
    final base = Holiday(
      code: 'H1',
      name: 'x',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 1),
      type: HolidayType.federal,
      status: HolidayStatus.pending,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    test('omitting status leaves it unchanged', () {
      expect(base.copyWith(name: 'y').status, HolidayStatus.pending);
    });

    test('passing a function can set a new value', () {
      expect(
        base.copyWith(status: () => HolidayStatus.considered).status,
        HolidayStatus.considered,
      );
    });

    test('passing a function returning null clears the status', () {
      expect(base.copyWith(status: () => null).status, isNull);
    });
  });

  group('HolidayModel.fromJson', () {
    test('parses a complete payload', () {
      final model = HolidayModel.fromJson(const {
        'code': '  HOL-1  ',
        'name': 'Thanksgiving',
        'startDate': '2026-11-26',
        'endDate': '2026-11-27',
        'description': 'Federal holiday',
        'type': 'FEDERAL',
        'status': 'PENDING',
        'version': 3,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      });

      expect(model.code, 'HOL-1'); // trimmed
      expect(model.name, 'Thanksgiving');
      expect(model.startDate, DateTime.parse('2026-11-26'));
      expect(model.endDate, DateTime.parse('2026-11-27'));
      expect(model.description, 'Federal holiday');
      expect(model.type, 'FEDERAL');
      expect(model.status, 'PENDING');
      expect(model.version, 3);
    });

    test('defaults missing fields without throwing', () {
      final model = HolidayModel.fromJson(const {'name': 'Bare'});
      expect(model.code, '');
      expect(model.description, '');
      expect(model.status, isNull);
      expect(model.version, 0);
      // endDate falls back to startDate when absent.
      expect(model.endDate, model.startDate);
    });

    test('parses version supplied as a string', () {
      expect(HolidayModel.fromJson(const {'version': '7'}).version, 7);
    });

    test('tolerates an unparseable date by falling back', () {
      final model = HolidayModel.fromJson(const {'startDate': 'not-a-date'});
      // No throw; a sensible fallback DateTime is produced.
      expect(model.startDate, isA<DateTime>());
    });
  });

  group('HolidayModel.toEntity', () {
    test('maps enum strings and preserves fields', () {
      final entity = HolidayModel.fromJson(const {
        'code': 'HOL-2',
        'name': 'Spring Break',
        'startDate': '2026-03-16',
        'endDate': '2026-03-20',
        'type': 'SCHOOL',
        'version': 1,
      }).toEntity();

      expect(entity.type, HolidayType.school);
      expect(entity.status, isNull);
      expect(entity.code, 'HOL-2');
      expect(entity.version, 1);
    });

    test('unknown type string degrades to school (no crash)', () {
      final entity = HolidayModel.fromJson(const {
        'code': 'HOL-3',
        'type': 'WHO-KNOWS',
      }).toEntity();
      expect(entity.type, HolidayType.school);
    });
  });

  test('HolidayModel.fromEntity round-trips core fields', () {
    final holiday = Holiday(
      code: 'HOL-4',
      name: 'Labor Day',
      startDate: DateTime(2026, 9, 7),
      endDate: DateTime(2026, 9, 7),
      description: 'desc',
      type: HolidayType.federal,
      status: HolidayStatus.considered,
      version: 5,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final model = HolidayModel.fromEntity(holiday);
    expect(model.type, 'FEDERAL');
    expect(model.status, 'CONSIDERED');
    expect(model.toEntity().type, HolidayType.federal);
    expect(model.toEntity().status, HolidayStatus.considered);
  });

  group('HolidayModel wire helpers', () {
    test('formatDate zero-pads to YYYY-MM-DD', () {
      expect(HolidayModel.formatDate(DateTime(2026, 3, 5)), '2026-03-05');
      expect(HolidayModel.formatDate(DateTime(2026, 12, 25)), '2026-12-25');
    });

    test('createBody sends only the creatable fields as formatted dates', () {
      final body = HolidayModel.createBody(
        name: 'PD Day',
        startDate: DateTime(2026, 2, 3),
        endDate: DateTime(2026, 2, 3),
        description: 'Staff development',
      );
      expect(body, {
        'name': 'PD Day',
        'startDate': '2026-02-03',
        'endDate': '2026-02-03',
        'description': 'Staff development',
      });
      // Server-assigned fields must never be sent on create.
      expect(body.containsKey('code'), isFalse);
      expect(body.containsKey('type'), isFalse);
      expect(body.containsKey('status'), isFalse);
      expect(body.containsKey('version'), isFalse);
    });
  });
}
