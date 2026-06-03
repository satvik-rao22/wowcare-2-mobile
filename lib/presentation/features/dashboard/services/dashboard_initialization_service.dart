import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_overall_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

/// Centralizes all dashboard cubit initialization and setup.
/// Removes complex initialization logic from dashboard widgets.
class DashboardInitializationService {
  /// Initialize cubits for the parent dashboard.
  static List<BlocProvider> initializeParentDashboardProviders() {
    return [
      BlocProvider<DashboardOverallCubit>(
        create: (_) => serviceLocator<DashboardOverallCubit>(),
      ),
      BlocProvider<ParentDashboardCubit>(
        create: (_) => serviceLocator<ParentDashboardCubit>(),
      ),
      BlocProvider<MyChildsDayCubit>(
        create: (_) => serviceLocator<MyChildsDayCubit>(),
      ),
      BlocProvider<StudentAttendanceProfileCubit>(
        create: (_) => serviceLocator<StudentAttendanceProfileCubit>(),
      ),
      BlocProvider<CommunicationCubit>(
        create: (_) => serviceLocator<CommunicationCubit>(),
      ),
      BlocProvider<StudentNewslettersCubit>(
        create: (_) => serviceLocator<StudentNewslettersCubit>(),
      ),
      BlocProvider<GeofenceCubit>(
        create: (_) => serviceLocator<GeofenceCubit>(),
      ),
    ];
  }

  /// Initialize cubits for the staff dashboard.
  static List<BlocProvider> initializeStaffDashboardProviders() {
    return [
      BlocProvider<DashboardOverallCubit>(
        create: (_) => serviceLocator<DashboardOverallCubit>(),
      ),
      BlocProvider<StaffDashboardCubit>(
        create: (_) => serviceLocator<StaffDashboardCubit>(),
      ),
      BlocProvider<MyDayCubit>(
        create: (_) => serviceLocator<MyDayCubit>(),
      ),
      BlocProvider<RatioMonitoringCubit>(
        create: (_) => serviceLocator<RatioMonitoringCubit>(),
      ),
      BlocProvider<MyAttendanceCubit>(
        create: (_) => serviceLocator<MyAttendanceCubit>(),
      ),
      BlocProvider<MyShiftsCubit>(
        create: (_) => serviceLocator<MyShiftsCubit>(),
      ),
      BlocProvider<GeofenceCubit>(
        create: (_) => serviceLocator<GeofenceCubit>(),
      ),
    ];
  }

  /// Initialize cubits for the admin dashboard.
  static List<BlocProvider> initializeAdminDashboardProviders() {
    return [
      BlocProvider<DashboardOverallCubit>(
        create: (_) => serviceLocator<DashboardOverallCubit>(),
      ),
      BlocProvider<AdminDashboardCubit>(
        create: (_) => serviceLocator<AdminDashboardCubit>(),
      ),
      BlocProvider<SchoolStatusCubit>(
        create: (_) => serviceLocator<SchoolStatusCubit>(),
      ),
      BlocProvider<RatioMonitoringCubit>(
        create: (_) => serviceLocator<RatioMonitoringCubit>(),
      ),
      BlocProvider<IndividualMovementsCubit>(
        create: (_) => serviceLocator<IndividualMovementsCubit>(),
      ),
      BlocProvider<FutureAvailabilityCubit>(
        create: (_) => serviceLocator<FutureAvailabilityCubit>(),
      ),
      BlocProvider<ClassroomShiftsCubit>(
        create: (_) => serviceLocator<ClassroomShiftsCubit>(),
      ),
      BlocProvider<DashboardAttentionCubit>(
        create: (_) => serviceLocator<DashboardAttentionCubit>(),
      ),
      BlocProvider<MyDayCubit>(
        create: (_) => serviceLocator<MyDayCubit>(),
      ),
      BlocProvider<GeofenceCubit>(
        create: (_) => serviceLocator<GeofenceCubit>(),
      ),
    ];
  }

  /// Load all initial data for parent dashboard.
  static Future<void> loadParentDashboardData(BuildContext context) async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);

    if (!context.mounted) return;
    await _initGeofence(context, schoolCode);
  }

  /// Load all initial data for staff dashboard.
  static Future<void> loadStaffDashboardData(BuildContext context) async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);

    if (!context.mounted) return;

    final geofenceFuture = _initGeofence(context, schoolCode);
    final myDayFuture =
        context.read<MyDayCubit>().load(isSilent: true);

    await Future.wait([geofenceFuture, myDayFuture]);
  }

  /// Load all initial data for admin dashboard.
  static Future<void> loadAdminDashboardData(BuildContext context) async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);

    if (!context.mounted) return;

    final futures = <Future<void>>[
      context.read<AdminDashboardCubit>().loadUserName(),
      context.read<ClassroomShiftsCubit>().load(DateTime.now()),
      context.read<DashboardAttentionCubit>().load(),
      context.read<MyDayCubit>().load(),
      _initGeofence(context, schoolCode),
      _initRatioMonitoring(context, schoolCode),
      _initMovements(context),
      _initAvailability(context),
    ];

    await Future.wait(futures);
  }

  static Future<void> _initGeofence(
    BuildContext context,
    String? schoolCode,
  ) async {
    if (schoolCode == null || schoolCode.isEmpty) return;
    if (!context.mounted) return;
    await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);
  }

  static Future<void> _initRatioMonitoring(
    BuildContext context,
    String? schoolCode,
  ) async {
    if (schoolCode == null || schoolCode.isEmpty) return;
    if (!context.mounted) return;
    await context.read<RatioMonitoringCubit>().loadRatioMonitoring(
      schoolCode: schoolCode,
      isSilent: true,
    );
  }

  static Future<void> _initMovements(BuildContext context) async {
    if (!context.mounted) return;
    await context.read<IndividualMovementsCubit>().loadInitial();
  }

  static Future<void> _initAvailability(BuildContext context) async {
    if (!context.mounted) return;
    await context.read<FutureAvailabilityCubit>().load(
      date: DateTime.now(),
      isTwoShifts: true,
    );
  }
}
