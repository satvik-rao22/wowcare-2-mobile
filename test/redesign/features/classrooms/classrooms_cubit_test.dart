import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classrooms_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('ClassroomsCubit', () {
    test('loads the floor and the school figures with it', () async {
      final cubit = ClassroomsCubit(source: const PreviewClassroomsSource());
      expect(cubit.state.status, ClassroomsStatus.loading);

      await cubit.load();

      expect(cubit.state.status, ClassroomsStatus.ready);
      expect(cubit.state.board.classroomCount, 5);
      expect(cubit.state.board.studentsPresent, 47);
      expect(cubit.state.board.staffOnDuty, 12);
      expect(cubit.state.board.percentFull, 81);
      await cubit.close();
    });

    test('one classroom is short of staff and one is empty', () async {
      final cubit = ClassroomsCubit(source: const PreviewClassroomsSource());
      await cubit.load();

      expect(cubit.state.board.overRatioCount, 1);
      expect(cubit.state.board.emptyCount, 1);

      final short = cubit.state.board.classrooms.firstWhere(
        (r) => !r.isInRatio,
      );
      expect(short.name, 'Bluebell');
      expect(short.staffNeeded, 1);
      await cubit.close();
    });

    test('the chips filter, and attention sorts first', () async {
      final cubit = ClassroomsCubit(source: const PreviewClassroomsSource());
      await cubit.load();

      expect(cubit.state.visible.first.name, 'Bluebell');

      cubit.selectSegment(ClassroomSegment.overRatio);
      expect(cubit.state.visible.map((r) => r.name), <String>['Bluebell']);

      cubit.selectSegment(ClassroomSegment.empty);
      expect(cubit.state.visible.map((r) => r.name), <String>['Willow']);
      await cubit.close();
    });

    test('search narrows the floor, and clearing puts it back', () async {
      final cubit = ClassroomsCubit(source: const PreviewClassroomsSource());
      await cubit.load();

      cubit.search('sun');
      expect(cubit.state.visible.map((r) => r.name), <String>['Sunflower']);
      expect(cubit.state.isSearching, isTrue);

      cubit.search('brennan');
      expect(cubit.state.hasNoMatches, isTrue);

      cubit.clearSearch();
      expect(cubit.state.visible.length, 5);
      await cubit.close();
    });

    test(
      'a school with no classrooms is its own state, not a failure',
      () async {
        final cubit = ClassroomsCubit(source: const EmptyClassroomsSource());
        await cubit.load();

        expect(cubit.state.status, ClassroomsStatus.ready);
        expect(cubit.state.hasNoClassrooms, isTrue);
        await cubit.close();
      },
    );

    test('nothing reachable and nothing cached fails outright', () async {
      final cubit = ClassroomsCubit(source: const FailingClassroomsSource());
      await cubit.load();

      expect(cubit.state.status, ClassroomsStatus.failed);
      expect(cubit.state.isFailed, isTrue);
      await cubit.close();
    });

    test('a floor already on screen stays up and says it is cached', () async {
      final cubit = ClassroomsCubit(source: const _FlakySource());
      await cubit.load();
      expect(cubit.state.status, ClassroomsStatus.ready);

      await cubit.refresh();

      expect(cubit.state.status, ClassroomsStatus.cached);
      expect(cubit.state.board.classroomCount, 5);
      await cubit.close();
    });
  });
}

/// Answers once, then stops answering: the way a screen ends up showing what
/// it last reached.
class _FlakySource extends PreviewClassroomsSource {
  const _FlakySource();

  static int _calls = 0;

  @override
  Future<ClassroomBoard> loadBoard() async {
    _calls += 1;
    if (_calls > 1) throw Exception('offline');
    return super.loadBoard();
  }
}
