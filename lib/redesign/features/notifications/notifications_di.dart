import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/cubit/notification_center_cubit.dart';
import 'package:wowcare/redesign/features/notifications/source/notifications_source.dart';
import 'package:wowcare/redesign/features/notifications/source/preview_notifications_source.dart';

/// M12 Notifications dependencies: preview sources during the UI phase, the
/// real usecases in the last phase. Called once from
/// `registerRedesignDependencies`.
///
/// The cubit is a factory taking the reader's persona, so the screen is built
/// for one person and no cubit reads a locator to find out who that is.
///
/// The source is a singleton rather than a factory because it carries the
/// session's read state and the arrival signal, both of which must survive
/// leaving the screen and coming back.
///
/// Swap [PreviewNotificationsMode] here to walk 12b's other states: `empty`
/// answers with an inbox nothing has ever arrived in, `failed` answers with
/// nothing at all, `offline` answers once and then stops (the banner over a
/// list still worth reading), and `arriving` lands a push a few seconds after
/// the first page.
void registerNotificationsDependencies(GetIt sl) {
  sl.registerLazySingleton<NotificationsSource>(
    PreviewNotificationsSource.new,
    dispose: (source) {
      if (source is PreviewNotificationsSource) source.dispose();
    },
  );

  sl.registerFactoryParam<NotificationCenterCubit, Persona, void>(
    (persona, _) => NotificationCenterCubit(
      source: sl<NotificationsSource>(),
      persona: persona,
    ),
  );
}
