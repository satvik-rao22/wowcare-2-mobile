import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auto_pay_methods_state.dart';

/// Owns the auto-pay payment-methods screen state (toggle, method selection,
/// change tracking, save flag). Saved card/echeck are demo data today; swap
/// [loadSavedMethods] for a repository call when billing is wired to a backend.
class AutoPayMethodsCubit extends Cubit<AutoPayMethodsState> {
  AutoPayMethodsCubit() : super(const AutoPayMethodsState.initial());

  void toggleAutoPay(bool value) {
    final wasEnabled = state.isAutoPayEnabled;
    String? selected = state.selectedMethod;
    // Clear the selection when (re)enabling from a disabled snapshot, or when
    // turning auto-pay off — mirrors the original screen behavior.
    if (value && !state.initialAutoPayEnabled) selected = null;
    if (!value && wasEnabled) selected = null;
    emit(state.copyWith(isAutoPayEnabled: value, selectedMethod: () => selected));
  }

  void selectMethod(String value) {
    emit(state.copyWith(selectedMethod: () => value));
  }

  /// Simulates persisting the auto-pay settings. Returns when the (currently
  /// faked) save completes so the view can confirm + pop.
  Future<void> save() async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;
    emit(state.copyWith(isSaving: false));
  }
}

class SavedCardData {
  const SavedCardData({
    required this.nameOnCard,
    required this.last4,
    required this.expireMonth,
    required this.expireYear,
    required this.cardType,
  });

  final String nameOnCard;
  final String last4;
  final int expireMonth;
  final int expireYear;
  final String cardType;
}

class SavedEcheckData {
  const SavedEcheckData({
    required this.accountHolder,
    required this.routingNumber,
    required this.last4,
    required this.accountType,
  });

  final String accountHolder;
  final String routingNumber;
  final String last4;
  final String accountType;

  String get accountTypeLabel {
    final lower = accountType.toLowerCase();
    if (lower == 'c' || lower.contains('checking')) return 'Checking';
    if (lower == 's' || lower.contains('saving')) return 'Savings';
    return accountType;
  }
}
