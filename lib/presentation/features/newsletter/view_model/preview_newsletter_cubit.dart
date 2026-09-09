import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/usecases/get_newsletter_by_code_usecase.dart';

class PreviewNewsletterCubit extends Cubit<PreviewNewsletterState> {
  PreviewNewsletterCubit(this._getNewsletterByCodeUseCase)
      : super(const PreviewNewsletterState.initial());

  final GetNewsletterByCodeUseCase _getNewsletterByCodeUseCase;

  Future<void> load({
    required String newsletterCode,
    Newsletter? initialNewsletter,
  }) async {
    final code = newsletterCode.trim();
    if (code.isEmpty) {
      emit(
        const PreviewNewsletterState.failure(
          errorMessage: AppStrings.newsletterCodeMissing,
        ),
      );
      return;
    }

    emit(
      PreviewNewsletterState.loading(
        newsletter: initialNewsletter,
      ),
    );

    try {
      final newsletter = await _getNewsletterByCodeUseCase(code);
      if (isClosed) return;
      emit(PreviewNewsletterState.loaded(newsletter: newsletter));
    } catch (e) {
      if (isClosed) return;
      emit(
        PreviewNewsletterState.failure(
          newsletter: initialNewsletter,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}

class PreviewNewsletterState extends Equatable {
  const PreviewNewsletterState({
    required this.newsletter,
    required this.isLoading,
    this.errorMessage,
  });

  const PreviewNewsletterState.initial()
      : newsletter = null,
        isLoading = true,
        errorMessage = null;

  const PreviewNewsletterState.loading({Newsletter? newsletter})
      : newsletter = newsletter,
        isLoading = true,
        errorMessage = null;

  const PreviewNewsletterState.loaded({required Newsletter newsletter})
      : newsletter = newsletter,
        isLoading = false,
        errorMessage = null;

  const PreviewNewsletterState.failure({
    Newsletter? newsletter,
    required String errorMessage,
  })  : newsletter = newsletter,
        isLoading = false,
        errorMessage = errorMessage;

  final Newsletter? newsletter;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => [newsletter, isLoading, errorMessage];
}
