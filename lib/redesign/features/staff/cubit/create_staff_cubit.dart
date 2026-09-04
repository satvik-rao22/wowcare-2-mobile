import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

part 'create_staff_state.dart';

/// 6d, Add Admin or Staff: three steps, the third of them skippable.
///
/// A step is validated as it is left, not as it is typed, which is what lets
/// the wizard's steps be tapped back to. There is no PIN field: the PIN
/// endpoint is read only, so the Sign-In PIN is issued with the record and
/// only ever shown back on 6c.
class CreateStaffCubit extends Cubit<CreateStaffState> {
  CreateStaffCubit({required StaffSource source})
    : _source = source,
      super(const CreateStaffState());

  final StaffSource _source;

  bool _isFetching = false;

  /// The designations, classrooms and job tags the form may pick from.
  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final options = await _source.loadOptions();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CreateStaffStatus.editing,
          options: options,
          draft: state.draft.copyWith(week: _defaultWeek),
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: CreateStaffStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  // --- Step one ---------------------------------------------------------------

  void setStatus(StaffStatus status) =>
      _edit(state.draft.copyWith(status: status));

  void setFirstName(String value) =>
      _edit(state.draft.copyWith(firstName: value));

  void setLastName(String value) =>
      _edit(state.draft.copyWith(lastName: value));

  void setEmail(String value) => _edit(state.draft.copyWith(email: value));

  void setPhone(String value) => _edit(state.draft.copyWith(phone: value));

  // --- Step two ---------------------------------------------------------------

  /// Changing the role drops the designation with it: the two lists do not
  /// overlap, and the existing screen refuses a designation from the other.
  void setRole(StaffRole role) => _edit(
    state.draft.copyWith(
      role: role,
      clearDesignation: true,
      clearPrimaryClassroom: role == StaffRole.admin,
      allowedClassrooms: role == StaffRole.admin ? const <String>{} : null,
    ),
  );

  void setDesignation(String designation) =>
      _edit(state.draft.copyWith(designation: designation));

  void setPrimaryClassroom(String classroom) => _edit(
    state.draft.copyWith(
      primaryClassroom: classroom,
      allowedClassrooms: <String>{...state.draft.allowedClassrooms, classroom},
    ),
  );

  void setAllowedClassrooms(Set<String> classrooms) =>
      _edit(state.draft.copyWith(allowedClassrooms: classrooms));

  void setJobTags(Set<String> tags) =>
      _edit(state.draft.copyWith(jobTags: tags));

  // --- Step three -------------------------------------------------------------

  void setSameShiftEveryDay({required bool value}) {
    final draft = state.draft.copyWith(sameShiftEveryDay: value);
    _edit(value ? draft.copyWith(week: _spread(draft.week)) : draft);
  }

  void setShift(StaffShift shift) {
    final week = <StaffShift>[
      for (final day in state.draft.week)
        if (day.weekday == shift.weekday) shift else day,
    ];
    _edit(
      state.draft.copyWith(
        week: state.draft.sameShiftEveryDay ? _spread(week, from: shift) : week,
      ),
    );
  }

  /// "Copy to all days": Monday's times, or whichever day was touched last,
  /// written across the week.
  void copyToAllDays(int weekday) {
    final source = state.draft.week.firstWhere(
      (day) => day.weekday == weekday,
      orElse: () => state.draft.week.first,
    );
    _edit(state.draft.copyWith(week: _spread(state.draft.week, from: source)));
  }

  // --- Moving through the wizard ----------------------------------------------

