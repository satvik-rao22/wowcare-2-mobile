import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/view_invoice_cubit.dart';

InvoiceListItemEntity _detail(String code) => InvoiceListItemEntity(
      code: code,
      organization: 'ORG-1',
      school: 'SCH-1',
      studentCode: 'STU-1',
      subjectOwnerType: 'FAMILY',
      subjectOwnerCode: 'FAM-1',
      amount: 100,
      total: 100,
      paidAmount: 0,
      status: 'ISSUED',
      invoiceStatus: 'UNPAID',
      items: const [],
      dueDate: DateTime.utc(2026, 1, 15),
    );

class _FakeInvoiceRepo implements InvoiceRepository {
  Object? throwError;

  @override
  Future<InvoiceListItemEntity> getInvoiceByCode(String code) {
    if (throwError != null) return Future.error(throwError!);
    return Future.value(_detail(code));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStudentRepo implements StudentRepository {
  Object? throwError;

  @override
  Future<StudentProfile> getStudentProfile({required String code}) {
    if (throwError != null) return Future.error(throwError!);
    return Future.value(const StudentProfile(
      code: 'STU-1',
      schoolCode: 'SCH-1',
      fullName: 'Ada Lovelace',
      classroomName: 'Room A',
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

ViewInvoiceCubit _build(_FakeInvoiceRepo invoice, _FakeStudentRepo student) =>
    ViewInvoiceCubit(
      getStudentProfile: GetStudentProfileUseCase(student),
      getInvoiceByCode: GetInvoiceByCodeUseCase(invoice),
    );

void main() {
  test('load populates both room name and invoice detail', () async {
    final cubit = _build(_FakeInvoiceRepo(), _FakeStudentRepo());

    await cubit.load(studentCode: 'STU-1', invoiceCode: 'INV-1');

    expect(cubit.state.roomName, 'Room A');
    expect(cubit.state.invoiceDetail?.code, 'INV-1');
    await cubit.close();
  });

  test('a failed invoice-detail fetch is swallowed; room name still resolves',
      () async {
    final cubit = _build(
      _FakeInvoiceRepo()..throwError = Exception('404'),
      _FakeStudentRepo(),
    );

    await cubit.load(studentCode: 'STU-1', invoiceCode: 'INV-1');

    expect(cubit.state.invoiceDetail, isNull, reason: 'falls back to summary');
    expect(cubit.state.roomName, 'Room A');
    await cubit.close();
  });

  test('blank codes skip both lookups and leave state empty', () async {
    final cubit = _build(_FakeInvoiceRepo(), _FakeStudentRepo());

    await cubit.load(studentCode: '  ', invoiceCode: '');

    expect(cubit.state.roomName, isNull);
    expect(cubit.state.invoiceDetail, isNull);
    await cubit.close();
  });
}
