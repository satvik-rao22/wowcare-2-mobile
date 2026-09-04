import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_range_cubit.dart';
import 'package:wowcare/redesign/features/attendance/cubit/sign_attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';
import 'package:wowcare/redesign/features/attendance/source/preview_attendance_source.dart';

/// M04 Attendance dependencies: preview sources during the UI phase, the real
/// usecases in the last phase. Called once from `registerRedesignDependencies`.
///
/// The persona and the classroom a staff member is rostered to are factory
/// parameters rather than something a cubit reads off a locator, so a screen
/// is built for one lens and never has to ask who is looking.
///
/// The source is a lazy singleton rather than a factory because the preview
/// one holds the writes: signing somebody in on 4a has to still be true when
/// the list reloads behind the form.
///
/// [_today] is the school's day, passed into every cubit so "today", "a past
/// day" and "how long have they been here" are all measured against the same
/// clock. Phase 5 swaps it for `SchoolZoneDateTime` and no cubit changes.
void registerAttendanceDependencies(GetIt sl) {
  sl.registerLazySingleton<AttendanceSource>(PreviewAttendanceSource.new);

  sl.registerFactoryParam<AttendanceCubit, Persona, String?>(
    (persona, scopeClassroom) => AttendanceCubit(
      source: sl<AttendanceSource>(),
      persona: persona,
      today: _today,
      scopeClassroom: scopeClassroom,
    ),
  );

  sl.registerFactoryParam<AttendanceRangeCubit, DateRange, void>(
    (range, _) =>
        AttendanceRangeCubit(source: sl<AttendanceSource>(), range: range),
  );

  sl.registerFactoryParam<SignAttendanceCubit, SignAttendanceArgs, Persona>(
    (args, persona) => SignAttendanceCubit(
      source: sl<AttendanceSource>(),
      args: args,
      persona: persona,
      today: _today,
    ),
  );
}

/// The design draws every frame on this day, and the fixtures are written
/// against it, so the screens have to agree with them about what "today"
/// means.
DateTime get _today => DemoData.today;
