import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/add_staff_document_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_document_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';

/// Hand-written fake standing in for the [StaffRepository] add/update document
/// calls the cubit routes through its use cases. Both writes park on an
/// optional gate so a caller can hold the op in flight and tear the cubit down
/// mid-flight. Everything else throws via [noSuchMethod].
class _FakeRepo implements StaffRepository {
  int addCalls = 0;
  int updateCalls = 0;
  String result = 'ok';

  /// When set, [addStaffDocument]/[updateStaffDocument] block on this gate so a
  /// close() can happen while the write is still in flight.
  Completer<String>? gate;

  @override
  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
  }) {
    addCalls++;
    if (gate != null) return gate!.future;
    return Future<String>.value(result);
  }

  @override
  Future<String> updateStaffDocument({
    required String documentUuid,
    required StaffDocument document,
    required String staffCode,
  }) {
    updateCalls++;
    if (gate != null) return gate!.future;
    return Future<String>.value(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

StaffDocumentCubit _cubit(_FakeRepo repo) => StaffDocumentCubit(
  addStaffDocumentUseCase: AddStaffDocumentUseCase(repo),
  updateStaffDocumentUseCase: UpdateStaffDocumentUseCase(repo),
);

const _doc = StaffDocument(
  documentType: 'Educational',
  documentName: 'cert.pdf',
  documentUrl: '',
  documentSizeKb: 1,
  mimeType: 'application/pdf',
);

void main() {
  test(
    'emits a real loading state while the add is in flight, so the save '
    "button's spinner can actually show",
    () async {
      final repo = _FakeRepo()..gate = Completer<String>();
      final cubit = _cubit(repo);
      addTearDown(cubit.close);

      expect(cubit.state.isLoading, isFalse);
      final pending = cubit.addDocument(staffCode: 'STF-1', document: _doc);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoading, isTrue);

      repo.gate!.complete('saved');
      await pending;
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isSuccess, isTrue);
    },
  );

  test('addDocument emits a success state carrying the API message', () async {
    final repo = _FakeRepo()..result = 'Added!';
    final cubit = _cubit(repo);

    await cubit.addDocument(staffCode: 'S1', document: _doc);

    expect(cubit.state.isSuccess, isTrue);
    expect(cubit.state.message, 'Added!');
    expect(repo.addCalls, 1);
    await cubit.close();
  });

  test(
    'an addDocument whose response lands after the cubit is closed does NOT '
    'emit (isClosed guard — no emit-after-close StateError)',
    () async {
      final repo = _FakeRepo()..gate = Completer<String>();
      final cubit = _cubit(repo);

      final pending = cubit.addDocument(staffCode: 'S1', document: _doc);
      await Future<void>.delayed(Duration.zero);

      // Tear down while the add is in flight, then let the response resolve.
      await cubit.close();
      repo.gate!.complete('done');

      await expectLater(pending, completes);
      expect(cubit.isClosed, isTrue);
    },
  );

  test(
    'an updateDocument whose response lands after the cubit is closed does NOT '
    'emit (isClosed guard)',
    () async {
      final repo = _FakeRepo()..gate = Completer<String>();
      final cubit = _cubit(repo);

      final pending = cubit.updateDocument(
        documentUuid: 'U1',
        staffCode: 'S1',
        document: _doc,
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      repo.gate!.complete('done');

      await expectLater(pending, completes);
      expect(cubit.isClosed, isTrue);
    },
  );
}
