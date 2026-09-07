import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/src/app_router.dart';

/// The Activities tab is `AutomaticKeepAliveClientMixin` inside an
/// `IndexedStack` shell branch: once visited, its State is reused forever. The
/// only thing that forces a rebuild for a new notification target is this key,
/// so what it does and does not distinguish IS the deep-link behaviour.
void main() {
  ValueKey<String>? key({
    String highlightCode = 'ACG_1',
    String date = '2026-09-05',
    String classroomCode = 'CLS_1',
    String studentCode = 'STD_A',
  }) => activityFeedDeepLinkKey(
    highlightCode: highlightCode,
    date: date,
    classroomCode: classroomCode,
    studentCode: studentCode,
  );

  test('ordinary browsing keeps a null key so tab state survives', () {
    // A bottom-nav tap on Activities carries no highlightCode. Keying it would
    // throw away scroll position and filters on every visit.
    expect(key(highlightCode: ''), isNull);
    expect(key(highlightCode: '   '), isNull);
  });

  test('a deep link gets a key', () {
    expect(key(), isNotNull);
  });

  test('two siblings on the same card, day and room get DIFFERENT keys', () {
    // The regression this exists for: for a guardian the feed's subject is the
    // selected child, not the room. Without the student in the key, child B's
    // notification reused child A's already-built State and the parent kept
    // looking at child A's day.
    expect(key(studentCode: 'STD_A'), isNot(key(studentCode: 'STD_B')));
  });

  test('the same target produces a stable key (no gratuitous remounts)', () {
    expect(key(), key());
  });

  test('card, day and room each still distinguish a target', () {
    expect(key(highlightCode: 'ACG_1'), isNot(key(highlightCode: 'ACG_2')));
    expect(key(date: '2026-09-05'), isNot(key(date: '2026-09-06')));
    expect(key(classroomCode: 'CLS_1'), isNot(key(classroomCode: 'CLS_2')));
  });

  test('a payload with no student still keys on card, day and room', () {
    // Classroom-wide activities carry no studentCode; they must not all
    // collapse onto one key.
    expect(
      key(studentCode: '', highlightCode: 'ACG_1'),
      isNot(key(studentCode: '', highlightCode: 'ACG_2')),
    );
    expect(key(studentCode: ''), isNotNull);
  });
}
