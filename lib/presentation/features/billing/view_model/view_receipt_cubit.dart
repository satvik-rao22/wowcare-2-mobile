import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_actions.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_pdf_builder.dart';
import 'package:wowcare/presentation/features/billing/view_model/billing_school_header_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';

part 'view_receipt_state.dart';

/// Owns the "View Receipt" screen's download state — the rest of that
/// screen's content (invoice number, due date, discount line) is UI-only mock
/// data pending real wiring (see ViewReceiptScreen), but the downloaded PDF
/// mirrors the real transaction it was opened with.
class ViewReceiptCubit extends Cubit<ViewReceiptState> {
  ViewReceiptCubit({
    required BillingSchoolHeaderCubit Function() createSchoolHeaderCubit,
  })  : _createSchoolHeaderCubit = createSchoolHeaderCubit,
        super(const ViewReceiptState());

  final BillingSchoolHeaderCubit Function() _createSchoolHeaderCubit;

  /// Builds the receipt PDF on-device (no backend PDF endpoint exists),
  /// matching the same school header [BillingSchoolHeader] renders, then
  /// hands it to the OS share sheet so the user can actually save it
  /// somewhere persistent (Files/Downloads/Drive) — a fresh PDF has no
  /// remote URL to open and isn't media the gallery can hold.
  /// Returns an error message on failure, or null on success.
  Future<String?> downloadReceipt(TransactionItem transaction) async {
    final headerCubit = _createSchoolHeaderCubit();
    try {
      await headerCubit.load();
      final header = headerCubit.state;

      final bytes = await BillingPdfBuilder.buildReceiptPdf(
        transaction: transaction,
        schoolName: header.name,
        schoolTagline: header.tagline,
        schoolAddress: header.address,
      );

      final id = (transaction.transactionId ?? transaction.id.toString()).trim();
      final fileName = 'receipt-$id.pdf';
      final savedPath = await FileUtils.saveToDocuments(bytes, fileName);

      if (isClosed) return null;
      if (savedPath == null) return 'Failed to save receipt PDF.';

      await FileActions.share(
        savedPath,
        mimeType: 'application/pdf',
        fileName: fileName,
      );
      return null;
    } catch (e) {
      AppLogger.e('[ViewReceiptCubit] PDF generation failed: $e');
      return 'Failed to generate receipt PDF.';
    } finally {
      unawaited(headerCubit.close());
    }
  }
}
