import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/util/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('fires only the last action after the quiet window', () {
      fakeAsync((async) {
        final debouncer = Debouncer(duration: const Duration(milliseconds: 300));
        final fired = <int>[];

        debouncer.run(() => fired.add(1));
        async.elapse(const Duration(milliseconds: 100));
        debouncer.run(() => fired.add(2));
        async.elapse(const Duration(milliseconds: 100));
        debouncer.run(() => fired.add(3));

        // Nothing has fired yet — the window keeps resetting.
        expect(fired, isEmpty);

        async.elapse(const Duration(milliseconds: 300));
        expect(fired, [3]);
      });
    });

    test('fires again for a new burst after the first settles', () {
      fakeAsync((async) {
        final debouncer = Debouncer(duration: const Duration(milliseconds: 200));
        var count = 0;

        debouncer.run(() => count++);
        async.elapse(const Duration(milliseconds: 200));
        expect(count, 1);

        debouncer.run(() => count++);
        async.elapse(const Duration(milliseconds: 200));
        expect(count, 2);
      });
    });

    test('cancel prevents a pending action from firing', () {
      fakeAsync((async) {
        final debouncer = Debouncer(duration: const Duration(milliseconds: 200));
        var fired = false;

        debouncer.run(() => fired = true);
        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 300));

        expect(fired, isFalse);
        expect(debouncer.isActive, isFalse);
      });
    });
  });
}
