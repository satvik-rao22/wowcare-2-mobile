import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/billing/usecases/issue_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/resend_invoice_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';

part 'send_invoice_state.dart';

/// Outcome of a [SendInvoiceCubit.send] call, so the view can react (snackbar,
/// pop) without reaching into the data layer.
enum SendInvoiceOutcome { missingCode, success, failure }

/// Owns the "Send Invoice" screen's data-layer work so the view stays
/// display-only: the best-effort classroom lookup and the issue/resend
/// mutation. A draft is issued (`POST /issue`); an already-issued invoice is
/// re-sent (`PATCH /resend`).
class SendInvoiceCubit extends Cubit<SendInvoiceState> {
  SendInvoiceCubit({
    required GetStudentProfileUseCase getStudentProfile,
    required IssueInvoiceUseCase issueInvoice,
    required ResendInvoiceUseCase resendInvoice,
  })  : _getStudentProfile = getStudentProfile,
        _issueInvoice = issueInvoice,
        _resendInvoice = resendInvoice,
        super(const SendInvoiceState());

  final GetStudentProfileUseCase _getStudentProfile;
  final IssueInvoiceUseCase _issueInvoice;
  final ResendInvoiceUseCase _resendInvoice;

  /// Single-flight guard so a double-tap on Send can't issue/resend twice.
  Future<SendInvoiceOutcome>? _inFlight;

  Future<void> loadRoomName(String? studentCode) async {
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

  /// Issues (draft) or re-sends the invoice. Single-flighted: concurrent taps
  /// share the one in-flight future rather than firing a second request.
  Future<SendInvoiceOutcome> send({
    required String? invoiceCode,
    required bool isDraft,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _sendImpl(invoiceCode: invoiceCode, isDraft: isDraft);
    _inFlight = future;
    future.whenComplete(() {
      _inFlight = null;
    }).ignore();
    return future;
  }

  Future<SendInvoiceOutcome> _sendImpl({
    required String? invoiceCode,
    required bool isDraft,
  }) async {
    final code = invoiceCode?.trim();
    if (code == null || code.isEmpty) return SendInvoiceOutcome.missingCode;

    emit(state.copyWith(isSending: true, errorMessage: null));
    try {
      if (isDraft) {
        await _issueInvoice(code);
      } else {
        await _resendInvoice(code);
      }
      if (isClosed) return SendInvoiceOutcome.success;
      emit(state.copyWith(isSending: false));
      return SendInvoiceOutcome.success;
    } catch (e) {
      if (isClosed) return SendInvoiceOutcome.failure;
      emit(state.copyWith(
        isSending: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return SendInvoiceOutcome.failure;
    }
  }
}
