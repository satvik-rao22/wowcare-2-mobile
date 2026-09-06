import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/reports/model/report_filter_defaults.dart';

void main() {
  group('ReportFilterDefault', () {
    test('selects every option while the filter is untouched', () {
      final filter = ReportFilterDefault();

      expect(filter.isUserEdited, isFalse);
      expect(filter.resolve(options: ['A', 'B'], current: const []), [
        'A',
        'B',
      ]);
    });

    test('re-seeds "All" when the option list loads in later', () {
      final filter = ReportFilterDefault();

      expect(filter.resolve(options: const [], current: const []), isEmpty);
      expect(filter.resolve(options: ['A', 'B', 'C'], current: const []), [
        'A',
        'B',
        'C',
      ]);
    });

    test('keeps an explicit selection instead of re-adding "All"', () {
      final filter = ReportFilterDefault();

      final selection = filter.userSelected(['B']);

      expect(filter.isUserEdited, isTrue);
      expect(selection, ['B']);
      expect(filter.resolve(options: ['A', 'B', 'C'], current: selection), [
        'B',
      ]);
    });

    test('drops user-selected options that no longer exist', () {
      final filter = ReportFilterDefault();
      final selection = filter.userSelected(['A', 'B']);

      expect(filter.resolve(options: ['B', 'C'], current: selection), ['B']);
    });

    test('an explicit empty selection is never re-expanded to all', () {
      final filter = ReportFilterDefault();
      final selection = filter.userSelected(const []);

      expect(filter.resolve(options: ['A', 'B'], current: selection), isEmpty);
    });
  });
}
