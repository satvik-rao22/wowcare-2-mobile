import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';
import 'package:wowcare/domain/features/staff/entities/staff_documents_page.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/delete_staff_document_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_documents_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/load_cached_staff_documents_usecase.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_documents_list_cubit.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

// Covers the paths of StaffDocumentsListCubit the existing download-only test
// leaves untested: cache-first loadInitial + revalidate, loadNextPage
// pagination (append), and deleteDocument's guarded single-flight + refresh.
//
// GUARD NOTE: unlike StaffCubit, StaffDocumentsListCubit has NO
// generation/school-isolation guard — it protects late emits only with
// `isClosed`, and there is no per-request sequence counter, so a stale (e.g.
// wrong-staff) refresh response is NOT discarded by the cubit. There is
// therefore no stale-response-discarded case to assert here; the only
// concurrency guard it does enforce is the per-document delete single-flight
// (via `_deletingDocuments`), which is tested below. Its loadNextPage also
// does NOT dedup by document code/uuid — it blindly concatenates pages — which
// is likewise pinned below.

StaffDocument _doc(String uuid) => StaffDocument(
  documentUuid: uuid,
  documentType: 'Educational',
  documentName: '$uuid.pdf',
  documentUrl: 'https://cdn.example/$uuid.pdf',
  documentSizeKb: 1,
  mimeType: 'application/pdf',
);

StaffDocumentsPage _page(
  List<String> uuids, {
  int page = 0,
  bool hasMore = false,
}) => StaffDocumentsPage(
  items: uuids.map(_doc).toList(),
  page: page,
  size: 10,
  totalPages: hasMore ? page + 2 : page + 1,
  totalElements: uuids.length,
  hasMore: hasMore,
);

class _UnusedRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Repo that also satisfies [StaffRepositoryWithCache] so the cache-first
/// branch of loadInitial fires. Returns [cached] once, or null when unset.
class _CachingRepo implements StaffRepository, StaffRepositoryWithCache {
  StaffDocumentsPage? cached;
  @override
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(
    String staffCode,
  ) async => cached;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Queue-backed fake for the paged GET use case. Records the page indices asked
/// for so the delete-triggered refresh can be observed. Falls back to an empty
/// page when the queue drains (so an unawaited revalidation never throws).
class _QueueGet extends GetStaffDocumentsUseCase {
  _QueueGet() : super(_UnusedRepo());
  final List<StaffDocumentsPage> _queue = <StaffDocumentsPage>[];
  final List<int> requestedPages = <int>[];
  int calls = 0;
  void enqueue(StaffDocumentsPage p) => _queue.add(p);

  @override
  Future<StaffDocumentsPage> call({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) async {
    calls++;
    requestedPages.add(page);
    return _queue.isNotEmpty ? _queue.removeAt(0) : _page(const []);
  }
}

/// Delete use case stub: returns a queued Either (defaults to success), and
/// counts how many times it is invoked so single-flight can be asserted.
class _StubDelete extends DeleteStaffDocumentUseCase {
  _StubDelete() : super(_UnusedRepo());
  int calls = 0;
  Either<Failure, String> result = const Right('deleted');

