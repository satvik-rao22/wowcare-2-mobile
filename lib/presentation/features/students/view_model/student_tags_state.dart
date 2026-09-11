part of 'student_tags_cubit.dart';

class StudentTagsState extends Equatable {
  const StudentTagsState({
    required this.mutationInProgress,
    this.errorMessage,
    this.isLoading = false,
    this.availableTagNames = const <String>[],
    this.tagNameToCode = const <String, String>{},
    this.selectedTags = const <String>[],
    this.schoolCode = '',
  });

  const StudentTagsState.initial()
    : mutationInProgress = false,
      errorMessage = null,
      isLoading = false,
      availableTagNames = const <String>[],
      tagNameToCode = const <String, String>{},
      selectedTags = const <String>[],
      schoolCode = '';

  final bool mutationInProgress;
  final String? errorMessage;

  /// The tags edit-sheet model: the load flag, the school's available tags +
  /// their name→code map, the current selection, and the resolved school code.
  /// Owned here so the sheet no longer keeps competing `setState` copies.
  final bool isLoading;
  final List<String> availableTagNames;
  final Map<String, String> tagNameToCode;
  final List<String> selectedTags;
  final String schoolCode;

  StudentTagsState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
    bool? isLoading,
    List<String>? availableTagNames,
    Map<String, String>? tagNameToCode,
    List<String>? selectedTags,
    String? schoolCode,
  }) {
    return StudentTagsState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      availableTagNames: availableTagNames ?? this.availableTagNames,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      selectedTags: selectedTags ?? this.selectedTags,
      schoolCode: schoolCode ?? this.schoolCode,
    );
  }

  @override
  List<Object?> get props => [
    mutationInProgress,
    errorMessage,
    isLoading,
    availableTagNames,
    tagNameToCode,
    selectedTags,
    schoolCode,
  ];
}
