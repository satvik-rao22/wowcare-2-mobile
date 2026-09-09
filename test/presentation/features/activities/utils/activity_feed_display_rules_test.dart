import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_feed_display_rules.dart';

/// The two rules that decide what a parent sees in the moments after tapping an
/// activity notification: whether the screen may claim there are no activities,
/// and which child it loads.
void main() {
  group('shouldShowActivityFeedLoadingPlaceholder', () {
    bool show({
      bool isLoading = false,
      bool isLoadingParentContext = false,
      bool hasCurrentResult = false,
      bool hasBootstrapError = false,
    }) => shouldShowActivityFeedLoadingPlaceholder(
      isLoading: isLoading,
      isLoadingParentContext: isLoadingParentContext,
      hasCurrentResult: hasCurrentResult,
      hasBootstrapError: hasBootstrapError,
    );

    test('holds the loader before the first load', () {
      // On mount the cubit doesn't exist yet, so `isLoading` is innocently
      // false; the guardian bootstrap hasn't started so `isLoadingParentContext`
      // is false too; and the item list is empty — the screen used to conclude
      // "no activities" before it had looked.
      expect(show(), isTrue);
    });

    test('keeps the loader while either load flag is set', () {
      expect(show(isLoading: true, hasCurrentResult: true), isTrue);
      expect(
        show(isLoadingParentContext: true, hasCurrentResult: true),
        isTrue,
      );
    });

    test('releases to the empty state once a load has completed', () {
      // Only here is "No Activities found" the truth: we asked, and there were
      // none.
      expect(show(hasCurrentResult: true), isFalse);
    });

    test('a stale result from a previous scope does not count', () {
      // The keep-alive regression: the Activities tab is reused inside an
      // IndexedStack, so a deep link into an already-open tab arrives with the
      // PREVIOUS visit's completed (and possibly empty) result still on screen.
      // Callers clear `hasCurrentResult` the moment they decide to reload, and
      // until the new load flips `isLoading` this is the only thing holding the
      // placeholder up — without it the stale empty answer renders first, which
      // is the reported "empty, then a loader, then the list".
      expect(show(hasCurrentResult: false), isTrue);
    });

    test('a bootstrap error is terminal, not work in progress', () {
      // No school selected / guardian profile unresolvable: never started a
      // load and never will, so the loader must give way to the error text
      // rather than spinning forever. This is also what makes it safe for the
      // not-ready early returns to leave `hasCurrentResult` false.
      expect(show(hasBootstrapError: true), isFalse);
    });

    test(
      'an in-flight retry after a bootstrap error still shows the loader',
      () {
        expect(show(hasBootstrapError: true, isLoading: true), isTrue);
      },
    );
  });

  group('resolveGuardianFeedStudentCode', () {
    const owned = <String>['STD_A', 'STD_B'];

    String? resolve({
      String? deepLinkStudentCode,
      bool deepLinkAlreadyApplied = false,
      String? selectedChildCode,
      Iterable<String> ownedStudentCodes = owned,
    }) => resolveGuardianFeedStudentCode(
      deepLinkStudentCode: deepLinkStudentCode,
      deepLinkAlreadyApplied: deepLinkAlreadyApplied,
      selectedChildCode: selectedChildCode,
      ownedStudentCodes: ownedStudentCodes,
    );

    test('the deep-link child beats a stale dropdown selection', () {
      // The whole point: a parent of two children taps child B's notification
      // while child A is selected. On a cold launch (splash routes straight to
      // the deep link) and right after a school switch (which resets the
      // cubit), the selection still says A when the feed bootstraps.
      expect(
        resolve(deepLinkStudentCode: 'STD_B', selectedChildCode: 'STD_A'),
        'STD_B',
      );
    });

    test('falls back to the dropdown when the link carries no student', () {
      expect(resolve(selectedChildCode: 'STD_A'), 'STD_A');
      expect(
        resolve(deepLinkStudentCode: '  ', selectedChildCode: 'STD_A'),
        'STD_A',
      );
    });

    test('ignores a student the guardian does not own', () {
      // A stale persisted selection, or a forged/replayed payload. It must not
      // become the code we fan out on — we fall back to a child we do own.
      expect(
        resolve(
          deepLinkStudentCode: 'STD_SOMEONE_ELSE',
          selectedChildCode: 'STD_A',
        ),
        'STD_A',
      );
      expect(resolve(selectedChildCode: 'STD_GONE'), 'STD_A');
    });

    test('always narrows to one child, never fans out across all of them', () {
      // Skipping the narrowing made the guardian fan-out query EVERY child, so
      // the parent saw a merged list that then visibly shrank.
      expect(resolve(), 'STD_A');
      expect(resolve(selectedChildCode: null), 'STD_A');
    });

    test('the deep-link child applies once, then yields to the dropdown', () {
      // Otherwise a later re-bootstrap — the one a child switch triggers when
      // that child's classroom isn't cached — resolves back to the
      // notification's child and fights the dropdown the user just used.
      expect(
        resolve(
          deepLinkStudentCode: 'STD_B',
          deepLinkAlreadyApplied: true,
          selectedChildCode: 'STD_A',
        ),
        'STD_A',
      );
    });

    test('matches case-insensitively but returns the canonical code', () {
      // The returned value keys the per-student fan-out, so it has to be the
      // code as the student page spells it.
      expect(resolve(deepLinkStudentCode: 'std_b'), 'STD_B');
      expect(resolve(selectedChildCode: ' std_b '), 'STD_B');
    });

    test('returns null when the guardian has no children with a classroom', () {
      expect(
        resolve(deepLinkStudentCode: 'STD_B', ownedStudentCodes: const []),
        isNull,
      );
      expect(resolve(ownedStudentCodes: const ['', '   ']), isNull);
    });
  });
}