  @override
  Future<Either<Failure, String>> call({
    required String documentUuid,
    required String staffCode,
  }) async {
    calls++;
    return result;
  }
}

/// The cubit no longer holds a repository — the cache read moved behind
/// [LoadCachedStaffDocumentsUseCase] so it stops type-testing the repository
/// itself. The fake repo is now handed to that use case instead.
class _UnusedImageUpload implements ImageUploadService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

StaffDocumentsListCubit _cubit({
  required _QueueGet get,
  required _StubDelete del,
  StaffRepository? repo,
}) {
  final repository = repo ?? _UnusedRepo();
  return StaffDocumentsListCubit(
    getStaffDocumentsUseCase: get,
    deleteStaffDocumentUseCase: del,
    loadCachedStaffDocumentsUseCase: LoadCachedStaffDocumentsUseCase(
      repository,
    ),
    imageUploadService: _UnusedImageUpload(),
  );
}

void main() {
  group('loadInitial', () {
    test(
      'cache-first: emits cached (isFromCache) then revalidates from API',
      () async {
        final get = _QueueGet()..enqueue(_page(['api-1', 'api-2']));
        final repo = _CachingRepo()..cached = _page(['cache-1']);
        final cubit = _cubit(get: get, del: _StubDelete(), repo: repo);

        final seen = <StaffDocumentsListState>[];
        final sub = cubit.stream.listen(seen.add);

        await cubit.loadInitial('STF-1');
        // let the unawaited revalidation settle
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // First emit is the cached snapshot…
        expect(seen.first.isFromCache, isTrue);
        expect(seen.first.documents.map((d) => d.documentUuid), ['cache-1']);
        expect(seen.first.currentPage, 0);
        // …and the terminal state is the revalidated API page.
        expect(cubit.state.isFromCache, isFalse);
        expect(cubit.state.documents.map((d) => d.documentUuid), [
          'api-1',
          'api-2',
        ]);
        expect(get.calls, 1); // exactly one revalidation

        await sub.cancel();
        await cubit.close();
      },
    );

    test(
      'no cache: loads straight from the API (single page 0 fetch)',
      () async {
        final get = _QueueGet()..enqueue(_page(['a', 'b'], hasMore: true));
        final cubit = _cubit(
          get: get,
          del: _StubDelete(),
        ); // _UnusedRepo, no cache

        await cubit.loadInitial('STF-1');

        expect(get.requestedPages, [0]);
        expect(cubit.state.isFromCache, isFalse);
        expect(cubit.state.documents.map((d) => d.documentUuid), ['a', 'b']);
        expect(cubit.state.hasMore, isTrue);

        await cubit.close();
      },
    );
  });

  group('loadNextPage', () {
    test('appends the next page onto the current list', () async {
      final get = _QueueGet()
        ..enqueue(_page(['a', 'b'], page: 0, hasMore: true))
        ..enqueue(_page(['c', 'd'], page: 1, hasMore: false));
      final cubit = _cubit(get: get, del: _StubDelete());

      await cubit.loadInitial('STF-1');
      await cubit.loadNextPage('STF-1');

      expect(cubit.state.documents.map((d) => d.documentUuid), [
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(cubit.state.currentPage, 1);
      expect(cubit.state.hasMore, isFalse);
      expect(get.requestedPages, [0, 1]);

      await cubit.close();
    });

    test(
      'does NOT dedup — an overlapping uuid is retained twice (no guard)',
      () async {
        final get = _QueueGet()
          ..enqueue(_page(['a', 'b'], page: 0, hasMore: true))
          ..enqueue(_page(['b', 'c'], page: 1, hasMore: false)); // b overlaps
        final cubit = _cubit(get: get, del: _StubDelete());

        await cubit.loadInitial('STF-1');
        await cubit.loadNextPage('STF-1');

        // The cubit blindly concatenates, so 'b' appears twice.
        expect(cubit.state.documents.map((d) => d.documentUuid), [
          'a',
          'b',
          'b',
          'c',
        ]);

        await cubit.close();
      },
    );

    test('is a no-op when there is no more data', () async {
      final get = _QueueGet()..enqueue(_page(['a'], page: 0, hasMore: false));
      final cubit = _cubit(get: get, del: _StubDelete());

      await cubit.loadInitial('STF-1');
      await cubit.loadNextPage('STF-1'); // hasMore == false

      expect(get.requestedPages, [0]); // no second fetch
      expect(cubit.state.documents.map((d) => d.documentUuid), ['a']);

      await cubit.close();
    });
  });

  group('deleteDocument', () {
    test(
      'success: returns null and triggers a guarded refresh (page 0)',
      () async {
        final get = _QueueGet()
          ..enqueue(_page(['a', 'b'], page: 0, hasMore: false)) // initial
          ..enqueue(
            _page(['a'], page: 0, hasMore: false),
          ); // post-delete refresh
        final del = _StubDelete()..result = const Right('ok');
        final cubit = _cubit(get: get, del: del, repo: _UnusedRepo());

        await cubit.loadInitial('STF-1');
        final err = await cubit.deleteDocument('STF-1', 'b');
        await Future<void>.delayed(Duration.zero); // let refresh settle

        expect(err, isNull);
        expect(del.calls, 1);
        // Refresh re-fetched page 0 after the delete.
        expect(get.requestedPages, [0, 0]);
        expect(cubit.state.documents.map((d) => d.documentUuid), ['a']);

        await cubit.close();
      },
    );

    test('failure: returns the error message and does NOT refresh', () async {
      final get = _QueueGet()..enqueue(_page(['a'], page: 0, hasMore: false));
      final del = _StubDelete()..result = const Left(ServerFailure('nope'));
      final cubit = _cubit(get: get, del: del);

      await cubit.loadInitial('STF-1');
      final err = await cubit.deleteDocument('STF-1', 'a');

      expect(err, isNotNull);
      expect(get.requestedPages, [0]); // no refresh on failure

      await cubit.close();
    });

    test(
      'single-flight: a second delete of the same uuid in flight is ignored',
      () async {
        final get = _QueueGet()..enqueue(_page(['a'], page: 0, hasMore: false));
        final del = _StubDelete();
        final cubit = _cubit(get: get, del: del);
        await cubit.loadInitial('STF-1');

        // Fire two concurrent deletes of the same uuid; the second must be a no-op.
        final f1 = cubit.deleteDocument('STF-1', 'a');
        final f2 = cubit.deleteDocument('STF-1', 'a');
        await Future.wait([f1, f2]);

        expect(await f2, isNull); // ignored duplicate returns null
        expect(del.calls, 1); // only one delete actually ran

        await cubit.close();
      },
    );
  });
}
