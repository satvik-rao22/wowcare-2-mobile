import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/src/app_router.dart';

/// Policy tests for the router's guardian student-scope guard — the client-side
/// half of "a parent may only open THEIR child's screens". The backend remains
/// the authorization boundary; this guard stops the app from navigating to, and
/// then issuing requests for, a student the signed-in guardian is not linked to.
void main() {
  const String path = '/dashboard/student-profile-by-code';
  const Set<String> owned = <String>{'STD_A', 'STD_B'};

  String? decide({
    String studentCode = 'STD_A',
    bool isPersonaResolved = true,
    bool isParent = true,
    bool childrenLoaded = true,
    Set<String> ownedStudentCodes = owned,
  }) => guardianStudentScopeDecision(
    path: path,
    studentCode: studentCode,
    isPersonaResolved: isPersonaResolved,
    isParent: isParent,
    childrenLoaded: childrenLoaded,
    ownedStudentCodes: ownedStudentCodes,
  );

  group('allows', () {
    test("a guardian opening their own child's screen", () {
      expect(decide(studentCode: 'STD_A'), isNull);
      expect(decide(studentCode: 'STD_B'), isNull);
    });

    test('a code that differs only in case', () {
      expect(decide(studentCode: 'std_b'), isNull);
      expect(decide(studentCode: '  STD_B  '), isNull);
    });

    test('staff and admin personas, which are scoped by their own rules', () {
      expect(decide(isParent: false, studentCode: 'STD_ANY'), isNull);
    });

    test('a route with no student code', () {
      expect(decide(studentCode: ''), isNull);
      expect(decide(studentCode: '   '), isNull);
    });
  });

  group('fails open rather than breaking a legitimate flow', () {
    test('while the persona is still resolving', () {
      // Bouncing here would break every cold-start deep link, and the persona
      // is resolved by the splash before /dashboard is reachable.
      expect(
        decide(isPersonaResolved: false, studentCode: 'STD_OTHER'),
        isNull,
      );
    });

    test('while the child list has not loaded', () {
      expect(decide(childrenLoaded: false, studentCode: 'STD_OTHER'), isNull);
    });

    test('when the child list loaded empty', () {
      // Indistinguishable from a transient fetch failure, and there is no
      // wrong child to leak to.
      expect(
        decide(ownedStudentCodes: const <String>{}, studentCode: 'STD_OTHER'),
        isNull,
      );
    });
  });

  group('blocks', () {
    test("a guardian opening another family's student", () {
      expect(decide(studentCode: 'STD_OTHER'), '/dashboard');
    });

    test('a hand-edited deep link', () {
      expect(
        guardianStudentScopeDecision(
          path: '/dashboard/student-attendance-profile-by-code',
          studentCode: 'STD_ZZZ',
          isPersonaResolved: true,
          isParent: true,
          childrenLoaded: true,
          ownedStudentCodes: owned,
        ),
        '/dashboard',
      );
    });

    test('idempotently — the redirect target is not itself guarded', () {
      // A second evaluation of the guard's own target must allow it, or the
      // router would loop A -> B -> A.
      expect(
        guardianStudentScopeDecision(
          path: '/dashboard',
          studentCode: '',
          isPersonaResolved: true,
          isParent: true,
          childrenLoaded: true,
          ownedStudentCodes: owned,
        ),
        isNull,
      );
    });
  });
}
