part of 'create_school_user_cubit.dart';

class CreateSchoolUserState extends Equatable {
  const CreateSchoolUserState._({
    required this.isLoading,
    this.result,
    this.errorMessage,
  });

  const CreateSchoolUserState.initial() : this._(isLoading: false);

  const CreateSchoolUserState.loading() : this._(isLoading: true);

  const CreateSchoolUserState.success(CreateSchoolUserResult result)
      : this._(isLoading: false, result: result);

  const CreateSchoolUserState.error(String message)
      : this._(isLoading: false, errorMessage: message);

  final bool isLoading;
  final CreateSchoolUserResult? result;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, result, errorMessage];
}


