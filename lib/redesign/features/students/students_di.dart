import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/cubit/edit_student_cubit.dart';
import 'package:wowcare/redesign/features/students/cubit/student_documents_cubit.dart';
import 'package:wowcare/redesign/features/students/cubit/student_profile_cubit.dart';
import 'package:wowcare/redesign/features/students/cubit/students_roster_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/preview_students_source.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

/// M05 Students dependencies: preview sources during the UI phase, the real
/// usecases in the last phase. Called once from `registerRedesignDependencies`.
///
/// The roster's persona and classroom scope are factory parameters rather
/// than something a cubit reads off a locator, so a screen is built for one
/// lens and never has to ask who is looking.
///
/// [_today] is the school's day, passed into the two forms so a date rule is
/// testable and so it can become `SchoolZoneDateTime` in the last phase
/// without touching either cubit.
void registerStudentsDependencies(GetIt sl) {
  sl.registerLazySingleton<StudentsSource>(PreviewStudentsSource.new);

  sl.registerFactoryParam<StudentsRosterCubit, Persona, String?>(
    (persona, scopeClassroom) => StudentsRosterCubit(
      source: sl<StudentsSource>(),
      persona: persona,
      scopeClassroom: scopeClassroom,
    ),
  );

  sl.registerFactoryParam<StudentProfileCubit, String, Persona>(
    (studentId, persona) => StudentProfileCubit(
      source: sl<StudentsSource>(),
      studentId: studentId,
      persona: persona,
    ),
  );

  sl.registerFactory<AddStudentCubit>(
    () => AddStudentCubit(source: sl<StudentsSource>(), today: _today),
  );

  sl.registerFactoryParam<EditStudentCubit, String, void>(
    (studentId, _) => EditStudentCubit(
      source: sl<StudentsSource>(),
      studentId: studentId,
      today: _today,
    ),
  );

  sl.registerFactoryParam<StudentDocumentsCubit, StudentDocumentsArgs, void>(
    (args, _) =>
        StudentDocumentsCubit(source: sl<StudentsSource>(), args: args),
  );
}

/// The design draws every frame on this day, and the fixtures are written
/// against it, so the forms have to agree with them about what "in the past"
/// means.
DateTime get _today => DemoData.today;
