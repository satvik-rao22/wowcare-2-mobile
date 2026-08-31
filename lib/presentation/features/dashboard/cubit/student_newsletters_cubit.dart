import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_entity.dart';
import 'package:wowcare/domain/features/newsletter/usecases/get_student_newsletters_usecase.dart';

part 'student_newsletters_state.dart';

class StudentNewslettersCubit extends Cubit<StudentNewslettersState> {
  StudentNewslettersCubit({
    required GetStudentNewslettersUseCase getStudentNewslettersUseCase,
  }) : _getStudentNewslettersUseCase = getStudentNewslettersUseCase,
       super(const StudentNewslettersState.initial());

  final GetStudentNewslettersUseCase _getStudentNewslettersUseCase;

  bool _isFetching = false;

  Future<void> loadFirstPage({
    required String studentCode,
    int size = 10,
    String status = 'SENT',
    bool forceRefresh = false,
    bool background = false,
  }) async {
    final code = studentCode.trim();
    if (code.isEmpty) {
      emit(const StudentNewslettersState.initial());
      return;
    }

    if (!forceRefresh &&
        state.status == StudentNewslettersStatus.loaded &&
        state.selectedChildCode == code) {
      return;
    }

    if (_isFetching) return;
    // Keep the loaded list visible during a background refresh (no shimmer).
    final hasData = state.status == StudentNewslettersStatus.loaded &&
        state.selectedChildCode == code;
    _isFetching = true;
    if (!(background && hasData)) {
      emit(
        state.copyWith(
          status: StudentNewslettersStatus.loading,
          selectedChildCode: code,
          errorMessage: '',
          currentPage: 0,
          hasMore: true,
          isPaginationLoading: false,
        ),
      );
    }

    try {
      final result = await _getStudentNewslettersUseCase(
        studentCode: code,
        page: 0,
        size: size,
        status: status,
      );
      result.fold(
        (failure) {
          // Keep stale data on a failed background refresh.
          if (background && hasData) return;
          emit(
            state.copyWith(
              status: StudentNewslettersStatus.error,
              errorMessage: failure.message ?? 'Failed to load newsletters',
            ),
          );
        },
        (page) => emit(
          state.copyWith(
            status: StudentNewslettersStatus.loaded,
            selectedChildCode: code,
            items: page.items,
            currentPage: page.page,
            pageSize: page.size,
            totalPages: page.totalPages,
            totalElements: page.totalElements,
            hasMore: page.hasMore,
            errorMessage: '',
          ),
        ),
      );
    } catch (e) {
      // Keep stale data on a failed background refresh.
      if (!(background && hasData)) {
        emit(
          state.copyWith(
            status: StudentNewslettersStatus.error,
            errorMessage: ApiErrorHandler.extractErrorMessage(e),
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore({String status = 'SENT'}) async {
    if (_isFetching) return;
    if (state.status != StudentNewslettersStatus.loaded) return;
    if (!state.hasMore) return;
    final code = state.selectedChildCode.trim();
    if (code.isEmpty) return;

    _isFetching = true;
    emit(state.copyWith(isPaginationLoading: true, errorMessage: ''));
    final nextPage = state.currentPage + 1;

    try {
      final result = await _getStudentNewslettersUseCase(
        studentCode: code,
        page: nextPage,
        size: state.pageSize,
        status: status,
      );
      result.fold(
        (failure) => emit(
          state.copyWith(
            isPaginationLoading: false,
            errorMessage: failure.message ?? 'Failed to load more newsletters',
          ),
        ),
        (page) => emit(
          state.copyWith(
            items: [...state.items, ...page.items],
            currentPage: page.page,
            pageSize: page.size,
            totalPages: page.totalPages,
            totalElements: page.totalElements,
            hasMore: page.hasMore,
            isPaginationLoading: false,
            errorMessage: '',
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isPaginationLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    } finally {
      _isFetching = false;
    }
  }
}
