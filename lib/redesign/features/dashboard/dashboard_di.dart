import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/source/dashboard_source.dart';
import 'package:wowcare/redesign/features/dashboard/source/preview_dashboard_source.dart';

/// M03 Dashboard and More dependencies: preview sources during the UI phase,
/// the real usecases in the last phase. Called once from
/// `registerRedesignDependencies`.
///
/// The cubit takes its persona as a factory parameter rather than reading a
/// role cubit, so the dashboard never has to ask who is looking: it is built
/// for one persona and reloaded when that changes.
void registerDashboardDependencies(GetIt sl) {
  sl.registerLazySingleton<DashboardSource>(PreviewDashboardSource.new);

  sl.registerFactoryParam<DashboardCubit, Persona, void>(
    (persona, _) => DashboardCubit(
      source: sl<DashboardSource>(),
      persona: persona,
    ),
  );
}
