import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/cancel_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_ledger_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';

import '../widgets/transactions/transaction_item.dart';

part 'transaction_details_state.dart';

/// Owns the family billing-profile screen state: the transaction list, family
/// members (students/guardians), summary totals, date range, and loading/error
/// flags. Real data comes from `GET /api/v1/invoices/family-ledger` via
/// [loadFamilyLedger]; [initialize] keeps demo data for callers without a
/// family code (e.g. opening from a single transaction).
class TransactionDetailsCubit extends Cubit<TransactionDetailsState> {
  TransactionDetailsCubit({
    required GetFamilyLedgerUseCase getFamilyLedger,
    required CancelInvoiceUseCase cancelInvoice,
    required DeleteInvoiceUseCase deleteInvoice,
    required GetStudentPageUseCase getStudentPage,
    required StorageService storage,
  })  : _getFamilyLedger = getFamilyLedger,
        _cancelInvoice = cancelInvoice,
        _deleteInvoice = deleteInvoice,
        _getStudentPage = getStudentPage,
        _storage = storage,
        super(const TransactionDetailsState.initial());

  final GetFamilyLedgerUseCase _getFamilyLedger;
  final CancelInvoiceUseCase _cancelInvoice;
  final DeleteInvoiceUseCase _deleteInvoice;
  final GetStudentPageUseCase _getStudentPage;
  final StorageService _storage;

  String _ownerType = 'FAMILY';
  String _ownerCode = '';

