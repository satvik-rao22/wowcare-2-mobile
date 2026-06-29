import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

import 'dashboard_coordinator_state.dart';

extension _IndividualMovementsStateX on IndividualMovementsState {
  bool get isLoaded => board != null;
  bool get isError => errorMessage != null;
}

extension _FutureAvailabilityStateX on FutureAvailabilityState {
  bool get isLoaded => grid != null;
  bool get isError => errorMessage != null;
}

extension _DashboardAttentionStateX on DashboardAttentionState {
  bool get isError =>
      status == DashboardAttentionStatus.error ||
      status == DashboardAttentionStatus.partialFailure;
}

class AdminDashboardCoordinatorCubit extends Cubit<DashboardState> {
  final AdminDashboardCubit dashboardCubit;
  final SchoolStatusCubit schoolStatusCubit;
  final RatioMonitoringCubit ratioMonitoringCubit;
  final IndividualMovementsCubit movementsCubit;
  final FutureAvailabilityCubit availabilityCubit;
  final ClassroomShiftsCubit classroomShiftsCubit;
  final DashboardAttentionCubit attentionCubit;
  final MyDayCubit myDayCubit;
  final GeofenceCubit geofenceCubit;

  final List<StreamSubscription> _subscriptions = [];

  AdminDashboardCoordinatorCubit({
    required this.dashboardCubit,
    required this.schoolStatusCubit,
    required this.ratioMonitoringCubit,
    required this.movementsCubit,
    required this.availabilityCubit,
    required this.classroomShiftsCubit,
    required this.attentionCubit,
    required this.myDayCubit,
    required this.geofenceCubit,
  }) : super(const DashboardState(status: DashboardStatus.initial)) {
    // Subscribe to child cubits to aggregate their states reactively
    _subscriptions.add(schoolStatusCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(
      ratioMonitoringCubit.stream.listen((_) => _updateState()),
    );
    _subscriptions.add(movementsCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(availabilityCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(
      classroomShiftsCubit.stream.listen((_) => _updateState()),
    );
    _subscriptions.add(attentionCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(myDayCubit.stream.listen((_) => _updateState()));

    // Trigger initial load
    unawaited(initialize());
  }

  Future<void> initialize() async {
    emit(state.copyWith(status: DashboardStatus.loading));

    await Future.wait([
      dashboardCubit.loadUserName(),
      classroomShiftsCubit.load(DateTime.now()),
      attentionCubit.load(),
      myDayCubit.load(),
      _initSchoolDependentCubits(),
    ]);

    _updateState();
  }

  Future<void> _initSchoolDependentCubits() async {
    final schoolCode = await _resolveSchoolCode();
    await Future.wait([
      movementsCubit.loadInitial(),
      availabilityCubit.load(date: DateTime.now(), isTwoShifts: true),
      if (schoolCode != null && schoolCode.isNotEmpty) ...[
        schoolStatusCubit.loadSchoolStatus(
          schoolCode: schoolCode,
          isSilent: true,
        ),
        ratioMonitoringCubit.loadRatioMonitoring(
          schoolCode: schoolCode,
          isSilent: true,
        ),
        geofenceCubit.initForSchool(schoolCode: schoolCode),
      ],
    ]);
  }

  Future<String?> _resolveSchoolCode() async {
    final storage = serviceLocator<StorageService>();
    final code = await storage.getString(StorageKeys.schoolCode);
    return (code != null && code.isNotEmpty) ? code : null;
  }

  void _updateState() {
    if (isClosed) return;

    // Check loading states
    final statusLoading = schoolStatusCubit.state.isLoading;
    final ratioLoading = ratioMonitoringCubit.state.isLoading;
    final movementsLoading = movementsCubit.state.isLoading;
    final availabilityLoading = availabilityCubit.state.isLoading;
    final shiftsLoading = classroomShiftsCubit.state.isLoading;
    final attentionLoading = attentionCubit.state.isLoading;
    final myDayLoading = myDayCubit.state.isLoading;

    // Check error states
    final statusError = schoolStatusCubit.state.isError;
    final ratioError = ratioMonitoringCubit.state.isError;
    final movementsError = movementsCubit.state.isError;
    final availabilityError = availabilityCubit.state.isError;
    final shiftsError = classroomShiftsCubit.state.isError;
    final attentionError = attentionCubit.state.isError;
    final myDayError = myDayCubit.state.status == MyDayStatus.error;

    // Check loaded/ready states
    final statusLoaded = schoolStatusCubit.state.isLoaded;
    final ratioLoaded = ratioMonitoringCubit.state.isLoaded;
    final movementsLoaded = movementsCubit.state.isLoaded;
    final availabilityLoaded = availabilityCubit.state.isLoaded;
    final shiftsLoaded = classroomShiftsCubit.state.isLoaded;
    final attentionLoaded = attentionCubit.state.isLoaded;
    final myDayLoaded = myDayCubit.state.isLoaded;

    final isAnyLoading =
        statusLoading ||
        ratioLoading ||
        movementsLoading ||
        availabilityLoading ||
        shiftsLoading ||
        attentionLoading ||
        myDayLoading;
    final isAnyError =
        statusError ||
        ratioError ||
        movementsError ||
        availabilityError ||
        shiftsError ||
        attentionError ||
        myDayError;
    final isAllLoaded =
        statusLoaded &&
        ratioLoaded &&
        movementsLoaded &&
        availabilityLoaded &&
        shiftsLoaded &&
        attentionLoaded &&
        myDayLoaded;
    final isAllError =
        statusError &&
        ratioError &&
        movementsError &&
        availabilityError &&
        shiftsError &&
        attentionError &&
        myDayError;

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

    final schoolCode = await _resolveSchoolCode();
    if (schoolCode != null && schoolCode.isNotEmpty) {
      await Future.wait([
        schoolStatusCubit.loadSchoolStatus(
          schoolCode: schoolCode,
          forceRefresh: true,
        ),
        ratioMonitoringCubit.loadRatioMonitoring(
          schoolCode: schoolCode,
          forceRefresh: true,
        ),
        classroomShiftsCubit.load(DateTime.now()),
        movementsCubit.refresh(),
        availabilityCubit.refresh(
          date: availabilityCubit.state.selectedDate ?? DateTime.now(),
          isTwoShifts: true,
        ),
        attentionCubit.refresh(),
        myDayCubit.refresh(),
      ]);
    } else {
      await Future.wait([
        classroomShiftsCubit.load(DateTime.now()),
        movementsCubit.refresh(),
        availabilityCubit.refresh(
          date: availabilityCubit.state.selectedDate ?? DateTime.now(),
          isTwoShifts: true,
        ),
        attentionCubit.refresh(),
        myDayCubit.refresh(),
      ]);
    }
    // No explicit _updateState() here — child cubit stream subscriptions
    // trigger _updateState() reactively as each cubit completes.
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Close all screen-scoped cubits
    dashboardCubit.close();
    schoolStatusCubit.close();
    ratioMonitoringCubit.close();
    movementsCubit.close();
    availabilityCubit.close();
    classroomShiftsCubit.close();
    attentionCubit.close();
    myDayCubit.close();

    // GeofenceCubit is a singleton — do NOT close it
    return super.close();
  }
}
