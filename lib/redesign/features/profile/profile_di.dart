import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/profile/cubit/change_password_cubit.dart';
import 'package:wowcare/redesign/features/profile/cubit/edit_profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/cubit/notification_settings_cubit.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/source/preview_profile_source.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

/// M13 My Profile dependencies: preview sources during the UI phase, the real
/// usecases in the last phase. Called once from `registerRedesignDependencies`.
///
/// Every cubit is a factory taking the signed-in account's id as its first
/// parameter, so a screen is built for one person and no cubit ever reads
/// storage or a locator to find out who that is. The profile cubit also takes
/// the persona, so the lens is fixed for the life of the screen.
///
/// Swap [PreviewProfileMode] here to walk 13f's other three states: `offline`
/// answers off the copy saved on this phone, `failed` answers with nothing.
void registerProfileDependencies(GetIt sl) {
  sl.registerLazySingleton<ProfileSource>(PreviewProfileSource.new);

  sl.registerFactoryParam<ProfileCubit, String, Persona>(
    (userId, persona) => ProfileCubit(
      source: sl<ProfileSource>(),
      userId: userId,
      persona: persona,
    ),
  );

  sl.registerFactoryParam<EditProfileCubit, String, void>(
    (userId, _) =>
        EditProfileCubit(source: sl<ProfileSource>(), userId: userId),
  );

  sl.registerFactoryParam<NotificationSettingsCubit, String, void>(
    (userId, _) =>
        NotificationSettingsCubit(source: sl<ProfileSource>(), userId: userId),
  );

  sl.registerFactoryParam<ChangePasswordCubit, String, void>(
    (userId, _) =>
        ChangePasswordCubit(source: sl<ProfileSource>(), userId: userId),
  );
}
