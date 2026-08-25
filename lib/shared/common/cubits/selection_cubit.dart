import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class SelectionState<T> extends Equatable {
  final Set<T> selectedItems;

  const SelectionState({required this.selectedItems});

  SelectionState<T> copyWith({Set<T>? selectedItems}) {
    return SelectionState<T>(
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }

  @override
  List<Object?> get props => [selectedItems];
}

class SelectionCubit<T> extends Cubit<SelectionState<T>> {
  SelectionCubit({Set<T>? initialSelection})
    : super(SelectionState<T>(selectedItems: initialSelection ?? <T>{}));

  void toggle(T item) {
    final current = Set<T>.from(state.selectedItems);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    emit(state.copyWith(selectedItems: current));
  }

  void selectAll(List<T> visibleItems) {
    final current = Set<T>.from(state.selectedItems);
    current.addAll(visibleItems);
    emit(state.copyWith(selectedItems: current));
  }

  void deselectAll(List<T> visibleItems) {
    final current = Set<T>.from(state.selectedItems);
    for (var item in visibleItems) {
      current.remove(item);
    }
    emit(state.copyWith(selectedItems: current));
  }

  void toggleAll(List<T> visibleItems) {
    if (isAllSelected(visibleItems)) {
      deselectAll(visibleItems);
    } else {
      selectAll(visibleItems);
    }
  }

  bool isSelected(T item) => state.selectedItems.contains(item);

  bool isAllSelected(List<T> visibleItems) {
    if (visibleItems.isEmpty) return false;
    return visibleItems.every((item) => state.selectedItems.contains(item));
  }

  bool isAnySelected(List<T> visibleItems) {
    return visibleItems.any((item) => state.selectedItems.contains(item));
  }

  void clear() {
    emit(SelectionState<T>(selectedItems: <T>{}));
  }
}
