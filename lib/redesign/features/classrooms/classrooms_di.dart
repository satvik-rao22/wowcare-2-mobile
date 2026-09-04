import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/assign_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_profile_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classrooms_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/create_classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

/// M07 Classrooms dependencies: preview sources during the UI phase, the real
/// usecases in the last phase. Called once from `registerRedesignDependencies`.
///
/// The screens that belong to one classroom take their id and their persona as
/// factory parameters, so a cubit never has to ask who is looking or what it
/// is looking at: it is built for one classroom and one role.
void registerClassroomsDependencies(GetIt sl) {
  sl.registerLazySingleton<ClassroomsSource>(PreviewClassroomsSource.new);

  sl.registerFactory<ClassroomsCubit>(
    () => ClassroomsCubit(source: sl<ClassroomsSource>()),
  );

  sl.registerFactoryParam<ClassroomCubit, ClassroomArgs, void>(
    (args, _) => ClassroomCubit(
      source: sl<ClassroomsSource>(),
      classroomId: args.classroomId,
      persona: args.persona,
      isOwnClassroom: args.isOwnClassroom,
    ),
  );

  sl.registerFactoryParam<ClassroomProfileCubit, String, Persona>(
    (classroomId, persona) => ClassroomProfileCubit(
      source: sl<ClassroomsSource>(),
      classroomId: classroomId,
      persona: persona,
    ),
  );

  sl.registerFactoryParam<AssignCubit, String, AssignKind>(
    (classroomId, kind) => AssignCubit(
      source: sl<ClassroomsSource>(),
      classroomId: classroomId,
      kind: kind,
    ),
  );

  sl.registerFactory<CreateClassroomCubit>(
    () => CreateClassroomCubit(source: sl<ClassroomsSource>()),
  );
}
