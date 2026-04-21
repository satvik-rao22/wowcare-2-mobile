import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class BulkMessagingSelectionState extends Equatable {
  final Set<String> selectedRecipientIds;
  final List<String> selectedClassrooms;
  final String? selectedStatus;
  final List<String> selectedDesignations;
  final List<String> selectedTags;
  final String searchQuery;

  const BulkMessagingSelectionState({
    this.selectedRecipientIds = const {},
    this.selectedClassrooms = const [],
    this.selectedStatus,
    this.selectedDesignations = const [],
    this.selectedTags = const [],
    this.searchQuery = '',
  });

  BulkMessagingSelectionState copyWith({
    Set<String>? selectedRecipientIds,
    List<String>? selectedClassrooms,
    String? selectedStatus,
    List<String>? selectedDesignations,
    List<String>? selectedTags,
    String? searchQuery,
    bool clearStatus = false,
  }) {
    return BulkMessagingSelectionState(
      selectedRecipientIds: selectedRecipientIds ?? this.selectedRecipientIds,
      selectedClassrooms: selectedClassrooms ?? this.selectedClassrooms,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedDesignations: selectedDesignations ?? this.selectedDesignations,
      selectedTags: selectedTags ?? this.selectedTags,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    selectedRecipientIds,
    selectedClassrooms,
    selectedStatus,
    selectedDesignations,
    selectedTags,
    searchQuery,
  ];
}

class BulkMessagingSelectionCubit extends Cubit<BulkMessagingSelectionState> {
  BulkMessagingSelectionCubit() : super(const BulkMessagingSelectionState());

  void toggleRecipient(String id) {
    final current = Set<String>.from(state.selectedRecipientIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    emit(state.copyWith(selectedRecipientIds: current));
  }

  void selectAll(List<String> ids) {
    final current = Set<String>.from(state.selectedRecipientIds);
    current.addAll(ids);
    emit(state.copyWith(selectedRecipientIds: current));
  }

  void deselectAll(List<String> ids) {
    final current = Set<String>.from(state.selectedRecipientIds);
    for (var id in ids) {
      current.remove(id);
    }
    emit(state.copyWith(selectedRecipientIds: current));
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void updateFilters({
    List<String>? classrooms,
    String? status,
    List<String>? designations,
    List<String>? tags,
    bool clearStatus = false,
  }) {
    emit(
      state.copyWith(
        selectedClassrooms: classrooms,
        selectedStatus: status,
        selectedDesignations: designations,
        selectedTags: tags,
        clearStatus: clearStatus,
      ),
    );
  }

  void clearAll() {
    emit(const BulkMessagingSelectionState());
  }
}
