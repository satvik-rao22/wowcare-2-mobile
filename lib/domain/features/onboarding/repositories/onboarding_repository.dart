import 'package:wowcare/domain/features/onboarding/entities/onboarding_entity.dart';

abstract class OnboardingRepository {
  Future<List<OnboardingEntity>> getPages();
}
