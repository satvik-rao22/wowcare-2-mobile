import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

import 'dashboard_coordinator_state.dart';

class StaffDashboardCoordinatorCubit extends Cubit<DashboardState> {
  final StaffDashboardCubit dashboardCubit;
  final MyDayCubit myDayCubit;
  final RatioMonitoringCubit ratioMonitoringCubit;
  final MyAttendanceCubit myAttendanceCubit;
  final MyShiftsCubit myShiftsCubit;
  final GeofenceCubit geofenceCubit;

  final List<StreamSubscription> _subscriptions = [];

  StaffDashboardCoordinatorCubit({
    required this.dashboardCubit,
    required this.myDayCubit,
    required this.ratioMonitoringCubit,
    required this.myAttendanceCubit,
    required this.myShiftsCubit,
    required this.geofenceCubit,
  }) : super(const DashboardState(status: DashboardStatus.initial)) {
    // Subscribe to child cubits to aggregate their states reactively
    _subscriptions.add(myDayCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(
      ratioMonitoringCubit.stream.listen((_) => _updateState()),
    );
    _subscriptions.add(myAttendanceCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(myShiftsCubit.stream.listen((_) => _updateState()));

    // Trigger initial load
    unawaited(initialize());
  }

  Future<void> initialize() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    await _initGeofence();

    final schoolCode = await _resolveSchoolCode();

    await Future.wait([
      myDayCubit.load(isSilent: true),
      myAttendanceCubit.load(),
      myShiftsCubit.load(forceRefresh: false),
      if (schoolCode != null)
        ratioMonitoringCubit.loadRatioMonitoring(
          schoolCode: schoolCode,
          isSilent: true,
        ),
    ]);

    _updateState();
  }

  Future<void> _initGeofence() async {
    final schoolCode = await _resolveSchoolCode();
    if (schoolCode != null && schoolCode.isNotEmpty) {
      await geofenceCubit.initForSchool(schoolCode: schoolCode);
    }
  }

  Future<String?> _resolveSchoolCode() async {
    final storage = serviceLocator<StorageService>();
    final code = await storage.getString(StorageKeys.schoolCode);
    return (code != null && code.isNotEmpty) ? code : null;
  }

  void _updateState() {
    if (isClosed) return;

    // Check loading states
    final myDayLoading = myDayCubit.state.isLoading;
    final ratioLoading = ratioMonitoringCubit.state.isLoading;
    final attendanceLoading = myAttendanceCubit.state.isLoading;
    final shiftsLoading = myShiftsCubit.state.isLoading;

    // Check error states
    final myDayError = myDayCubit.state.status == MyDayStatus.error;
    final ratioError = ratioMonitoringCubit.state.isError;
    final attendanceError = myAttendanceCubit.state.isError;
    final shiftsError = myShiftsCubit.state.isError;

    // Check loaded/ready states
    final myDayLoaded = myDayCubit.state.isLoaded;
    final ratioLoaded = ratioMonitoringCubit.state.isLoaded;
    final attendanceLoaded = myAttendanceCubit.state.isLoaded;
    final shiftsLoaded = myShiftsCubit.state.isLoaded;

    final isAnyLoading =
        myDayLoading || ratioLoading || attendanceLoading || shiftsLoading;
    final isAnyError =
        myDayError || ratioError || attendanceError || shiftsError;
    final isAllLoaded =
        myDayLoaded && ratioLoaded && attendanceLoaded && shiftsLoaded;
    final isAllError =
        myDayError && ratioError && attendanceError && shiftsError;

    if (isAnyLoading) {
      if (state.status == DashboardStatus.ready ||
          state.status == DashboardStatus.partialError) {
        emit(state.copyWith(status: DashboardStatus.refreshing));
      } else {
        emit(state.copyWith(status: DashboardStatus.loading));
      }
    } else if (isAllError) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: 'Unable to load dashboard data. Please try again.',
        ),
      );
    } else if (isAnyError) {
      emit(state.copyWith(status: DashboardStatus.partialError));
    } else if (isAllLoaded) {
      // Clear any stale error from a previous failed load cycle.
      emit(
        state.copyWith(status: DashboardStatus.ready, clearErrorMessage: true),
      );
    } else {
      emit(state.copyWith(status: DashboardStatus.initial));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(status: DashboardStatus.refreshing));

    // Re-validate GPS position immediately on refresh
    unawaited(geofenceCubit.refreshSettings());

    await Future.wait([
      myDayCubit.refresh(),
      myAttendanceCubit.refresh(),
      myShiftsCubit.load(forceRefresh: true),
    ]);

    final schoolCode = await _resolveSchoolCode();
    if (schoolCode != null) {
      await ratioMonitoringCubit.loadRatioMonitoring(
        schoolCode: schoolCode,
        forceRefresh: true,
      );
    }
    // No explicit _updateState() here — child cubit stream subscriptions
    // trigger _updateState() reactively as each cubit completes, so a
    // manual call after Future.wait() would fire a redundant emission.
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Close all screen-scoped cubits
    dashboardCubit.close();
    myDayCubit.close();
    ratioMonitoringCubit.close();
    myAttendanceCubit.close();
    myShiftsCubit.close();

    // GeofenceCubit is a singleton — do NOT close it
    return super.close();
  }
}
