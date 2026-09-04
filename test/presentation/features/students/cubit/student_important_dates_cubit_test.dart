import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_important_dates_cubit.dart';

/// Repository that fails loudly — the use-case fake never touches it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeUpdateUseCase extends UpdateStudentImportantDatesUseCase {
  _FakeUpdateUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  final List<StudentImportantDates> passedDates = <StudentImportantDates>[];
  Either<Failure, String> result = const Right('Updated');

  @override
  Future<Either<Failure, String>> call({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    calls++;
    studentCodes.add(studentCode);
    passedDates.add(dates);
    return result;
  }
}

void main() {
  late _FakeUpdateUseCase useCase;

  StudentImportantDatesCubit build() => StudentImportantDatesCubit(
        updateStudentImportantDatesUseCase: useCase,
      );

  setUp(() {
    useCase = _FakeUpdateUseCase();
  });

  final enroll = DateTime(2026, 1, 15);
  final schoolStart = DateTime(2026, 2, 1);

  group('initial state', () {
    test('has null dates and no loading/success/error', () {
      final cubit = build();
      expect(cubit.state.enrollDate, isNull);
      expect(cubit.state.schoolStartDate, isNull);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isError, isFalse);
    });
  });

  group('seed + edit', () {
    test('initialize seeds both dates', () {
      final cubit = build();
      cubit.initialize(enrollDate: enroll, schoolStartDate: schoolStart);
      expect(cubit.state.enrollDate, enroll);
      expect(cubit.state.schoolStartDate, schoolStart);
    });

    test('initialize can seed nulls (missing dates)', () {
      final cubit = build()
        ..initialize(enrollDate: enroll, schoolStartDate: schoolStart);
      cubit.initialize(enrollDate: null, schoolStartDate: null);
      expect(cubit.state.enrollDate, isNull);
      expect(cubit.state.schoolStartDate, isNull);
    });

    test('setEnrollDate updates only the enroll date', () {
      final cubit = build()
        ..initialize(enrollDate: null, schoolStartDate: schoolStart);
      cubit.setEnrollDate(enroll);
      expect(cubit.state.enrollDate, enroll);
      expect(cubit.state.schoolStartDate, schoolStart);
    });

    test('setSchoolStartDate updates only the school-start date', () {
      final cubit = build()
        ..initialize(enrollDate: enroll, schoolStartDate: null);
      cubit.setSchoolStartDate(schoolStart);
      expect(cubit.state.schoolStartDate, schoolStart);
      expect(cubit.state.enrollDate, enroll);
    });

    test('editing a field clears a prior error banner', () async {
      useCase.result = const Left(ServerFailure('nope'));
      final cubit = build();
      await cubit.save(studentCode: 'S1');
      expect(cubit.state.isError, isTrue);

      cubit.setEnrollDate(enroll);
      expect(cubit.state.isError, isFalse);
      expect(cubit.state.message, isNull);
    });
  });

  group('save', () {
    test('builds dates from state and reports success', () async {
      useCase.result = const Right('Saved');
      final cubit = build()
        ..initialize(enrollDate: enroll, schoolStartDate: schoolStart);

      final emitted = <StudentImportantDatesState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.save(studentCode: 'S1');

      expect(useCase.calls, 1);
      expect(useCase.studentCodes.single, 'S1');
      expect(useCase.passedDates.single.enrollDate, enroll);
      expect(useCase.passedDates.single.schoolStartDate, schoolStart);

      // loading → success, in order.
      expect(emitted.first.isLoading, isTrue);
      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.message, 'Saved');
      // Dates survive the round-trip.
      expect(cubit.state.enrollDate, enroll);
      expect(cubit.state.schoolStartDate, schoolStart);

      await sub.cancel();
    });

    test('reports error and preserves the edited dates', () async {
      useCase.result = const Left(ServerFailure('server down'));
      final cubit = build()
        ..initialize(enrollDate: enroll, schoolStartDate: schoolStart);

      await cubit.save(studentCode: 'S1');

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, 'server down');
      expect(cubit.state.enrollDate, enroll);
      expect(cubit.state.schoolStartDate, schoolStart);
    });

    test('sends the latest edited values, not the seeded ones', () async {
      useCase.result = const Right('ok');
      final cubit = build()..initialize(enrollDate: null, schoolStartDate: null);
      cubit.setEnrollDate(enroll);
      cubit.setSchoolStartDate(schoolStart);

      await cubit.save(studentCode: 'S9');

      expect(useCase.passedDates.single.enrollDate, enroll);
      expect(useCase.passedDates.single.schoolStartDate, schoolStart);
    });
  });
}
