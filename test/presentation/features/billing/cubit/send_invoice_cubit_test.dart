import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/issue_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/resend_invoice_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/send_invoice_cubit.dart';

const _okResult = InvoiceResultEntity(code: 'INV-1');

class _FakeInvoiceRepo implements InvoiceRepository {
  int issueCount = 0;
  int resendCount = 0;
  Completer<InvoiceResultEntity>? gate;
  Object? throwError;

  @override
  Future<InvoiceResultEntity> issueInvoice(String code) {
    issueCount++;
    if (throwError != null) return Future.error(throwError!);
    if (gate != null) return gate!.future;
    return Future.value(_okResult);
  }

  @override
  Future<InvoiceResultEntity> resendInvoice(String code) {
    resendCount++;
    if (throwError != null) return Future.error(throwError!);
    if (gate != null) return gate!.future;
    return Future.value(_okResult);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStudentRepo implements StudentRepository {
  @override
  Future<StudentProfile> getStudentProfile({required String code}) async =>
      const StudentProfile(
        code: 'STU-1',
        schoolCode: 'SCH-1',
        fullName: 'Ada Lovelace',
        classroomName: 'Room A',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

SendInvoiceCubit _build(_FakeInvoiceRepo repo) => SendInvoiceCubit(
      getStudentProfile: GetStudentProfileUseCase(_FakeStudentRepo()),
      issueInvoice: IssueInvoiceUseCase(repo),
      resendInvoice: ResendInvoiceUseCase(repo),
    );

void main() {
  test('two concurrent sends fire ONE underlying issue (single-flight)',
      () async {
    final repo = _FakeInvoiceRepo()..gate = Completer<InvoiceResultEntity>();
    final cubit = _build(repo);

    final f1 = cubit.send(invoiceCode: 'INV-1', isDraft: true);
    final f2 = cubit.send(invoiceCode: 'INV-1', isDraft: true);

    repo.gate!.complete(_okResult);
    final r1 = await f1;
    final r2 = await f2;

    expect(repo.issueCount, 1, reason: 'second tap must not fire a 2nd issue');
    expect(r1, SendInvoiceOutcome.success);
    expect(r2, SendInvoiceOutcome.success);
    await cubit.close();
  });

  test('draft issues, non-draft resends', () async {
    final repo = _FakeInvoiceRepo();
    final cubit = _build(repo);

    expect(await cubit.send(invoiceCode: 'INV-1', isDraft: true),
        SendInvoiceOutcome.success);
    expect(await cubit.send(invoiceCode: 'INV-1', isDraft: false),
        SendInvoiceOutcome.success);

    expect(repo.issueCount, 1);
    expect(repo.resendCount, 1);
    await cubit.close();
  });

  test('missing invoice code short-circuits without hitting the repo',
      () async {
    final repo = _FakeInvoiceRepo();
    final cubit = _build(repo);

    expect(await cubit.send(invoiceCode: '  ', isDraft: true),
        SendInvoiceOutcome.missingCode);
    expect(repo.issueCount, 0);
    expect(repo.resendCount, 0);
    await cubit.close();
  });

  test('a failed send surfaces failure + message and clears the in-flight lock',
      () async {
    final repo = _FakeInvoiceRepo()..throwError = Exception('boom');
    final cubit = _build(repo);

    expect(await cubit.send(invoiceCode: 'INV-1', isDraft: true),
        SendInvoiceOutcome.failure);
    expect(cubit.state.isSending, false);
    expect(cubit.state.errorMessage, isNotNull);

    // Lock released: a subsequent send is attempted again (not swallowed).
    repo.throwError = null;
    expect(await cubit.send(invoiceCode: 'INV-1', isDraft: true),
        SendInvoiceOutcome.success);
    expect(repo.issueCount, 2);
    await cubit.close();
  });
}
