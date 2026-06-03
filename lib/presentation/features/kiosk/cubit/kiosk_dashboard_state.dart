part of 'kiosk_dashboard_cubit.dart';

abstract class KioskDashboardState extends Equatable {
  const KioskDashboardState();

  @override
  List<Object?> get props => [];
}

class KioskDashboardInitial extends KioskDashboardState {
  const KioskDashboardInitial();
}

class KioskDashboardLoading extends KioskDashboardState {
  const KioskDashboardLoading();
}

class KioskDashboardQrLoaded extends KioskDashboardState {
  const KioskDashboardQrLoaded({
    required this.qrCode,
    required this.schoolName,
  });

  final KioskQrEntity qrCode;
  final String schoolName;

  @override
  List<Object?> get props => [qrCode, schoolName];
}

class KioskDashboardError extends KioskDashboardState {
  const KioskDashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
