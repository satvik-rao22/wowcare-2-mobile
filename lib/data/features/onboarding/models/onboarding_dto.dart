import 'package:wowcare/domain/features/onboarding/entities/onboarding_entity.dart';

class OnboardingDto {
  final String image;
  final String title;
  final String description;

  const OnboardingDto({
    required this.image,
    required this.title,
    required this.description,
  });

  OnboardingEntity toEntity() =>
      OnboardingEntity(image: image, title: title, description: description);
}
