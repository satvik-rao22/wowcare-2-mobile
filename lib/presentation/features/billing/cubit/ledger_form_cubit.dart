import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/general_ledger/models/ledger_account_model.dart';

part 'ledger_form_state.dart';

/// Result of a ledger form submission, returned to the view so it can show the
/// right snackbar and pop with the created/updated ledger.
enum LedgerFormStatus { invalid, success, error }

class LedgerFormResult {
  const LedgerFormResult(this.status, this.ledger);

  final LedgerFormStatus status;
  final LedgerAccountModel? ledger;
}

/// Shared form state for the create + edit ledger screens. The view keeps its
/// title/description controllers and passes their text into [submit]; the cubit
/// owns the type selection, validation flags, and the (faked) save.
class LedgerFormCubit extends Cubit<LedgerFormState> {
  LedgerFormCubit({String? initialType})
      : super(LedgerFormState.initial(initialType));

  void setType(String? value) {
    emit(state.copyWith(selectedType: () => value, typeError: false));
  }

  /// Validates and "saves" the ledger. When [original] is null a new ledger is
  /// created; otherwise [original] is copied with the edits.
  Future<LedgerFormResult> submit({
    LedgerAccountModel? original,
    required String title,
    required String description,
  }) async {
    final titleError = title.trim().isEmpty;
    final typeError = state.selectedType == null;
    emit(state.copyWith(titleError: titleError, typeError: typeError));
    if (titleError || typeError) {
      return const LedgerFormResult(LedgerFormStatus.invalid, null);
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final desc =
          description.trim().isEmpty ? title.trim() : description.trim();
      final LedgerAccountModel ledger;
      if (original == null) {
        ledger = LedgerAccountModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: title.trim(),
          type: state.selectedType!,
          description: desc,
          openBalance: 0,
          invoiced: 0,
          received: 0,
          isSubsidy: state.selectedType == '(Legacy) Subsidy/Agency',
          status: 'A',
        );
      } else {
        ledger = original.copyWith(
          name: title.trim(),
          type: state.selectedType,
          description: desc,
        );
      }
      if (isClosed) return const LedgerFormResult(LedgerFormStatus.error, null);
      return LedgerFormResult(LedgerFormStatus.success, ledger);
    } catch (_) {
      return const LedgerFormResult(LedgerFormStatus.error, null);
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }
}
