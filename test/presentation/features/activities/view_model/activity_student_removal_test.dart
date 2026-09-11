import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/bottle_activity_cubit.dart';
import 'package:wowcare/presentation/features/activities/view_model/medication_activity_cubit.dart';

/// Regression tests for the student-removal defect.
///
/// Every activity form keeps the selection in TWO lists that must stay
/// index-aligned:
///
///   * `selectedStudents`      — display names, drives the on-screen tiles
///   * `selectedStudentsData`  — records, drives the SUBMITTED `studentCodes`
///
/// `MedicationActivityCubit.removeStudent` used to drop the name only. The
/// consequences were both invisible and serious:
///
///   1. the submitted payload still carried the removed student's code, so the
///      activity was created for a child the teacher had explicitly removed —
///      on a medication form, a medical record against the wrong child; and
///   2. the tiles pair `selectedStudents[i]` with `selectedStudentsData[i]`, so
///      after a removal every remaining tile rendered the WRONG student code.
///
/// These tests assert both lists stay in step. `BottleActivityCubit` — which
/// already did this correctly — is covered too, so the pair cannot drift again.
/// `init` kicks off unawaited school-timezone and staff-context bootstraps.
/// Neither has anything to do with student removal, so these fakes stay quiet
/// (empty reads) rather than throwing — a throwing fake would only surface
/// those bootstraps as unhandled async errors and tell us nothing.
class _QuietStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<int?> getInt(String key) async => null;

  @override
  Future<bool?> getBool(String key) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QuietApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QuietEditor implements ActivityEditorCubit {
  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Student maps deliberately carry NO `classroomCode`, so `init`'s fire-and-
/// forget `_loadActivityContextForCreate` returns before touching the editor.
List<Map<String, dynamic>> _students() => <Map<String, dynamic>>[
  <String, dynamic>{'name': 'Ana', 'studentCode': 'STU-A'},
  <String, dynamic>{'name': 'Ben', 'studentCode': 'STU-B'},
  <String, dynamic>{'name': 'Cara', 'studentCode': 'STU-C'},
];

void main() {
  setUp(() {
    // `init` kicks an unawaited school-timezone bootstrap that resolves these.
    if (!serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.registerSingleton<StorageService>(_QuietStorage());
    }
    if (!serviceLocator.isRegistered<ApiClient>()) {
      serviceLocator.registerSingleton<ApiClient>(_QuietApiClient());
    }
  });

  tearDown(() async => serviceLocator.reset());

  group('MedicationActivityCubit.removeStudent', () {
    late MedicationActivityCubit cubit;

    setUp(() {
      cubit = MedicationActivityCubit(
        editor: _QuietEditor(),
        storageService: _QuietStorage(),
      );
      cubit.init(
        isEdit: false,
        readOnly: false,
        selectedStudents: _students(),
      );
    });

    tearDown(() async => cubit.close());

    test('drops the student from the data list that drives the payload', () {
      expect(cubit.state.selectedStudents, ['Ana', 'Ben', 'Cara']);

      cubit.removeStudent('Ana');

      expect(cubit.state.selectedStudents, ['Ben', 'Cara']);
      // The bug: this list kept all three, so submitCreate built studentCodes
      // from it and created the activity for Ana as well.
      expect(
        cubit.state.selectedStudentsData
            .map((m) => m['studentCode'])
            .toList(),
        ['STU-B', 'STU-C'],
        reason: 'a removed student must not reach the submitted payload',
      );
    });

    test('keeps the two lists index-aligned so tiles show the right code', () {
      cubit.removeStudent('Ana');

      final names = cubit.state.selectedStudents;
      final data = cubit.state.selectedStudentsData;
      expect(names.length, data.length);
      for (var i = 0; i < names.length; i++) {
        expect(
          data[i]['name'],
          names[i],
          reason: 'tile $i pairs selectedStudents[i] with '
              'selectedStudentsData[i] — they must describe the same student',
        );
      }
    });

    test('removing every student empties both lists', () {
      for (final name in ['Ana', 'Ben', 'Cara']) {
        cubit.removeStudent(name);
      }
      expect(cubit.state.selectedStudents, isEmpty);
      expect(cubit.state.selectedStudentsData, isEmpty);
    });

    test('removing an unknown name changes nothing', () {
      cubit.removeStudent('Nobody');
      expect(cubit.state.selectedStudents, ['Ana', 'Ben', 'Cara']);
      expect(cubit.state.selectedStudentsData.length, 3);
    });
  });

  group('BottleActivityCubit.removeStudent (already correct — locked in)', () {
    test('drops the student from both lists', () async {
      final cubit = BottleActivityCubit(
        editor: _QuietEditor(),
        storageService: _QuietStorage(),
      );
      cubit.init(
        isEdit: false,
        readOnly: false,
        selectedStudents: _students(),
      );

      cubit.removeStudent('Ben');

      expect(cubit.state.selectedStudents, ['Ana', 'Cara']);
      expect(
        cubit.state.selectedStudentsData
            .map((m) => m['studentCode'])
            .toList(),
        ['STU-A', 'STU-C'],
      );
      await cubit.close();
    });
  });
}
