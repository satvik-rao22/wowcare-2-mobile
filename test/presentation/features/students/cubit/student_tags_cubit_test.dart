import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_tag_names_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_tags_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_tags_cubit.dart';

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetStudentTagNamesUseCase extends GetStudentTagNamesUseCase {
  _FakeGetStudentTagNamesUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  List<String> result = const <String>[];
  Object? error;

  @override
  Future<List<String>> call({required String studentCode}) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGetTagNamesForSchoolUseCase extends GetTagNamesForSchoolUseCase {
  _FakeGetTagNamesForSchoolUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> schoolCodes = <String>[];
  List<String> result = const <String>[];
  Object? error;

  @override
  Future<List<String>> call({required String schoolCode}) async {
    calls++;
    schoolCodes.add(schoolCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGetTagNameCodeMapForSchoolUseCase
    extends GetTagNameCodeMapForSchoolUseCase {
  _FakeGetTagNameCodeMapForSchoolUseCase() : super(_FakeRepo());

  int calls = 0;
  Map<String, String> result = const <String, String>{};
  Object? error;

  @override
  Future<Map<String, String>> call({required String schoolCode}) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeUpdateStudentTagsUseCase extends UpdateStudentTagsUseCase {
  _FakeUpdateStudentTagsUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'updated';
  Completer<String>? gate;

  @override
  Future<String> call({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final getStudentTagNames = _FakeGetStudentTagNamesUseCase();
  final getTagNamesForSchool = _FakeGetTagNamesForSchoolUseCase();
  final getTagNameCodeMap = _FakeGetTagNameCodeMapForSchoolUseCase();
  final update = _FakeUpdateStudentTagsUseCase();

  StudentTagsCubit build() => StudentTagsCubit(
    getStudentTagNamesUseCase: getStudentTagNames,
    getTagNamesForSchoolUseCase: getTagNamesForSchool,
    getTagNameCodeMapForSchoolUseCase: getTagNameCodeMap,
    updateStudentTagsUseCase: update,
  );
}

void main() {
  group('reads return the use-case value', () {
    test('fetchStudentTagNames', () async {
      final fakes = _Fakes();
      fakes.getStudentTagNames.result = ['5 Days', 'Vegetarian'];
      final cubit = fakes.build();

      final names = await cubit.fetchStudentTagNames('S1');

      expect(fakes.getStudentTagNames.calls, 1);
      expect(fakes.getStudentTagNames.studentCodes.last, 'S1');
      expect(names, ['5 Days', 'Vegetarian']);
      await cubit.close();
    });

    test('fetchTagNamesForSchool', () async {
      final fakes = _Fakes();
      fakes.getTagNamesForSchool.result = ['A', 'B'];
      final cubit = fakes.build();

      final names = await cubit.fetchTagNamesForSchool('SCH');

      expect(fakes.getTagNamesForSchool.calls, 1);
      expect(fakes.getTagNamesForSchool.schoolCodes.last, 'SCH');
      expect(names, ['A', 'B']);
      await cubit.close();
    });

    test('fetchTagNameCodeMap', () async {
      final fakes = _Fakes();
      fakes.getTagNameCodeMap.result = {'A': 'TAG_A'};
      final cubit = fakes.build();

      final map = await cubit.fetchTagNameCodeMap('SCH');

      expect(fakes.getTagNameCodeMap.calls, 1);
      expect(map, {'A': 'TAG_A'});
      await cubit.close();
    });
  });

  group('updateTags', () {
    test('calls the update use case and returns its message', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.updateTags(
        studentCode: 'S1',
        schoolCode: 'SCH',
        tagCodes: const ['TAG_A'],
      );

      expect(fakes.update.calls, 1);
      expect(message, 'updated');
      await cubit.close();
    });

    test('rethrows on error', () async {
      final fakes = _Fakes();
      fakes.update.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateTags(
          studentCode: 'S1',
          schoolCode: 'SCH',
          tagCodes: const ['TAG_A'],
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateTags for the same studentCode issue '
    'ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.update.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.updateTags(
        studentCode: 'S1',
        schoolCode: 'SCH',
        tagCodes: const ['TAG_A'],
      );
      final f2 = cubit.updateTags(
        studentCode: 'S1',
        schoolCode: 'SCH',
        tagCodes: const ['TAG_A'],
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.update.calls, 1);

      gate.complete('updated');
      await Future.wait<String>([f1, f2]);

      expect(fakes.update.calls, 1);
      await cubit.close();
    },
  );
}
