import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_actions.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_pdf_builder.dart';
import 'package:wowcare/presentation/features/billing/view_model/billing_school_header_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';

part 'view_invoice_state.dart';

/// Owns the read-only "View Invoice" screen state so the view stays display-only.
///
/// Both lookups are best-effort and independent — the screen renders from the
/// transaction summary it was opened with and only enriches it:
///  - the student's current classroom (invoices carry no room field), and
///  - the full invoice by code (the transaction row has no invoice
///    number/due date/service period; the web modal shows all three).
/// A failed lookup simply leaves that slice null and the view falls back to the
/// summary it already has.
class ViewInvoiceCubit extends Cubit<ViewInvoiceState> {
  ViewInvoiceCubit({
    required GetStudentProfileUseCase getStudentProfile,
    required GetInvoiceByCodeUseCase getInvoiceByCode,
    required BillingSchoolHeaderCubit Function() createSchoolHeaderCubit,
  })  : _getStudentProfile = getStudentProfile,
        _getInvoiceByCode = getInvoiceByCode,
        _createSchoolHeaderCubit = createSchoolHeaderCubit,
        super(const ViewInvoiceState());

  final GetStudentProfileUseCase _getStudentProfile;
  final GetInvoiceByCodeUseCase _getInvoiceByCode;
  final BillingSchoolHeaderCubit Function() _createSchoolHeaderCubit;

  /// Fires both enrichment lookups concurrently; each emits on its own success.
  Future<void> load({String? studentCode, String? invoiceCode}) async {
    await Future.wait([
      _loadRoomName(studentCode),
      _loadInvoiceDetail(invoiceCode),
    ]);
  }

  Future<void> _loadRoomName(String? studentCode) async {
    final code = studentCode?.trim();
    if (code == null || code.isEmpty) return;
    try {
      final profile = await _getStudentProfile(code: code);
      if (isClosed) return;
      emit(state.copyWith(roomName: profile.classroomName));
    } catch (_) {
      // No room fallback — the row is simply omitted.
    }
  }

  Future<void> _loadInvoiceDetail(String? invoiceCode) async {
    final code = invoiceCode?.trim();
    if (code == null || code.isEmpty) return;
    try {
      final detail = await _getInvoiceByCode(code);
      if (isClosed) return;
      emit(state.copyWith(invoiceDetail: detail));
    } catch (e) {
      // Fall back to whatever summary fields the transaction row carried.
      CoreUtils.logApiError(
          '[ViewInvoiceCubit] getInvoiceByCode($code) failed: $e');
    }
  }

  /// Builds the invoice PDF on-device (no backend PDF endpoint exists) from
  /// whatever this screen already has loaded, matching the same school
  /// header (avatar/name/tagline/address) [BillingSchoolHeader] renders, then
  /// hands it to the OS share sheet — the same "let the user actually save
  /// it somewhere they can find it" outcome the app's other document/media
  /// downloads reach via the gallery or an external open, neither of which
  /// applies to a freshly-generated PDF with no remote URL.
  /// Returns an error message on failure, or null on success.
  Future<String?> downloadInvoice(TransactionItem transaction) async {
    final headerCubit = _createSchoolHeaderCubit();
    try {
      await headerCubit.load();
      final header = headerCubit.state;

      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: transaction,
        schoolName: header.name,
        schoolTagline: header.tagline,
        schoolAddress: header.address,
        roomName: state.roomName,
        detail: state.invoiceDetail,
      );

      final code = (transaction.invoiceCode ?? transaction.id.toString()).trim();
      final fileName = 'invoice-$code.pdf';
      final savedPath = await FileUtils.saveToDocuments(bytes, fileName);

      if (isClosed) return null;
      if (savedPath == null) return 'Failed to save invoice PDF.';

      await FileActions.share(
        savedPath,
        mimeType: 'application/pdf',
        fileName: fileName,
      );
      return null;
    } catch (e) {
      AppLogger.e('[ViewInvoiceCubit] PDF generation failed: $e');
      return 'Failed to generate invoice PDF.';
    } finally {
      unawaited(headerCubit.close());
    }
  }
}
