import 'package:wowcare/data/features/onboarding/models/onboarding_dto.dart';

abstract class OnboardingRemoteDataSource {
  Future<List<OnboardingDto>> fetchPages();
}

class OnboardingRemoteDataSourceMock implements OnboardingRemoteDataSource {
  @override
  Future<List<OnboardingDto>> fetchPages() async {
    return const [
      OnboardingDto(
        image: 'assets/images/WowCarePNG.png',
        title: 'Welcome to WowCare',
        description: 'Manage classrooms, attendance, and communication in one app.',
      ),
      OnboardingDto(
        image: 'assets/images/WowCarePNG.png',
        title: 'Stay Connected',
        description: 'Messaging and newsletters keep everyone informed.',
      ),
      OnboardingDto(
        image: 'assets/images/WowCarePNG.png',
        title: 'Track with Ease',
        description: 'Attendance and activities made simple.',
      ),
      OnboardingDto(
        image: 'assets/images/WowCarePNG.png',
        title: 'Get Started',
        description: 'Let’s set up your experience.',
      ),
    ];
  }
}


