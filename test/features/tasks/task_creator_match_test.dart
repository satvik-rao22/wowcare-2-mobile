import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_creator_match.dart';

Task _task({
  String createdBy = '',
  String createdByName = '',
  String createdByCode = '',
}) =>
    Task(
      code: 'TSA_1',
      taskCode: 'TSK_1',
      title: 'x',
      createdBy: createdBy,
      createdByName: createdByName,
      createdByCode: createdByCode,
      startDate: DateTime.utc(2026, 7, 30),
      dueDate: DateTime.utc(2026, 7, 30),
      createdAt: DateTime.utc(2026, 7, 30),
      updatedAt: DateTime.utc(2026, 7, 30),
    );

void main() {
  group('displayName identity (today\'s payload)', () {
    const me = TaskCreatorMatcher(
      identityCodes: {'STF_ME', 'USR_ME'},
      displayName: 'Suhas Biwalkar',
    );

    test('is the default, so no call site has to opt in', () {
      expect(TaskCreatorMatcher.defaultIdentity,
          TaskCreatorIdentity.displayName);
      expect(const TaskCreatorMatcher().identity,
          TaskCreatorIdentity.displayName);
    });

    test('matches the creator name the API sends in createdBy', () {
      expect(me.matches(_task(createdBy: 'Suhas Biwalkar')), isTrue);
    });

    test('does not match a different creator', () {
      expect(me.matches(_task(createdBy: 'Mohan Sonone')), isFalse);
    });

    test('ignores case and surrounding//repeated whitespace', () {
      expect(me.matches(_task(createdBy: '  suhas   BIWALKAR ')), isTrue);
    });

    test('prefers the denormalized name when the payload has both', () {
      expect(
        me.matches(_task(createdBy: 'ignored', createdByName: 'Suhas Biwalkar')),
        isTrue,
      );
    });

    test('a name is not compared against identity codes', () {
      // The staff code is in `identityCodes`, but under this identity only names
      // are compared — a code in `createdBy` is somebody else's business.
      expect(me.matches(_task(createdBy: 'STF_ME')), isFalse);
    });

    group('fails closed', () {
      test('when the signed-in display name is unresolved', () {
        const unresolved =
            TaskCreatorMatcher(identityCodes: {'STF_ME'}, displayName: '');
        expect(unresolved.isResolved, isFalse);
        expect(unresolved.matches(_task(createdBy: 'Suhas Biwalkar')), isFalse);
      });

      test('when the display name is only whitespace', () {
        const blank = TaskCreatorMatcher(displayName: '   ');
        expect(blank.isResolved, isFalse);
        expect(blank.matches(_task(createdBy: '   ')), isFalse);
      });

      test('when the task has no creator at all', () {
        // An unknown author must read as "not mine", never as "mine" just
        // because both sides are blank.
        expect(me.matches(_task()), isFalse);
      });
    });
  });

  group('staffCode identity (after the backend sends a code)', () {
    const me = TaskCreatorMatcher(
      identityCodes: {'STF_ME', 'USR_ME'},
      displayName: 'Suhas Biwalkar',
      identity: TaskCreatorIdentity.staffCode,
    );

    test('matches on the dedicated createdByCode field', () {
      expect(me.matches(_task(createdByCode: 'STF_ME')), isTrue);
      expect(me.matches(_task(createdByCode: 'USR_ME')), isTrue);
    });

    test('matches a code the backend puts in createdBy instead', () {
      // Covers the other plausible migration: `createdBy` repurposed from name
      // to code rather than a new field being added.
      expect(me.matches(_task(createdBy: 'STF_ME')), isTrue);
    });

    test('does not match another person\'s code', () {
      expect(me.matches(_task(createdByCode: 'STF_OTHER')), isFalse);
    });

    test('stops trusting names entirely', () {
      // This is the point of the switch: a namesake can no longer match.
      expect(me.matches(_task(createdBy: 'Suhas Biwalkar')), isFalse);
      expect(
        me.matches(_task(createdByName: 'Suhas Biwalkar')),
        isFalse,
      );
    });

    test('fails closed with no identity codes', () {
      const unresolved = TaskCreatorMatcher(
        displayName: 'Suhas Biwalkar',
        identity: TaskCreatorIdentity.staffCode,
      );
      expect(unresolved.isResolved, isFalse);
      expect(unresolved.matches(_task(createdByCode: 'STF_ME')), isFalse);
    });

    test('ignores blank identity codes', () {
      const blanks = TaskCreatorMatcher(
        identityCodes: {'', '  '},
        identity: TaskCreatorIdentity.staffCode,
      );
      expect(blanks.isResolved, isFalse);
      expect(blanks.matches(_task(createdByCode: '')), isFalse);
    });
  });

  group('normalizeName', () {
    test('trims, case-folds and collapses whitespace', () {
      expect(TaskCreatorMatcher.normalizeName('  Suhas   Biwalkar  '),
          'suhas biwalkar');
      expect(TaskCreatorMatcher.normalizeName('SUHAS\tBIWALKAR'),
          'suhas biwalkar');
    });

    test('keeps genuinely different names apart', () {
      // No initial-matching or punctuation stripping: "S. Biwalkar" is not
      // provably the same person as "Suhas Biwalkar".
      expect(
        TaskCreatorMatcher.normalizeName('S. Biwalkar'),
        isNot(TaskCreatorMatcher.normalizeName('Suhas Biwalkar')),
      );
    });
  });

  group('isAmbiguousAmong — the limit of name matching', () {
    const me = TaskCreatorMatcher(displayName: 'Priya Nair');

    test('flags a roster containing a namesake of the signed-in user', () {
      expect(
        me.isAmbiguousAmong(const ['Priya Nair', 'Mohan Sonone', 'priya nair']),
        isTrue,
      );
    });

    test('is quiet when the name is unique in the roster', () {
      expect(
        me.isAmbiguousAmong(const ['Priya Nair', 'Mohan Sonone']),
        isFalse,
      );
    });

    test('is quiet when the signed-in name is unresolved', () {
      expect(
        const TaskCreatorMatcher().isAmbiguousAmong(const ['', '']),
        isFalse,
      );
    });

    test('never flags once identity is a code — it cannot be ambiguous', () {
      expect(
        const TaskCreatorMatcher(
          displayName: 'Priya Nair',
          identityCodes: {'STF_ME'},
          identity: TaskCreatorIdentity.staffCode,
        ).isAmbiguousAmong(const ['Priya Nair', 'Priya Nair']),
        isFalse,
      );
    });
  });
}
