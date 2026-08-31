import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/staff_address_update.dart';
import '../../../../domain/features/staff/entities/staff_profile_update.dart';
import '../../../../domain/features/staff/usecases/activate_organization_admin_usecase.dart';
import '../../../../domain/features/staff/usecases/activate_school_user_usecase.dart';
import '../../../../domain/features/staff/usecases/change_user_email_usecase.dart';
import '../../../../domain/features/staff/usecases/deactivate_organization_admin_usecase.dart';
import '../../../../domain/features/staff/usecases/deactivate_school_user_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_address_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_allowed_classrooms_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_primary_classroom_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_profile_usecase.dart';

part 'staff_profile_edit_state.dart';

/// Mutations backing the Edit Staff Profile (edit_profile_details_screen) save.
///
/// The screen routes every write for the multi-step save through this cubit →
/// use case → repository so the view no longer depends on [StaffRepository]
/// directly. The save ORCHESTRATION (sequence, conditionals, status-transition
/// branches, message building, snackbars, navigation) stays in the view; this
/// cubit only owns the individual call targets.
class StaffProfileEditCubit extends Cubit<StaffProfileEditState> {
  StaffProfileEditCubit({
    required UpdateStaffProfileUseCase updateStaffProfileUseCase,
    required UpdateStaffAddressUseCase updateStaffAddressUseCase,
    required UpdateStaffAllowedClassroomsUseCase
        updateStaffAllowedClassroomsUseCase,
    required UpdateStaffPrimaryClassroomUseCase
        updateStaffPrimaryClassroomUseCase,
    required ChangeUserEmailUseCase changeUserEmailUseCase,
    required ActivateOrganizationAdminUseCase activateOrganizationAdminUseCase,
    required DeactivateOrganizationAdminUseCase
        deactivateOrganizationAdminUseCase,
    required ActivateSchoolUserUseCase activateSchoolUserUseCase,
    required DeactivateSchoolUserUseCase deactivateSchoolUserUseCase,
  })  : _updateStaffProfileUseCase = updateStaffProfileUseCase,
        _updateStaffAddressUseCase = updateStaffAddressUseCase,
        _updateStaffAllowedClassroomsUseCase =
            updateStaffAllowedClassroomsUseCase,
        _updateStaffPrimaryClassroomUseCase =
            updateStaffPrimaryClassroomUseCase,
        _changeUserEmailUseCase = changeUserEmailUseCase,
        _activateOrganizationAdminUseCase = activateOrganizationAdminUseCase,
        _deactivateOrganizationAdminUseCase =
            deactivateOrganizationAdminUseCase,
        _activateSchoolUserUseCase = activateSchoolUserUseCase,
        _deactivateSchoolUserUseCase = deactivateSchoolUserUseCase,
        super(const StaffProfileEditState.initial());

  final UpdateStaffProfileUseCase _updateStaffProfileUseCase;
  final UpdateStaffAddressUseCase _updateStaffAddressUseCase;
  final UpdateStaffAllowedClassroomsUseCase _updateStaffAllowedClassroomsUseCase;
  final UpdateStaffPrimaryClassroomUseCase _updateStaffPrimaryClassroomUseCase;
  final ChangeUserEmailUseCase _changeUserEmailUseCase;
  final ActivateOrganizationAdminUseCase _activateOrganizationAdminUseCase;
  final DeactivateOrganizationAdminUseCase _deactivateOrganizationAdminUseCase;
  final ActivateSchoolUserUseCase _activateSchoolUserUseCase;
  final DeactivateSchoolUserUseCase _deactivateSchoolUserUseCase;

  // --- Mutations (each keyed single-flight; rethrow) ---

  /// In-flight mutations keyed by `action:code`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlight<T>(
    String key,
    Future<T> Function() operation,
  ) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing as Future<T>;
    final future = operation();
    _inFlightMutations[key] = future;
    // Clear the in-flight entry on completion. `whenComplete` returns a new
    // future that mirrors any error; ignore it so a rethrown mutation error
    // surfaces only through the caller's `future` and isn't double-reported as
    // an unhandled async error.
    future.whenComplete(() => _inFlightMutations.remove(key)).ignore();
    return future;
  }

  Future<String> updateProfile({
    required String staffCode,
    required StaffProfileUpdate fields,
  }) {
    return _singleFlight<String>('updateProfile:$staffCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStaffProfileUseCase(
          staffCode: staffCode,
          fields: fields,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateAddress({
    required String staffCode,
    required StaffAddressUpdate fields,
  }) {
    return _singleFlight<String>('updateAddress:$staffCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStaffAddressUseCase(
          staffCode: staffCode,
          fields: fields,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateAllowedClassrooms({
    required String staffCode,
    required List<String> classroomCodes,
  }) {
    return _singleFlight<String>('allowedClassrooms:$staffCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStaffAllowedClassroomsUseCase(
          staffCode: staffCode,
          classroomCodes: classroomCodes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updatePrimaryClassroom({
    required String staffCode,
    required String classroomCode,
  }) {
    return _singleFlight<String>('primaryClassroom:$staffCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStaffPrimaryClassroomUseCase(
          staffCode: staffCode,
          classroomCode: classroomCode,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> changeUserEmail({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _singleFlight<String>('changeEmail:$userCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _changeUserEmailUseCase(
          userCode: userCode,
          oldEmail: oldEmail,
          newEmail: newEmail,
          organizationCode: organizationCode,
          schoolCode: schoolCode,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> activateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) {
    return _singleFlight<String>(
      'activateOrgAdmin:$userCode:$organizationCode',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _activateOrganizationAdminUseCase(
            userCode: userCode,
            organizationCode: organizationCode,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  Future<String> deactivateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) {
    return _singleFlight<String>(
      'deactivateOrgAdmin:$userCode:$organizationCode',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _deactivateOrganizationAdminUseCase(
            userCode: userCode,
            organizationCode: organizationCode,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    return _singleFlight<String>('activateSchoolUser:$userCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _activateSchoolUserUseCase(
          userCode: userCode,
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          role: role,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    return _singleFlight<String>('deactivateSchoolUser:$userCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _deactivateSchoolUserUseCase(
          userCode: userCode,
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          role: role,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
