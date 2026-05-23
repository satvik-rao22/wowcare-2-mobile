import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import '../usecases/get_staff_shifts_usecase.dart';
import '../../attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'absence_validator.dart';
import 'availability_validator.dart';
import 'recurring_date_generator.dart';
import 'scheduling_conflict_detector.dart';
import 'shift_time_validators.dart';
import 'shift_validation_models.dart';

class ShiftValidationService {
  ShiftValidationService({
    required StaffRepository staffRepository,
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required GetStaffAbsentFormListUseCase getStaffAbsentFormListUseCase,
    AvailabilityValidator? availabilityValidator,
    SchedulingConflictDetector? conflictDetector,
  }) : _staffRepository = staffRepository,
       _getStaffShiftsUseCase = getStaffShiftsUseCase,
       _absenceValidator = AbsenceValidator(getStaffAbsentFormListUseCase),
       _availabilityValidator = availabilityValidator ?? const AvailabilityValidator(),
       _conflictDetector = conflictDetector ?? const SchedulingConflictDetector();

  final StaffRepository _staffRepository;
  final GetStaffShiftsUseCase _getStaffShiftsUseCase;
  final AbsenceValidator _absenceValidator;
  final AvailabilityValidator _availabilityValidator;
  final SchedulingConflictDetector _conflictDetector;

  Future<ShiftValidationResult> validateCreate({
    required ShiftDraft draft,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final errors = <ShiftValidationError>[];

    // Basic time validations.
    final shiftRangeError = ShiftTimeValidators.validateShiftRange(
      start: draft.startTime,
      end: draft.endTime,
    );
    if (shiftRangeError != null) {
      errors.add(
        ShiftValidationError(
          code: ShiftValidationErrorCode.invalidShiftRange,
          message: shiftRangeError,
        ),
      );
    }

    final breakError = ShiftTimeValidators.validateBreakRange(
      breakStart: draft.breakStartTime,
      breakEnd: draft.breakEndTime,
      shiftStart: draft.startTime,
      shiftEnd: draft.endTime,
    );
    if (breakError != null) {
      errors.add(
        ShiftValidationError(
          code: ShiftValidationErrorCode.invalidBreakRange,
          message: breakError,
        ),
      );
    }

    // Recurring validations.
    if (draft.isRecurring) {
      if (draft.repeatUntilDate == null) {
        errors.add(
          const ShiftValidationError(
            code: ShiftValidationErrorCode.repeatUntilMissing,
            message: 'Please select until date',
          ),
        );
      } else {
        final start = DateTime(draft.shiftDate.year, draft.shiftDate.month, draft.shiftDate.day);
        final until = DateTime(draft.repeatUntilDate!.year, draft.repeatUntilDate!.month, draft.repeatUntilDate!.day);
        if (until.isBefore(start)) {
          errors.add(
            const ShiftValidationError(
              code: ShiftValidationErrorCode.repeatUntilBeforeStart,
              message: 'Repeat until date must be on/after the shift date',
            ),
          );
        }
      }
    }

    if (errors.isNotEmpty) {
      return ShiftValidationResult(
        errors: errors,
        conflicts: const [],
        requiresForceAddConfirmation: false,
        requiresOverrideConfirmation: false,
        affectedDates: const [],
      );
    }

    final dates = draft.isRecurring
        ? RecurringDateGenerator.generate(
            startDate: draft.shiftDate,
            untilDate: draft.repeatUntilDate!,
            repeatDayCodes: draft.repeatDayCodes,
          )
        : [DateTime(draft.shiftDate.year, draft.shiftDate.month, draft.shiftDate.day)];

    // Absence validation (hard block).
    final isAbsent = await _absenceValidator.isStaffAbsentOnAnyDate(
      staffCode: draft.staffCode,
      dates: dates,
    );
    if (isAbsent) {
      return ShiftValidationResult(
        errors: const [
          ShiftValidationError(
            code: ShiftValidationErrorCode.absentStaff,
            message:
                'This staff is marked absent for the selected days, so no shift can be added for them.',
          ),
        ],
        conflicts: const [],
        requiresForceAddConfirmation: false,
        requiresOverrideConfirmation: false,
        affectedDates: dates,
      );
    }

    // Availability validation.
    StaffProfile? profile;
    try {
      profile = await _staffRepository.getStaffProfile(
        staffCode: draft.staffCode,
        forEditStaff: true,
      );
    } catch (_) {
      profile = null;
    }

    bool outsideAvailability = false;
    if (profile != null) {
      for (final d in dates) {
        final ok = _availabilityValidator.isWithinAvailabilityForDate(
          profile: profile,
          date: d,
          shiftStart: draft.startTime,
          shiftEnd: draft.endTime,
          breakStart: draft.breakStartTime,
          breakEnd: draft.breakEndTime,
        );
        if (!ok) {
          outsideAvailability = true;
          break;
        }
      }
    }

    // Conflicts validation.
    final from = DateFormat('yyyy-MM-dd').format(dates.first);
    final to = DateFormat('yyyy-MM-dd').format(dates.last);
    final existing = await _getStaffShiftsUseCase(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      staffCode: draft.staffCode,
      dateFrom: from,
      dateTo: to,
      page: 0,
      size: 200,
    );

    final conflicts = <ShiftConflict>[];
    for (final d in dates) {
      conflicts.addAll(
        _conflictDetector.detect(
          existing: existing,
          date: d,
          start: draft.startTime,
          end: draft.endTime,
          classroomCode: draft.classroomCode,
        ),
      );
    }

    final requiresOverride = conflicts.isNotEmpty;

    final requiresForceAdd = outsideAvailability && draft.isSingleShift;
    if (outsideAvailability && draft.isRecurring) {
      // Recurring cannot force-add.
      errors.add(
        const ShiftValidationError(
          code: ShiftValidationErrorCode.outsideAvailability,
          message: 'Shift times must be within staff availability for recurring shifts',
        ),
      );
    }

    return ShiftValidationResult(
      errors: errors,
      conflicts: conflicts,
      requiresForceAddConfirmation: requiresForceAdd,
      requiresOverrideConfirmation: requiresOverride,
      affectedDates: dates,
    );
  }
}

