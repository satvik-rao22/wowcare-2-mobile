import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/auth/cubit/forgot_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_family_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_scanner_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/reset_password_cubit.dart';
import 'package:wowcare/redesign/features/auth/cubit/sign_in_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';
import 'package:wowcare/redesign/features/auth/source/preview_auth_source.dart';

/// M01 Authentication and Kiosk dependencies: preview sources during the UI
/// phase, the real usecases in the last phase. Called once from
/// `registerRedesignDependencies`.
///
/// The prefilled credentials are a fixture affordance and live here rather
/// than in the page, so the last phase drops them by deleting two arguments.
/// 1a arrives showing exactly the address its frame shows.
void registerAuthDependencies(GetIt sl) {
  sl.registerLazySingleton<AuthSource>(PreviewAuthSource.new);

  sl.registerFactory<SignInCubit>(
    () => SignInCubit(
      source: sl<AuthSource>(),
      prefillEmail: DemoData.staff.email,
      prefillPassword: _prefillPassword,
    ),
  );
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(source: sl<AuthSource>()),
  );
  sl.registerFactory<ResetPasswordCubit>(
    () => ResetPasswordCubit(source: sl<AuthSource>()),
  );
  sl.registerFactory<KioskCubit>(() => KioskCubit(source: sl<AuthSource>()));
  sl.registerFactory<KioskScannerCubit>(
    () => KioskScannerCubit(source: sl<AuthSource>()),
  );
  sl.registerFactoryParam<KioskFamilyCubit, KioskFamilyArgs, void>(
    (args, _) => KioskFamilyCubit(source: sl<AuthSource>(), args: args),
  );
}

/// Any non-empty password signs the demo accounts in. This one is what 1a's
/// frame shows behind its dots.
const String _prefillPassword = 'MapleSyrup24!';
