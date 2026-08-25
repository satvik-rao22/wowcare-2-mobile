part of 'auto_pay_new_method_cubit.dart';

class AutoPayNewMethodState extends Equatable {
  const AutoPayNewMethodState({
    required this.paymentMethod,
    required this.expMonth,
    required this.expYear,
    required this.accountType,
    required this.isSaving,
    required this.fieldErrors,
  });

  const AutoPayNewMethodState.initial()
    : paymentMethod = '',
      expMonth = '',
      expYear = '',
      accountType = '',
      isSaving = false,
      fieldErrors = const <String, String>{};

  final String paymentMethod;
  final String expMonth;
  final String expYear;
  final String accountType;
  final bool isSaving;
  final Map<String, String> fieldErrors;

  bool get isCard =>
      paymentMethod.isNotEmpty && paymentMethod.toLowerCase() != 'echeck';
  bool get showCardFields => isCard;
  bool get showEcheckFields =>
      paymentMethod.isNotEmpty && paymentMethod.toLowerCase() == 'echeck';
  bool get showInfoBlock => paymentMethod.isNotEmpty;

  AutoPayNewMethodState copyWith({
    String? paymentMethod,
    String? expMonth,
    String? expYear,
    String? accountType,
    bool? isSaving,
    Map<String, String>? fieldErrors,
  }) {
    return AutoPayNewMethodState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      accountType: accountType ?? this.accountType,
      isSaving: isSaving ?? this.isSaving,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    paymentMethod,
    expMonth,
    expYear,
    accountType,
    isSaving,
    fieldErrors,
  ];
}
