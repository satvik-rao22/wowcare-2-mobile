import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_attendance_cubit_v2.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/notifications/cubit/push_notification_cubit.dart';

/// [MultiBlocProvider] providers nested inside the sizer/theme setup —
/// cubits owned by the app's authenticated + kiosk shell.
List<SingleChildWidget> appBlocProviders() => [
  BlocProvider<AuthCubit>(
    create: (_) => serviceLocator<AuthCubit>()..initialize(),
  ),
  BlocProvider<PushNotificationCubit>(
    create: (_) => serviceLocator<PushNotificationCubit>(),
  ),
  BlocProvider<GeofenceCubit>(create: (_) => serviceLocator<GeofenceCubit>()),
  // Kiosk cubits provided at app root so all routes have access
  // This fixes ProviderNotFoundException in GoRouter nested routes
  BlocProvider<KioskDashboardCubit>(
    create: (_) => serviceLocator<KioskDashboardCubit>(),
  ),
  BlocProvider<KioskAttendanceCubitV2>(
    create: (_) => serviceLocator<KioskAttendanceCubitV2>(),
  ),
];
