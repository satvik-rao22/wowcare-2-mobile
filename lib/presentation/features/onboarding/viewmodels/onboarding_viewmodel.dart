import 'package:flutter/foundation.dart';

import '../../../../domain/features/onboarding/entities/onboarding_entity.dart';
import '../../../../domain/features/onboarding/usecases/get_onboarding_content.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._getOnboardingContent);

  final GetOnboardingContent _getOnboardingContent;

  OnboardingEntity? _onboarding;
  bool _isLoading = false;
  Object? _error;

  OnboardingEntity? get onboarding => _onboarding;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _getOnboardingContent();
      _onboarding = result as OnboardingEntity?;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
