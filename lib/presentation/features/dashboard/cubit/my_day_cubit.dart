import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';

part 'my_day_state.dart';

/// Fetches the school's regular schedule and resolves today's active entry.
///
/// Reuses the existing [StaffRepository.getSchoolRegularSchedules] call —
/// no new datasource or API path is needed.
///
/// Load strategy mirrors the other dashboard cubits:
/// - First open (`isInitial`): shows shimmer.
/// - Navigation revisit (`isSilent = true`): silently refreshes, no shimmer.
/// - Pull-to-refresh: preserves existing data while re-fetching.
class MyDayCubit extends Cubit<MyDayState> {
  MyDayCubit({
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _staffRepository = staffRepository,
        _storageService = storageService,
        super(const MyDayState());

  final StaffRepository _staffRepository;
  final StorageService _storageService;

  bool _isFetching = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// First-open or navigation-revisit load.
  ///
  /// [isSilent] = true skips shimmer when data is already present (revisit).
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!isSilent && state.isInitial) {
      emit(state.copyWith(status: MyDayStatus.loading));
    }

    await _fetch();
    _isFetching = false;
  }

  /// Pull-to-refresh — keeps current data visible while re-fetching.
  Future<void> refresh() async {
    if (_isFetching) return;
    _isFetching = true;
    await _fetch();
    _isFetching = false;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _fetch() async {
    final schoolCode = await _storageService.getString(StorageKeys.schoolCode);
    if (schoolCode == null || schoolCode.trim().isEmpty) {
      emit(state.copyWith(
        status: MyDayStatus.loaded,
        schoolClosed: true,
        clearTodaySchedule: true,
      ));
      return;
    }

    try {
      final days = await _staffRepository.getSchoolRegularSchedules(
        schoolCode: schoolCode.trim(),
      );

      final now = DateTime.now();
      final todayKey = SchoolHoursResolver.dayOfWeekKey(now);

      // Find the schedule entry for today — prefer ACTIVE, then any status.
      SchoolRegularScheduleDay? todayEntry;
      for (final d in days) {
        if (d.dayOfWeek.toUpperCase() == todayKey) {
          todayEntry = d;
          break;
        }
      }

      final bool closed =
          todayEntry == null || !todayEntry.isActive;

      AppLogger.d(
        '[MyDayCubit] today=$todayKey '
        'found=${todayEntry?.dayOfWeek} '
        'status=${todayEntry?.status} '
        'closed=$closed',
      );

      emit(state.copyWith(
        status: MyDayStatus.loaded,
        todaySchedule: closed ? null : todayEntry,
        schoolClosed: closed,
        clearTodaySchedule: closed,
      ));
    } catch (e) {
      AppLogger.e('[MyDayCubit] fetch failed: $e');
      emit(state.copyWith(
        status: MyDayStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
