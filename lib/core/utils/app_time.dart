import 'package:wowcare/core/utils/server_time_service.dart';

/// Thin alias for [ServerTimeService] — prefer calling
/// `ServerTimeService.instance` directly for new code.
///
/// Kept so existing call sites keep compiling. All methods delegate to the
/// server clock with **no extra conversion**.
abstract final class AppTime {
  AppTime._();

  static DateTime nowUtc() => ServerTimeService.instance.nowUtc();

  static DateTime now() => ServerTimeService.instance.now();

  static DateTime today() => ServerTimeService.instance.today();
}
