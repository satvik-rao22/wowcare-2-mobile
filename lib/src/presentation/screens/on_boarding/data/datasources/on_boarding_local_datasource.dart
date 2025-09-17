import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/Common/errors/exceptions.dart';

abstract class OnBoardingLocalDatasource {
  const OnBoardingLocalDatasource();

  Future<void> cacheFirstTimer();
  Future<bool> checkIfUserIsFirstTimer();
}

const kFirstTimerKey = 'first_timer';

class OnBoardingLocalDatasourceImpl extends OnBoardingLocalDatasource {
  const OnBoardingLocalDatasourceImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<void> cacheFirstTimer() async {
    try {
      await _prefs.setBool(kFirstTimerKey, false);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<bool> checkIfUserIsFirstTimer() async {
    try {
      return _prefs.getBool(kFirstTimerKey) ?? true;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
