import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_ledger_usecase.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';

part 'ledger_form_state.dart';

enum LedgerFormStatus { invalid, success, error }

class LedgerFormResult {
  const LedgerFormResult(this.status, this.ledger);

  final LedgerFormStatus status;
  final LedgerAccountModel? ledger;
}

class LedgerFormCubit extends Cubit<LedgerFormState> {
  LedgerFormCubit({
    String? initialCategory,
    required CreateLedgerUseCase createLedgerUseCase,
    required UpdateLedgerUseCase updateLedgerUseCase,
    required StorageService storageService,
  })  : _createLedgerUseCase = createLedgerUseCase,
        _updateLedgerUseCase = updateLedgerUseCase,
        _storageService = storageService,
        super(LedgerFormState.initial(initialCategory));

  final CreateLedgerUseCase _createLedgerUseCase;
  final UpdateLedgerUseCase _updateLedgerUseCase;
  final StorageService _storageService;

  void setCategory(String? value) {
    emit(state.copyWith(selectedCategory: () => value, categoryError: false));
  }

  /// Validates and saves the ledger via the API.
  /// When [original] is null a new ledger is created; otherwise it is updated.
  Future<LedgerFormResult> submit({
    LedgerAccountModel? original,
    required String title,
    required String description,
  }) async {
    final titleError = title.trim().isEmpty;
    final categoryError = state.selectedCategory == null;
    emit(state.copyWith(titleError: titleError, categoryError: categoryError));
    if (titleError || categoryError) {
      return const LedgerFormResult(LedgerFormStatus.invalid, null);
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final org =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';
      final school =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';

      final params = CreateLedgerParams(
        name: title.trim(),
        organization: org,
        school: school,
        category: state.selectedCategory,
        description:
            description.trim().isEmpty ? null : description.trim(),
      );

      final LedgerEntity entity;
      if (original == null) {
        entity = await _createLedgerUseCase(params);
      } else {
        entity = await _updateLedgerUseCase(
          ledgerCode: original.id,
          params: params,
        );
      }

      if (isClosed) return const LedgerFormResult(LedgerFormStatus.error, null);
      return LedgerFormResult(
        LedgerFormStatus.success,
        LedgerAccountModel.fromEntity(entity),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return const LedgerFormResult(LedgerFormStatus.error, null);
    } finally {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
    }
  }
}
