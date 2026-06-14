import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';

/// State for the onboarding flow. The screen itself renders static pages, so
/// the only meaningful transition is completing onboarding.
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingCompleting extends OnboardingState {
  const OnboardingCompleting();
}

final class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}

/// Owns the onboarding completion logic so the view stays display-only.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._authLocalDataSource, this._storage)
      : super(const OnboardingInitial());

  final AuthLocalDataSource _authLocalDataSource;
  final StorageService _storage;

  /// Marks onboarding as finished.
  ///
  /// Clears any stale auth cache so the user always lands on sign-in next
  /// (avoids jumping straight to the dashboard on a leftover token/flag), then
  /// records that onboarding has been seen so it only shows once.
  Future<void> complete() async {
    emit(const OnboardingCompleting());
    await _authLocalDataSource.clearCache();
    await _storage.saveBool(StorageKeys.onboardingSeen, true);
    emit(const OnboardingCompleted());
  }
}
