part of 'kiosk_logout_cubit.dart';

abstract class KioskLogoutState extends Equatable {
  const KioskLogoutState();

  @override
  List<Object?> get props => [];
}

class KioskLogoutInitial extends KioskLogoutState {
  const KioskLogoutInitial();
}

class KioskLogoutLoading extends KioskLogoutState {
  const KioskLogoutLoading();
}

class KioskLogoutSuccess extends KioskLogoutState {
  const KioskLogoutSuccess();
}

class KioskLogoutError extends KioskLogoutState {
  const KioskLogoutError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
