import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';

import 'dashboard_coordinator_state.dart';

extension _CommunicationStateX on CommunicationState {
  bool get isLoading => this is CommunicationConversationsLoading || this is CommunicationLoading;
  bool get isError => this is CommunicationError;
  bool get isLoaded => this is CommunicationConversationsLoaded || this is CommunicationLoaded || this is CommunicationSending;
}

class ParentDashboardCoordinatorCubit extends Cubit<DashboardState> {
  final ParentDashboardCubit dashboardCubit;
  final MyChildsDayCubit myChildsDayCubit;
  final StudentAttendanceProfileCubit studentAttendanceProfileCubit;
  final CommunicationCubit communicationCubit;
  final StudentNewslettersCubit studentNewslettersCubit;
  final GeofenceCubit geofenceCubit;
  final ParentChildCubit parentChildCubit;

  final List<StreamSubscription> _subscriptions = [];

  ParentDashboardCoordinatorCubit({
    required this.dashboardCubit,
    required this.myChildsDayCubit,
    required this.studentAttendanceProfileCubit,
    required this.communicationCubit,
    required this.studentNewslettersCubit,
    required this.geofenceCubit,
    required this.parentChildCubit,
  }) : super(const DashboardState(status: DashboardStatus.initial)) {
    // Subscribe to child cubits to aggregate their states reactively
    _subscriptions.add(myChildsDayCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(studentAttendanceProfileCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(studentNewslettersCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(communicationCubit.stream.listen((_) => _updateState()));

    // Listen to ParentChildCubit to load data when child selection changes
    _subscriptions.add(parentChildCubit.stream.listen((parentChildState) {
      _onChildSelectionChanged(parentChildState);
    }));

    // Trigger initial load if selected child is already set
    if (parentChildCubit.state.selectedChild != null) {
      _onChildSelectionChanged(parentChildCubit.state);
    } else {
      _updateState();
    }
  }

  void _onChildSelectionChanged(ParentChildState parentChildState) {
    final selectedChild = parentChildState.selectedChild;
    if (selectedChild != null) {
      final studentCode = selectedChild.code;
      
      // Trigger loads on feature cubits
      myChildsDayCubit.loadForChild(studentCode: studentCode);
      
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month, 1);
      final toDate = now;
      studentAttendanceProfileCubit.loadAttendanceProfile(
        studentCode: studentCode,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      studentNewslettersCubit.loadFirstPage(studentCode: studentCode);
      communicationCubit.loadConversations();
      
      // Initialize geofence
      _initGeofence();
    }
  }

  Future<void> _initGeofence() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = await storage.getString(StorageKeys.schoolCode);
    if (schoolCode != null && schoolCode.isNotEmpty) {
      await geofenceCubit.initForSchool(schoolCode: schoolCode);
    }
  }

  void _updateState() {
    if (isClosed) return;

    // Check loading states
    final myChildsDayLoading = myChildsDayCubit.state.status == MyChildsDayStatus.loading;
    final attendanceLoading = studentAttendanceProfileCubit.state.isLoading;
    final newslettersLoading = studentNewslettersCubit.state.isLoading;
    final communicationLoading = communicationCubit.state.isLoading;

    // Check error states
    final myChildsDayError = myChildsDayCubit.state.status == MyChildsDayStatus.error;
    final attendanceError = studentAttendanceProfileCubit.state.isError;
    final newslettersError = studentNewslettersCubit.state.isError;
    final communicationError = communicationCubit.state.isError;

    // Check loaded/ready states
    final myChildsDayLoaded = myChildsDayCubit.state.status == MyChildsDayStatus.loaded;
    final attendanceLoaded = studentAttendanceProfileCubit.state.isLoaded;
    final newslettersLoaded = studentNewslettersCubit.state.isLoaded;
    final communicationLoaded = communicationCubit.state.isLoaded;

    final isAnyLoading = myChildsDayLoading || attendanceLoading || newslettersLoading || communicationLoading;
    final isAnyError = myChildsDayError || attendanceError || newslettersError || communicationError;
    final isAllLoaded = myChildsDayLoaded && attendanceLoaded && newslettersLoaded && communicationLoaded;
    final isAllError = myChildsDayError && attendanceError && newslettersError && communicationError;

    if (isAnyLoading) {
      if (state.status == DashboardStatus.ready || state.status == DashboardStatus.partialError) {
        emit(state.copyWith(status: DashboardStatus.refreshing));
      } else {
        emit(state.copyWith(status: DashboardStatus.loading));
      }
    } else if (isAllError) {
      emit(state.copyWith(status: DashboardStatus.failure, errorMessage: "Failed to load dashboard data"));
    } else if (isAnyError) {
      emit(state.copyWith(status: DashboardStatus.partialError));
    } else if (isAllLoaded || (myChildsDayLoaded || attendanceLoaded || newslettersLoaded)) {
      emit(state.copyWith(status: DashboardStatus.ready));
    } else {
      emit(state.copyWith(status: DashboardStatus.initial));
    }
  }

  Future<void> refresh() async {
    final selectedChild = parentChildCubit.state.selectedChild;
    if (selectedChild == null) return;
    
    emit(state.copyWith(status: DashboardStatus.refreshing));
    
    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, 1);
    final toDate = now;

    await Future.wait([
      myChildsDayCubit.loadForChild(studentCode: selectedChild.code),
      studentAttendanceProfileCubit.loadAttendanceProfile(
        studentCode: selectedChild.code,
        fromDate: fromDate,
        toDate: toDate,
        forceRefresh: true,
      ),
      studentNewslettersCubit.loadFirstPage(studentCode: selectedChild.code, forceRefresh: true),
      communicationCubit.loadConversations(),
    ]);

    _updateState();
  }

  @override
  Future<void> close() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Close all screen-scoped cubits
    dashboardCubit.close();
    myChildsDayCubit.close();
    studentAttendanceProfileCubit.close();
    communicationCubit.close();
    studentNewslettersCubit.close();

    // GeofenceCubit is a singleton — do NOT close it here
    return super.close();
  }
}
