import 'package:wowcare/domain/features/onboarding/entities/onboarding_entity.dart';
import 'package:wowcare/domain/features/onboarding/repositories/onboarding_repository.dart';

class GetOnboardingContent {
  final OnboardingRepository repository;

  const GetOnboardingContent(this.repository);

  Future<List<OnboardingEntity>> call() => repository.getPages();
}


