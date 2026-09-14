import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_state.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';

import 'dashboard_coordinator_state.dart';

extension _CommunicationStateX on CommunicationState {
  bool get isLoading =>
      this is CommunicationConversationsLoading || this is CommunicationLoading;
  bool get isError => this is CommunicationError;
  bool get isLoaded =>
      this is CommunicationConversationsLoaded ||
      this is CommunicationLoaded ||
      this is CommunicationSending;
}

class ParentDashboardCoordinatorCubit extends Cubit<DashboardState> {
  final ParentDashboardCubit dashboardCubit;
  final MyChildsDayCubit myChildsDayCubit;
  final StudentAttendanceProfileCubit studentAttendanceProfileCubit;
  final CommunicationCubit communicationCubit;
  final StudentNewslettersCubit studentNewslettersCubit;
  final ParentBillingCubit parentBillingCubit;
  final GeofenceCubit geofenceCubit;
  final ParentChildCubit parentChildCubit;

  final List<StreamSubscription> _subscriptions = [];

  ParentDashboardCoordinatorCubit({
    required this.dashboardCubit,
    required this.myChildsDayCubit,
    required this.studentAttendanceProfileCubit,
    required this.communicationCubit,
    required this.studentNewslettersCubit,
    required this.parentBillingCubit,
    required this.geofenceCubit,
    required this.parentChildCubit,
  }) : super(const DashboardState(status: DashboardStatus.initial)) {
    // Billing is family/guardian-scoped (not per-child), so load it once here
    // and keep it alive for the dashboard's lifetime. It has its own loading UI
    // and is intentionally NOT folded into the aggregated dashboard state.
    parentBillingCubit.load();
    // Subscribe to child cubits to aggregate their states reactively
    _subscriptions.add(myChildsDayCubit.stream.listen((_) => _updateState()));
    _subscriptions.add(
      studentAttendanceProfileCubit.stream.listen((_) => _updateState()),
    );
    _subscriptions.add(
      studentNewslettersCubit.stream.listen((_) => _updateState()),
    );
    _subscriptions.add(communicationCubit.stream.listen((_) => _updateState()));

    // Listen to ParentChildCubit to load data when child selection changes
    _subscriptions.add(
      parentChildCubit.stream.listen((parentChildState) {
        _onChildSelectionChanged(parentChildState);
      }),
    );

    // Trigger initial load if selected child is already set
    if (parentChildCubit.state.selectedChild != null) {
      _onChildSelectionChanged(parentChildCubit.state);
    } else {
      _updateState();
    }
  }

  /// The child the feature cubits were last loaded for, and the
  /// [ParentChildState.refreshNonce] they were loaded at. Together these are
  /// the only two inputs that should cause a reload.
  String? _loadedForChildCode;
  int? _loadedForNonce;

  void _onChildSelectionChanged(ParentChildState parentChildState) {
    final selectedChild = parentChildState.selectedChild;
    if (selectedChild != null) {
      final studentCode = selectedChild.code;
      final nonce = parentChildState.refreshNonce;

      // ParentChildCubit emits on FIVE inputs — selected child, child list,
      // isLoading, isLoaded and refreshNonce — and this listener used to
      // re-run all four feature loads on every one of them. A single refresh
      // therefore fired the same four requests two or three times over, each
      // round racing the previous one's response into the same cubits.
      //
      // Only two of those inputs mean "reload": a genuine child SWITCH, and an
      // explicit `forceRefresh()` (the nonce), which is what the parent
      // sign-in/sign-out forms use to make the dashboard re-read the child's
      // day after an attendance action. Both are preserved; the loading-flag
      // churn is not.
      if (studentCode == _loadedForChildCode && nonce == _loadedForNonce) {
        return;
      }
      _loadedForChildCode = studentCode;
      _loadedForNonce = nonce;

      // Trigger loads on feature cubits
      myChildsDayCubit.loadForChild(studentCode: studentCode);

      final now = AppTime.now();
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
    } else {
      // Selection cleared (logout, school switch, empty child list) — forget
      // what was loaded so re-selecting the SAME child still reloads it.
      _loadedForChildCode = null;
      _loadedForNonce = null;
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
    final myChildsDayLoading =
        myChildsDayCubit.state.status == MyChildsDayStatus.loading;
    final attendanceLoading = studentAttendanceProfileCubit.state.isLoading;
    final newslettersLoading = studentNewslettersCubit.state.isLoading;
    final communicationLoading = communicationCubit.state.isLoading;

    // Check error states
    final myChildsDayError =
        myChildsDayCubit.state.status == MyChildsDayStatus.error;
    final attendanceError = studentAttendanceProfileCubit.state.isError;
    final newslettersError = studentNewslettersCubit.state.isError;
    final communicationError = communicationCubit.state.isError;

    // Check loaded/ready states
    final myChildsDayLoaded =
        myChildsDayCubit.state.status == MyChildsDayStatus.loaded;
    final attendanceLoaded = studentAttendanceProfileCubit.state.isLoaded;
    final newslettersLoaded = studentNewslettersCubit.state.isLoaded;
    final communicationLoaded = communicationCubit.state.isLoaded;

    final isAnyLoading =
        myChildsDayLoading ||
        attendanceLoading ||
        newslettersLoading ||
        communicationLoading;
    final isAnyError =
        myChildsDayError ||
        attendanceError ||
        newslettersError ||
        communicationError;
    final isAllLoaded =
        myChildsDayLoaded &&
        attendanceLoaded &&
        newslettersLoaded &&
        communicationLoaded;
    final isAllError =
        myChildsDayError &&
        attendanceError &&
        newslettersError &&
        communicationError;

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
    final selectedChild = parentChildCubit.state.selectedChild;
    if (selectedChild == null) return;

    emit(state.copyWith(status: DashboardStatus.refreshing));

    // Re-validate GPS position immediately on refresh
    unawaited(geofenceCubit.refreshSettings());
    unawaited(parentBillingCubit.refresh());

    final now = AppTime.now();
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
      studentNewslettersCubit.loadFirstPage(
        studentCode: selectedChild.code,
        forceRefresh: true,
      ),
      communicationCubit.loadConversations(),
    ]);
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
    myChildsDayCubit.close();
    studentAttendanceProfileCubit.close();
    communicationCubit.close();
    studentNewslettersCubit.close();
    parentBillingCubit.close();

    // GeofenceCubit is a singleton — do NOT close it here
    return super.close();
  }
}
