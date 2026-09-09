import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';

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
  })  : _getStudentProfile = getStudentProfile,
        _getInvoiceByCode = getInvoiceByCode,
        super(const ViewInvoiceState());

  final GetStudentProfileUseCase _getStudentProfile;
  final GetInvoiceByCodeUseCase _getInvoiceByCode;

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
}
