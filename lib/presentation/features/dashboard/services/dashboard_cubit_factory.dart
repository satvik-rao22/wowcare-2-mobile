import 'package:get_it/get_it.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/core/util/logger_service.dart';

class DashboardCubitFactory {
  final GetIt _getIt;

  DashboardCubitFactory(this._getIt);

  T _resolveSafe<T extends Object>() {
    try {
      if (!_getIt.isRegistered<T>()) {
        AppLogger.e(
          'DashboardCubitFactory Error: Type $T is not registered in GetIt.',
        );

        // Safety Fallback Mechanisms
        if (T == ParentChildCubit) {
          AppLogger.w(
            'DashboardCubitFactory: Falling back to manual creation of ParentChildCubit.',
          );
          return ParentChildCubit() as T;
        }
        if (T == ParentDashboardCubit) {
          AppLogger.w(
            'DashboardCubitFactory: Falling back to manual creation of ParentDashboardCubit.',
          );
          return ParentDashboardCubit() as T;
        }
        if (T == StaffDashboardCubit) {
          AppLogger.w(
            'DashboardCubitFactory: Falling back to manual creation of StaffDashboardCubit.',
          );
          return StaffDashboardCubit() as T;
        }
        if (T == AdminDashboardCubit) {
          AppLogger.w(
            'DashboardCubitFactory: Falling back to manual creation of AdminDashboardCubit.',
          );
          return AdminDashboardCubit() as T;
        }
        throw StateError(
          'GetIt: Object/factory with type $T is not registered inside GetIt.',
        );
      }
      return _getIt<T>();
    } catch (e, stack) {
      AppLogger.e(
        'DashboardCubitFactory critical resolution error for $T: $e',
        e,
        stack,
      );
      rethrow;
    }
  }

  ParentDashboardCoordinatorCubit createParentDashboardCoordinator() {
    return ParentDashboardCoordinatorCubit(
      dashboardCubit: _resolveSafe<ParentDashboardCubit>(),
      myChildsDayCubit: _resolveSafe<MyChildsDayCubit>(),
      studentAttendanceProfileCubit:
          _resolveSafe<StudentAttendanceProfileCubit>(),
      communicationCubit: _resolveSafe<CommunicationCubit>(),
      studentNewslettersCubit: _resolveSafe<StudentNewslettersCubit>(),
      parentBillingCubit: _resolveSafe<ParentBillingCubit>(),
      geofenceCubit: _resolveSafe<GeofenceCubit>(),
      parentChildCubit: _resolveSafe<ParentChildCubit>(),
    );
  }

  StaffDashboardCoordinatorCubit createStaffDashboardCoordinator() {
    return StaffDashboardCoordinatorCubit(
      dashboardCubit: _resolveSafe<StaffDashboardCubit>(),
      myDayCubit: _resolveSafe<MyDayCubit>(),
      ratioMonitoringCubit: _resolveSafe<RatioMonitoringCubit>(),
      myAttendanceCubit: _resolveSafe<MyAttendanceCubit>(),
      myShiftsCubit: _resolveSafe<MyShiftsCubit>(),
      geofenceCubit: _resolveSafe<GeofenceCubit>(),
    );
  }

  AdminDashboardCoordinatorCubit createAdminDashboardCoordinator() {
    return AdminDashboardCoordinatorCubit(
      dashboardCubit: _resolveSafe<AdminDashboardCubit>(),
      schoolStatusCubit: _resolveSafe<SchoolStatusCubit>(),
      ratioMonitoringCubit: _resolveSafe<RatioMonitoringCubit>(),
      movementsCubit: _resolveSafe<IndividualMovementsCubit>(),
      availabilityCubit: _resolveSafe<FutureAvailabilityCubit>(),
      classroomShiftsCubit: _resolveSafe<ClassroomShiftsCubit>(),
      attentionCubit: _resolveSafe<DashboardAttentionCubit>(),
      myDayCubit: _resolveSafe<MyDayCubit>(),
      geofenceCubit: _resolveSafe<GeofenceCubit>(),
    );
  }
}
