import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/entities/student_document.dart';
import 'package:wowcare/domain/features/student/entities/student_documents_page.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/delete_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_documents_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_documents_list_cubit.dart';

StudentDocument _doc(String uuid) => StudentDocument(
      documentUuid: uuid,
      documentType: 'REPORT',
      documentName: 'file-$uuid.pdf',
      documentUrl: 'file-$uuid.pdf',
      documentSizeKb: 12,
      mimeType: 'application/pdf',
      expiryDate: '2026-01-01',
    );

StudentDocumentsPage _page(
  List<String> uuids, {
  int page = 0,
  bool hasMore = false,
}) =>
    StudentDocumentsPage(
      items: uuids.map(_doc).toList(),
      page: page,
      size: 10,
      totalPages: hasMore ? page + 2 : page + 1,
      totalElements: uuids.length,
      hasMore: hasMore,
    );

/// Plain repository (NOT [StudentRepositoryWithCache]) so `loadInitial` skips
/// the cache path and delegates straight to `refresh`.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetDocs extends GetStudentDocumentsUseCase {
  _FakeGetDocs() : super(_FakeRepo());

  final List<Object> _queue = <Object>[]; // StudentDocumentsPage | Completer | error
  final List<int> requestedPages = <int>[];
  Object? errorToThrow;

  void enqueue(Object response) => _queue.add(response);

  @override
  Future<StudentDocumentsPage> call({
    required String studentCode,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  }) async {
    requestedPages.add(page);
    if (errorToThrow != null) throw errorToThrow!;
    final r = _queue.isNotEmpty ? _queue.removeAt(0) : _page(const []);
    if (r is Completer<StudentDocumentsPage>) return r.future;
    return r as StudentDocumentsPage;
  }
}

class _FakeDeleteDoc extends DeleteStudentDocumentUseCase {
  _FakeDeleteDoc() : super(_FakeRepo());

  int calls = 0;
  Completer<void>? gate;
  Either<Failure, String> result = const Right('deleted');

  @override
  Future<Either<Failure, String>> call({
    required String documentUuid,
    required String studentCode,
  }) async {
    calls++;
    if (gate != null) await gate!.future;
    return result;
  }
}

void main() {
  late _FakeGetDocs getDocs;
  late _FakeDeleteDoc deleteDoc;

  StudentDocumentsListCubit build() => StudentDocumentsListCubit(
        getStudentDocumentsUseCase: getDocs,
        deleteStudentDocumentUseCase: deleteDoc,
        repository: _FakeRepo(),
      );

  setUp(() {
    getDocs = _FakeGetDocs();
    deleteDoc = _FakeDeleteDoc();
  });

  test('initial state is idle and empty', () {
    final cubit = build();
    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.errorMessage, isNull);
  });

  group('refresh', () {
    test('loading → success populates documents', () async {
      getDocs.enqueue(_page(['A', 'B'], hasMore: false));
      final cubit = build();

      final emitted = <StudentDocumentsListState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.refresh('S1');

      expect(emitted.first.isLoading, isTrue); // loading first (list was empty)
      expect(cubit.state.documents.map((d) => d.documentUuid), ['A', 'B']);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isRefreshing, isFalse);
      expect(cubit.state.hasMore, isFalse);
      await sub.cancel();
    });

    test('empty response → loaded with an empty list (not an error)', () async {
      getDocs.enqueue(_page(const []));
      final cubit = build();
      await cubit.refresh('S1');
      expect(cubit.state.documents, isEmpty);
      expect(cubit.state.errorMessage, isNull);
    });

    test('failure → errorMessage set (friendly, not raw)', () async {
      getDocs.errorToThrow = Exception('boom');
      final cubit = build();
      await cubit.refresh('S1');
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isRefreshing, isFalse);
    });

    test('a second refresh while one is in flight is ignored (guard)', () async {
      final gate = Completer<StudentDocumentsPage>();
      getDocs.enqueue(gate);
      final cubit = build();

      final f1 = cubit.refresh('S1'); // holds isRefreshing
      final f2 = cubit.refresh('S1'); // dropped

      gate.complete(_page(['A']));
      await Future.wait([f1, f2]);

      expect(getDocs.requestedPages.where((p) => p == 0).length, 1);
      await cubit.close();
    });

    test('a refresh that resolves after close does not emit (no throw)', () async {
      final gate = Completer<StudentDocumentsPage>();
      getDocs.enqueue(gate);
      final cubit = build();

      final saving = cubit.refresh('S1');
      await cubit.close();
      gate.complete(_page(['A']));
      await saving; // must not throw
    });
  });

  group('loadInitial (no cache repo)', () {
    test('delegates to refresh and loads', () async {
      getDocs.enqueue(_page(['A']));
      final cubit = build();
      await cubit.loadInitial('S1');
      expect(cubit.state.documents.single.documentUuid, 'A');
    });
  });

  group('loadNextPage', () {
    test('appends the next page', () async {
      getDocs.enqueue(_page(['A', 'B'], page: 0, hasMore: true));
      final cubit = build();
      await cubit.refresh('S1');

      getDocs.enqueue(_page(['C'], page: 1, hasMore: false));
      await cubit.loadNextPage('S1');

      expect(cubit.state.documents.map((d) => d.documentUuid), ['A', 'B', 'C']);
      expect(cubit.state.hasMore, isFalse);
    });

    test('is a no-op when there is no next page', () async {
      getDocs.enqueue(_page(['A'], hasMore: false));
      final cubit = build();
      await cubit.refresh('S1');
      final before = getDocs.requestedPages.length;
      await cubit.loadNextPage('S1');
      expect(getDocs.requestedPages.length, before); // no extra request
    });
  });

  group('deleteDocument', () {
    test('duplicate delete of the same doc runs the use case once', () async {
      deleteDoc.gate = Completer<void>();
      final cubit = build();

      final d1 = cubit.deleteDocument('S1', 'DOC1');
      final d2 = cubit.deleteDocument('S1', 'DOC1'); // dropped (single-flight)

      deleteDoc.gate!.complete();
      await Future.wait([d1, d2]);

      expect(deleteDoc.calls, 1);
      await cubit.close();
    });

    test('failure returns the message; success returns null', () async {
      deleteDoc.result = const Left(ServerFailure('cannot delete'));
      final cubit = build();
      final err = await cubit.deleteDocument('S1', 'DOC1');
      expect(err, 'cannot delete');

      deleteDoc.result = const Right('ok');
      getDocs.enqueue(_page(const [])); // the success path triggers a refresh
      final ok = await cubit.deleteDocument('S1', 'DOC2');
      expect(ok, isNull);
    });
  });
}
