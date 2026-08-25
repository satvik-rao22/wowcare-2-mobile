part of 'subsidies_cubit.dart';

class SubsidiesState extends Equatable {
  const SubsidiesState({
    required this.items,
    required this.searchQuery,
    required this.isToggled,
  });

  SubsidiesState.initial()
    : items = SubsidiesCubit._seedSubsidies(),
      searchQuery = '',
      isToggled = false;

  final List<SubsidyItem> items;
  final String searchQuery;
  final bool isToggled;

  /// Items filtered by the active search query. When the "show all" toggle is
  /// on (or the query is empty), every item is shown.
  List<SubsidyItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    if (isToggled || query.isEmpty) return items;
    return items
        .where((subsidy) => subsidy.subsidyName.toLowerCase().contains(query))
        .toList();
  }

  SubsidiesState copyWith({
    List<SubsidyItem>? items,
    String? searchQuery,
    bool? isToggled,
  }) {
    return SubsidiesState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      isToggled: isToggled ?? this.isToggled,
    );
  }

  @override
  List<Object?> get props => [items, searchQuery, isToggled];
}
