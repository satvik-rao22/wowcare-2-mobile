import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'subsidies_state.dart';

/// Owns the Subsidies tab's list + search/toggle state. Items are demo data
/// today; swap [_seedSubsidies] for a repository call when billing is wired to
/// a backend.
class SubsidiesCubit extends Cubit<SubsidiesState> {
  SubsidiesCubit() : super(SubsidiesState.initial());

  static List<SubsidyItem> _seedSubsidies() => [
        SubsidyItem(
            subsidyName: 'Food Assistance',
            invoiced: 12,
            received: 30,
            balance: 19),
        SubsidyItem(
            subsidyName: 'Housing vouchers',
            invoiced: 0,
            received: 0,
            balance: 19),
        SubsidyItem(
            subsidyName: 'Federal assistance',
            invoiced: 0,
            received: 0,
            balance: 19),
        SubsidyItem(
            subsidyName: 'Local Community Fund',
            invoiced: 0,
            received: 0,
            balance: 19),
      ];

  /// Any typing turns the "show all" toggle off, matching the original screen.
  void setSearchQuery(String query) {
    emit(state.copyWith(
      searchQuery: query,
      isToggled: state.isToggled ? false : null,
    ));
  }

  void setToggle(bool value) {
    // Toggling clears the search (the view also clears its controller).
    emit(state.copyWith(isToggled: value, searchQuery: ''));
  }

  /// Removes [subsidy] and returns its prior index so the view can offer Undo.
  int deleteSubsidy(SubsidyItem subsidy) {
    final index = state.items.indexOf(subsidy);
    final updated = List<SubsidyItem>.from(state.items)..remove(subsidy);
    emit(state.copyWith(items: updated));
    return index;
  }

  void restoreSubsidy(SubsidyItem subsidy, int index) {
    final updated = List<SubsidyItem>.from(state.items);
    if (index >= 0 && index <= updated.length) {
      updated.insert(index, subsidy);
    } else {
      updated.add(subsidy);
    }
    emit(state.copyWith(items: updated));
  }
}

class SubsidyItem {
  final String subsidyName;
  final num? invoiced;
  final num? received;
  final num? balance;
  SubsidyItem({
    required this.subsidyName,
    this.invoiced,
    this.received,
    this.balance,
  });
}
