import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'auto_pay_new_method_state.dart';

/// Owns the new-payment-method form's non-text state: the payment-method /
/// expiry / account-type selections, validation errors, and the save flag.
///
/// The view keeps its [TextEditingController]s (card/cvv/account/routing) and
/// passes their values into [validate] / [save]; this cubit owns the rules.
class AutoPayNewMethodCubit extends Cubit<AutoPayNewMethodState> {
  AutoPayNewMethodCubit() : super(const AutoPayNewMethodState.initial());

  void setPaymentMethod(String? label) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('paymentMethod');
    emit(
      state.copyWith(
        paymentMethod: _mapMethodLabelToCode(label),
        fieldErrors: errors,
      ),
    );
  }

  void setExpMonth(String? value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('expMonth');
    emit(state.copyWith(expMonth: value ?? '', fieldErrors: errors));
  }

  void setExpYear(String? value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('expYear');
    emit(state.copyWith(expYear: value ?? '', fieldErrors: errors));
  }

  void setAccountType(String? label) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('accountType');
    emit(
      state.copyWith(
        accountType: _mapAccountTypeLabelToCode(label),
        fieldErrors: errors,
      ),
    );
  }

  void clearFieldError(String key) {
    if (!state.fieldErrors.containsKey(key)) return;
    final errors = Map<String, String>.from(state.fieldErrors)..remove(key);
    emit(state.copyWith(fieldErrors: errors));
  }

  /// Validates the full form. Text values live in the view's controllers and
  /// are passed in. Emits the resulting [fieldErrors] and returns whether the
  /// form is valid.
  bool validate({
    required String cardNumber,
    required String cvv,
    required String accountNumber,
    required String routingNumber,
  }) {
    final errors = <String, String>{};

    if (state.paymentMethod.isEmpty) {
      errors['paymentMethod'] = 'Please select a payment method';
    }

    if (state.isCard) {
      final card = cardNumber.trim();
      final code = cvv.trim();
      if (card.isEmpty) {
        errors['cardNumber'] = 'Card number is required';
      } else if (card.length < 13 || card.length > 19) {
        errors['cardNumber'] = 'Card number must be 13-19 digits';
      }
      if (state.expMonth.isEmpty) {
        errors['expMonth'] = 'Expiration month is required';
      }
      if (state.expYear.isEmpty) {
        errors['expYear'] = 'Expiration year is required';
      }
      if (code.isEmpty) {
        errors['cvv'] = 'CVV is required';
      } else if (code.length < 3 || code.length > 4) {
        errors['cvv'] = 'CVV must be 3-4 digits';
      }
    } else if (state.paymentMethod == 'echeck') {
      final account = accountNumber.trim();
      final routing = routingNumber.trim();
      if (account.isEmpty) {
        errors['accountNumber'] = 'Account number is required';
      } else if (account.length < 4 || account.length > 17) {
        errors['accountNumber'] = 'Account number must be 4-17 digits';
      }
      if (routing.isEmpty) {
        errors['routingNumber'] = 'Routing number is required';
      } else if (routing.length != 9) {
        errors['routingNumber'] = 'Routing number must be 9 digits';
      }
      if (state.accountType.isEmpty) {
        errors['accountType'] = 'Account type is required';
      }
    }

    emit(state.copyWith(fieldErrors: errors));
    return errors.isEmpty;
  }

  /// Simulates creating the secure token. Returns when the (currently faked)
  /// call completes so the view can confirm.
  Future<void> save() async {
    if (state.isSaving) return;
    emit(state.copyWith(isSaving: true));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (isClosed) return;
    emit(state.copyWith(isSaving: false));
  }

  String _mapMethodLabelToCode(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'visa':
        return 'visa';
      case 'mastercard':
        return 'mast';
      case 'discover':
        return 'disc';
      case 'ach':
        return 'echeck';
      default:
        return '';
    }
  }

  String _mapAccountTypeLabelToCode(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'checking':
        return 'checking';
      case 'savings':
        return 'savings';
      default:
        return '';
    }
  }
}
