// Regression tests for P1-2: a classroom-scoped staff member must never issue
// an unrestricted newsletter query.
//
// The dangerous state is reachable when `getStaffProfile()` fails AND the
// device has no cached allowed classroom codes AND the classroom list is
// empty. Before the fix that produced `classroomCodes: []`, which the
// datasource turns into a query with no `classroomCode` parameter at all —
// i.e. every classroom in the school.
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/paginated_newsletters_entity.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';
import 'package:wowcare/domain/features/newsletter/usecases/get_sent_newsletters_usecase.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/newsletter_list_cubit.dart';

class _RecordingRepository implements NewsletterRepository {
  final List<List<String>> queriedClassroomCodes = <List<String>>[];

  @override
  Future<NewsletterPage> getSentNewsletters({
    required String schoolCode,
    String? search,
    List<String> classroomCodes = const <String>[],
    int page = 0,
    int size = 10,
  }) async {
    queriedClassroomCodes.add(classroomCodes);
    return const NewsletterPage(
      items: <Newsletter>[],
      page: 0,
      size: 10,
      totalPages: 0,
      totalElements: 0,
      hasMore: false,
    );
  }

  @override
  Future<Newsletter> getNewsletterByCode(String code) =>
      throw UnimplementedError();
}

class _NoopStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

NewsletterListCubit _cubit(_RecordingRepository repo) => NewsletterListCubit(
      getSentNewslettersUseCase: GetSentNewslettersUseCase(repo),
      repository: repo,
      storageService: _NoopStorage(),
    );

void main() {
  late _RecordingRepository repo;
  late NewsletterListCubit cubit;

  setUp(() {
    repo = _RecordingRepository();
    cubit = _cubit(repo);
  });

  group('effectiveClassroomCodes', () {
    test('an UNSCOPED user passes their selection through unchanged', () {
      expect(cubit.effectiveClassroomCodes(const []), const <String>[]);
      expect(cubit.effectiveClassroomCodes(const ['C1']), const ['C1']);
    });

    test('a scoped user always gets their primary classroom included', () {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            primaryClassroomCode: 'PRIMARY',
          ),
        );
      expect(scoped.effectiveClassroomCodes(const ['C1']),
          containsAll(<String>['PRIMARY', 'C1']));
    });

    test('a scoped user with no primary falls back to their first allowed', () {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            allowedClassroomCodes: <String>['A1', 'A2'],
          ),
        );
      expect(scoped.effectiveClassroomCodes(const []), const ['A1']);
    });

    test(
        'REGRESSION: a scoped user with NOTHING resolvable returns null, '
        'never an empty (= unrestricted) list', () {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
          ),
        );
      expect(scoped.effectiveClassroomCodes(const []), isNull);
      expect(scoped.hasUnresolvableScope(const []), isTrue);
    });
  });

  group('bootstrapStaffList', () {
    test('REGRESSION: an unresolvable scope issues NO query and surfaces an '
        'error instead of listing the whole school', () async {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            schoolCode: 'SCH_1',
          ),
        );

      await scoped.bootstrapStaffList(
        defaultNames: const <String>[],
        selectedCodes: const <String>[],
        search: '',
      );

      expect(repo.queriedClassroomCodes, isEmpty,
          reason: 'no request may be issued at all');
      expect(scoped.state.errorMessage, isNotNull);
    });

    test('REGRESSION: it does NOT latch isStaffListBootstrapped on failure, '
        'so a later retry can still succeed', () async {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            schoolCode: 'SCH_1',
            allowedClassroomCodes: const <String>[],
          ),
        );

      await scoped.bootstrapStaffList(
        defaultNames: const <String>[],
        selectedCodes: const <String>[],
        search: '',
      );
      expect(scoped.state.isStaffListBootstrapped, isFalse);

      // The classroom list arrives on a retry — the bootstrap now succeeds.
      await scoped.bootstrapStaffList(
        defaultNames: const <String>['Room A'],
        selectedCodes: const <String>['ROOM_A'],
        search: '',
      );
      expect(scoped.state.isStaffListBootstrapped, isTrue);
      expect(repo.queriedClassroomCodes.single, const <String>['ROOM_A']);
    });

    test('a resolvable scope queries with exactly those codes', () async {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            schoolCode: 'SCH_1',
            primaryClassroomCode: 'PRIMARY',
          ),
        );

      await scoped.bootstrapStaffList(
        defaultNames: const <String>['Room A'],
        selectedCodes: const <String>['ROOM_A'],
        search: '',
      );
      expect(repo.queriedClassroomCodes.single,
          containsAll(<String>['PRIMARY', 'ROOM_A']));
    });
  });

  group('refresh', () {
    test('REGRESSION: pull-to-refresh is not a second route to an '
        'unrestricted query', () async {
      final scoped = _cubit(repo)
        ..emit(
          const NewsletterListState.initial().copyWith(
            isStaffScoped: true,
            isScopeResolved: true,
            schoolCode: 'SCH_1',
          ),
        );

      await scoped.refresh();

      expect(repo.queriedClassroomCodes, isEmpty);
      expect(scoped.state.errorMessage, isNotNull);
    });

    test('an unscoped user refreshes normally', () async {
      cubit.emit(
        const NewsletterListState.initial().copyWith(schoolCode: 'SCH_1'),
      );
      await cubit.refresh();
      expect(repo.queriedClassroomCodes, hasLength(1));
    });
  });
}
