import 'package:wowcare/data/features/onboarding/datasources/onboarding_remote_datasource.dart';
import 'package:wowcare/domain/features/onboarding/entities/onboarding_entity.dart';
import 'package:wowcare/domain/features/onboarding/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remote;

  OnboardingRepositoryImpl(this.remote);

  @override
  Future<List<OnboardingEntity>> getPages() async {
    final dtos = await remote.fetchPages();
    return dtos.map((d) => d.toEntity()).toList();
  }
}


