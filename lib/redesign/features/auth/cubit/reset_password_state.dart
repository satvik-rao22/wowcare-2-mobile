part of 'reset_password_cubit.dart';

enum ResetPasswordStatus { editing, saving, saved, failed }

@immutable
class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.status = ResetPasswordStatus.editing,
    this.password = '',
    this.confirmation = '',
  });

  /// The shortest password the app accepts.
  static const int minLength = 8;

  static final RegExp _number = RegExp(r'\d');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');

  final ResetPasswordStatus status;
  final String password;
  final String confirmation;

  bool get isSaving => status == ResetPasswordStatus.saving;
  bool get isSaved => status == ResetPasswordStatus.saved;
  bool get isFailed => status == ResetPasswordStatus.failed;

  bool get isLongEnough => password.length >= minLength;
  bool get hasNumberAndSymbol =>
      _number.hasMatch(password) && _symbol.hasMatch(password);
  bool get isMatched => password.isNotEmpty && password == confirmation;

  List<bool> get rules => <bool>[
    isLongEnough,
    hasNumberAndSymbol,
    isMatched,
  ];

  bool get isValid => rules.every((met) => met);

  /// How full the strength bar is: one third per rule met.
  double get strength => rules.where((met) => met).length / rules.length;

  ResetPasswordState copyWith({
    ResetPasswordStatus? status,
    String? password,
    String? confirmation,
  }) => ResetPasswordState(
    status: status ?? this.status,
    password: password ?? this.password,
    confirmation: confirmation ?? this.confirmation,
  );

  @override
  List<Object?> get props => [status, password, confirmation];
}
