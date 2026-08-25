import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/discount_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/create_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/update_discount_usecase.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/discount_account_model.dart';

part 'discount_form_state.dart';

class DiscountFormCubit extends Cubit<DiscountFormState> {
  DiscountFormCubit({
    required CreateDiscountUseCase createDiscountUseCase,
    required UpdateDiscountUseCase updateDiscountUseCase,
    required StorageService storageService,
  }) : _createDiscountUseCase = createDiscountUseCase,
       _updateDiscountUseCase = updateDiscountUseCase,
       _storageService = storageService,
       super(const DiscountFormState());

  final CreateDiscountUseCase _createDiscountUseCase;
  final UpdateDiscountUseCase _updateDiscountUseCase;
  final StorageService _storageService;

  Future<DiscountFormResult> submit({
    required String name,
    required String percentageStr,
    String? description,
    DiscountAccountModel? original,
  }) async {
    final nameTrimmed = name.trim();
    final pct = double.tryParse(percentageStr.trim()) ?? -1;
    final nameErr = nameTrimmed.isEmpty;
    final pctErr = pct < 0 || pct > 100;

    if (nameErr || pctErr) {
      emit(state.copyWith(nameError: nameErr, percentageError: pctErr));
      return const DiscountFormResult(status: DiscountFormStatus.invalid);
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        nameError: false,
        percentageError: false,
      ),
    );

    try {
      final school =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      final params = CreateDiscountParams(
        name: nameTrimmed,
        school: school,
        percentage: pct,
        description: description?.trim().isEmpty == true
            ? null
            : description?.trim(),
      );

      DiscountEntity entity;
      if (original == null) {
        entity = await _createDiscountUseCase(params);
      } else {
        entity = await _updateDiscountUseCase(
          code: original.code,
          params: params,
        );
      }

      if (isClosed)
        return const DiscountFormResult(status: DiscountFormStatus.error);
      emit(state.copyWith(isSubmitting: false));
      return DiscountFormResult(
        status: DiscountFormStatus.success,
        discount: DiscountAccountModel.fromEntity(entity),
      );
    } catch (_) {
      if (isClosed)
        return const DiscountFormResult(status: DiscountFormStatus.error);
      emit(state.copyWith(isSubmitting: false));
      return const DiscountFormResult(status: DiscountFormStatus.error);
    }
  }
}