  /// Validates the step that is showing and moves on. On the last step it
  /// saves instead.
  Future<void> next() async {
    final errors = _validate(state.step);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }
    if (state.step < CreateStaffState.lastStep) {
      emit(
        state.copyWith(
          step: state.step + 1,
          errors: const <StaffField, String>{},
        ),
      );
      return;
    }
    await submit();
  }

  void back() {
    if (state.step == 1) return;
    emit(
      state.copyWith(
        step: state.step - 1,
        errors: const <StaffField, String>{},
      ),
    );
  }

  /// Tapping a step row. Only a step that has already been reached opens, so
  /// the wizard cannot be skipped forward past a field it needs.
  void goToStep(int step) {
    if (step > state.step || step == state.step) return;
    emit(state.copyWith(step: step, errors: const <StaffField, String>{}));
  }

  /// "Skip, set the shifts later": the record is created without a week.
  Future<void> skipShifts() async {
    if (state.step != CreateStaffState.lastStep) return;
    emit(
      state.copyWith(draft: state.draft.copyWith(week: const <StaffShift>[])),
    );
    await submit();
  }

  Future<void> submit() async {
    if (state.isSaving) return;

    for (var step = 1; step <= CreateStaffState.lastStep; step++) {
      final errors = _validate(step);
      if (errors.isNotEmpty) {
        emit(state.copyWith(step: step, errors: errors));
        return;
      }
    }

    emit(
      state.copyWith(
        status: CreateStaffStatus.saving,
        errors: const <StaffField, String>{},
      ),
    );
    try {
      final created = await _source.createStaff(state.draft);
      if (isClosed) return;
      emit(state.copyWith(status: CreateStaffStatus.saved, created: created));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: CreateStaffStatus.failed));
    }
  }

  void _edit(StaffDraft draft) => emit(state.copyWith(draft: draft).cleared());

  Map<StaffField, String> _validate(int step) {
    final draft = state.draft;
    final errors = <StaffField, String>{};

    if (step == 1) {
      if (draft.firstName.trim().isEmpty) {
        errors[StaffField.firstName] = StaffStrings.nameRequired;
      }
      if (draft.lastName.trim().isEmpty) {
        errors[StaffField.lastName] = StaffStrings.nameRequired;
      }
      if (!_isEmail(draft.email)) {
        errors[StaffField.email] = StaffStrings.invalidEmail;
      }
      if (!_isPhone(draft.phone)) {
        errors[StaffField.phone] = StaffStrings.invalidPhone;
      }
      return errors;
    }

    if (step == 2) {
      final designation = draft.designation;
      final allowed = state.options.designationsFor(draft.role);
      if (designation == null || !allowed.contains(designation)) {
        errors[StaffField.designation] = StaffStrings.pickDesignationError;
      }
      // An Admin covers every classroom, so the two classroom fields are a
      // staff member's only, exactly as `CreateSchoolUserUseCase` splits them.
      if (draft.role == StaffRole.staff) {
        if (draft.primaryClassroom == null || draft.primaryClassroom!.isEmpty) {
          errors[StaffField.primaryClassroom] = StaffStrings.pickPrimaryError;
        }
        if (draft.effectiveAllowed.isEmpty) {
          errors[StaffField.allowedClassrooms] = StaffStrings.pickAllowedError;
        }
      }
      return errors;
    }

    for (final shift in draft.week) {
      if (!shift.isOrderValid) {
        errors[StaffField.shifts] = StaffStrings.shiftOrderError;
        return errors;
      }
      if (!shift.isBreakInsideShift) {
        errors[StaffField.shifts] = StaffStrings.breakOutsideError;
        return errors;
      }
    }
    return errors;
  }

  static bool _isEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final at = trimmed.indexOf('@');
    if (at <= 0 || at == trimmed.length - 1) return false;
    final domain = trimmed.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.') &&
        !trimmed.contains(' ');
  }

  /// Ten digits, however they are punctuated. The existing screen formats
  /// them as `(603) 555-0188`; what matters here is that there are ten.
  static bool _isPhone(String value) =>
      value.replaceAll(RegExp(r'\D'), '').length == 10;

  /// Monday to Friday, 8:30 to 17:00 with a 12:30 break, which is the week
  /// the frame opens on.
  static List<StaffShift> get _defaultWeek => <StaffShift>[
    for (var weekday = DateTime.monday; weekday <= DateTime.friday; weekday++)
      StaffShift(
        weekday: weekday,
        startMinutes: 510,
        endMinutes: 1020,
        breakStartMinutes: 750,
        breakEndMinutes: 780,
      ),
  ];

  /// One day's times across every day of the week.
  static List<StaffShift> _spread(List<StaffShift> week, {StaffShift? from}) {
    if (week.isEmpty) return week;
    final source = from ?? week.first;
    return <StaffShift>[for (final day in week) source.copyOnto(day.weekday)];
  }
}