  /// Cancels an invoice then refreshes the ledger. Returns true on success.
  Future<bool> cancelInvoice(String code) async {
    if (code.trim().isEmpty) return false;
    try {
      await _cancelInvoice(code);
      if (_ownerCode.isNotEmpty) {
        await loadFamilyLedger(ownerCode: _ownerCode, ownerType: _ownerType);
      }
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
          hasError: true, errorMessage: ApiErrorHandler.extractErrorMessage(e)));
      return false;
    }
  }

  /// Deletes an invoice then refreshes the ledger. Returns true on success.
  Future<bool> deleteInvoice(String code) async {
    if (code.trim().isEmpty) return false;
    try {
      await _deleteInvoice(code);
      if (_ownerCode.isNotEmpty) {
        await loadFamilyLedger(ownerCode: _ownerCode, ownerType: _ownerType);
      }
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
          hasError: true, errorMessage: ApiErrorHandler.extractErrorMessage(e)));
      return false;
    }
  }

  /// Loads a family's ledger and maps it onto the screen's state shape.
  Future<void> loadFamilyLedger({
    required String ownerCode,
    String ownerType = 'FAMILY',
  }) async {
    _ownerType = ownerType.trim().isEmpty ? 'FAMILY' : ownerType.trim();
    _ownerCode = ownerCode.trim();
    if (_ownerCode.isEmpty) return;

    emit(state.copyWith(
      isLoadingSiblings: true,
      isLoadingFamily: true,
      hasError: false,
      errorMessage: '',
      familyError: '',
    ));
    try {
      final org =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) {
        if (isClosed) return;
        emit(state.copyWith(
          isLoadingSiblings: false,
          isLoadingFamily: false,
          hasError: true,
          errorMessage: 'Missing organization/school context.',
        ));
        return;
      }

      final ledger = await _getFamilyLedger(
        organizationCode: org,
        school: school,
        ownerCode: _ownerCode,
        ownerType: _ownerType,
      );
      if (isClosed) return;
      emit(state.copyWith(
        netPaidAmount: ledger.netPaid,
        amountUnpaid: ledger.unpaid,
        amountInProcess: ledger.inProcess,
        amountRefund: ledger.refunded,
        openBalance: ledger.openBalance,
        siblingTransactions: _mapTransactions(
          ledger.transactions,
          familyName: ledger.familyName,
          familyStudentNames: ledger.students
              .map((s) => s.fullName.trim())
              .where((n) => n.isNotEmpty)
              .join(', '),
          familyGuardianNames: ledger.guardians
              .map((g) => g.fullName.trim())
              .where((n) => n.isNotEmpty)
              .join(', '),
        ),
        familyChildren: _mapPeople(ledger.students),
        familyParents: _mapPeople(ledger.guardians),
        familyName: ledger.familyName,
        isLoadingSiblings: false,
        isLoadingFamily: false,
        hasError: false,
        hasMoreData: false,
      ));

      // Non-fatal: a failure here just leaves the family chips ungreyed and
      // Create Invoice pre-selecting every child, rather than failing the
      // whole ledger load — that already succeeded above.
      unawaited(_resolveInactiveStudentCodes(
        school: school,
        studentCodes: ledger.students
            .map((s) => s.code.trim())
            .where((c) => c.isNotEmpty)
            .toSet(),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingSiblings: false,
        isLoadingFamily: false,
        hasError: true,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
        familyError: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  /// Looks up each family child's enrollment status individually (the
  /// family-ledger API's own `students` list carries no status field) and
  /// records which ones are INACTIVE.
  Future<void> _resolveInactiveStudentCodes({
    required String school,
    required Set<String> studentCodes,
  }) async {
    if (studentCodes.isEmpty) return;
    final inactive = <String>{};
    await Future.wait(studentCodes.map((code) async {
      try {
        final page = await _getStudentPage(
          schoolCode: school,
          code: code,
          page: 0,
          size: 1,
        );
        var student = page.items.isNotEmpty ? page.items.first : null;
        // Several student-list surfaces in this app (see AdminChatHostScreen)
        // default to ACTIVE-only when no status is specified — if that's
        // also true here, an unfiltered lookup for an inactive student's
        // exact code comes back empty rather than returning them with
        // status=INACTIVE. Retry once, explicitly asking for INACTIVE, so
        // this lookup doesn't silently miss them either way.
        if (student == null) {
          final inactivePage = await _getStudentPage(
            schoolCode: school,
            code: code,
            status: 'INACTIVE',
            page: 0,
            size: 1,
          );
          student =
              inactivePage.items.isNotEmpty ? inactivePage.items.first : null;
        }
        if (student != null && student.status.trim().toUpperCase() == 'INACTIVE') {
          inactive.add(code);
        }
      } catch (_) {
        // Leave this student's status unresolved (not marked inactive)
        // rather than failing the whole lookup for one bad code.
      }
    }));
    if (isClosed) return;
    // Always replaces (never merges) so a refresh correctly clears a code
    // that's no longer inactive, not just adds newly-inactive ones.
    emit(state.copyWith(inactiveStudentCodes: inactive));
  }

  List<BillingFamilyMember> _mapPeople(List<FamilyLedgerPersonEntity> people) {
    return people.map(BillingFamilyMember.fromEntity).toList();
  }

  List<TransactionItem> _mapTransactions(
      List<FamilyLedgerTransactionEntity> txns,
      {String familyName = '',
      String familyStudentNames = '',
      String familyGuardianNames = ''}) {
    // `familyName` comes straight from the ledger API and is sometimes blank
    // for a family with no name configured server-side (seen on a QA/test
    // school) — without a fallback, every family-level row (a payment with no
    // studentName/studentCode of its own) rendered a completely blank
    // "Payment For" name and avatar instead of anything identifying. Falls
    // back to the guardians, then the children, before giving up.
    final effectiveFamilyName = familyName.isNotEmpty
        ? familyName
        : (familyGuardianNames.isNotEmpty
            ? familyGuardianNames
            : (familyStudentNames.isNotEmpty ? familyStudentNames : 'Family'));
    return List<TransactionItem>.generate(txns.length, (i) {
      final t = txns[i];
      // Family-level transactions (Payment / Credit / Refund) carry no student.
      final isFamilyLevel = t.studentName.isEmpty && t.studentCode.isEmpty;
      // Header label: the specific student, else the family name. For nameless
      // family-level rows (e.g. a guardian card payment), append the payment
      // status in brackets — e.g. "Fisher Family (In Process)".
      final familyLabel = isFamilyLevel
          ? () {
              final status = _formatTxnStatus(t.status);
              return status.isEmpty
                  ? effectiveFamilyName
                  : '$effectiveFamilyName ($status)';
            }()
          : effectiveFamilyName;
      final resolvedName = t.studentName.isNotEmpty
          ? t.studentName
          : (t.studentCode.isNotEmpty ? t.studentCode : familyLabel);
      // "Student Name" row: all family students for family-level transactions,
      // otherwise the single student.
      final studentNames = isFamilyLevel && familyStudentNames.isNotEmpty
          ? familyStudentNames
          : (t.studentName.isNotEmpty ? t.studentName : null);
      return TransactionItem(
        id: i + 1,
        invoiceCode: t.invoiceCode.isNotEmpty ? t.invoiceCode : null,
        transactionType:
            t.transactionType.isNotEmpty ? t.transactionType : 'Invoice',
        date: t.date ?? billingSchoolNow(),
        amount: t.amount,
        paidAmount: t.paidAmount,
        refundedAmount: t.refundedAmount,
        status: t.status,
        description: t.description.isNotEmpty
            ? t.description
            : (t.items.isNotEmpty ? t.items.first : ''),
        studentName: resolvedName,
        studentNames: studentNames,
        classroom: '',
        studentCode: t.studentCode.isNotEmpty ? t.studentCode : null,
        refTable: t.transactionType,
        balance: t.balance,
        paymentMode: t.method.isNotEmpty ? t.method : null,
        studentOpenBalance: t.balance,
        fullyReduced: t.fullyReduced,
      );
    });
  }

  /// Human-friendly status for the family-row label, e.g. `IN_PROCESS` /
  /// `In_Process` → `In Process`, `SUCCESS` → `Success`.
  String _formatTxnStatus(String status) {
    final trimmed = status.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Opened without a family code (e.g. from a single transaction): there is no
  /// ledger to fetch, so leave the screen empty rather than showing demo data.
  Future<void> initialize() async {
    emit(state.copyWith(
      isLoadingSiblings: false,
      isLoadingFamily: false,
      hasMoreData: false,
    ));
  }

  /// Re-fetches the family ledger (used by pull-to-refresh / error retry). No-op
  /// when there's no family code — never falls back to demo data.
  Future<void> refresh() async {
    if (_ownerCode.isEmpty) return;
    await loadFamilyLedger(ownerCode: _ownerCode, ownerType: _ownerType);
  }

  // No client-side pagination; kept as a guarded no-op.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMoreData) return;
  }

  /// Applies a new date range and refetches the ledger (the endpoint has no
  /// date filter, so this is effectively a refresh).
  Future<void> applyDateRange(DateTime? start, DateTime? end) async {
    emit(state.copyWith(startDate: () => start, endDate: () => end));
    await refresh();
  }

}
