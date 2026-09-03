part of 'forgot_password_cubit.dart';

enum ForgotPasswordStatus {
  editing,

  /// The address does not look like one. The only check 1d makes itself.
  invalid,
  sending,

  /// 1e.
  sent,

  /// The link could not be sent, which is the only failure 1d draws.
  failed,
}

@immutable
class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.editing,
    this.email = '',
    this.secondsLeft = 0,
  });

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final ForgotPasswordStatus status;
  final String email;

  /// What is left on 1e's resend clock. Zero means the key is live.
  final int secondsLeft;

  bool get isSending => status == ForgotPasswordStatus.sending;
  bool get isSent => status == ForgotPasswordStatus.sent;
  bool get isEmailValid => _email.hasMatch(email.trim());

  /// The address as 1e prints it: the first letter, then bullets, then the
  /// domain. Nobody standing behind the reviewer learns the whole address.
  String get maskedEmail {
    final parts = email.trim().split('@');
    if (parts.length != 2 || parts.first.isEmpty) return email.trim();
    return '${parts.first[0]}••••@${parts.last}';
  }

  /// "0:45", counting down.
  String get resendClock {
    final minutes = secondsLeft ~/ 60;
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    int? secondsLeft,
  }) => ForgotPasswordState(
    status: status ?? this.status,
    email: email ?? this.email,
    secondsLeft: secondsLeft ?? this.secondsLeft,
  );

  @override
  List<Object?> get props => [status, email, secondsLeft];
}
