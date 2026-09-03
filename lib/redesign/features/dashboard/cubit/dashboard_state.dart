part of 'dashboard_cubit.dart';

enum DashboardStatus { loading, ready, failed }

@immutable
class DashboardState extends Equatable {
  const DashboardState({
    required this.persona,
    this.status = DashboardStatus.loading,
    this.snapshot = const DashboardSnapshot(),
    this.selectedChildId,
    this.isMyDayOpen = true,
    this.isWorking = false,
  });

  final Persona persona;
  final DashboardStatus status;
  final DashboardSnapshot snapshot;

  /// Which of a guardian's students the day card is showing.
  final String? selectedChildId;

  /// 3A1 collapses My day; 3S1 leaves it open, because it is the screen.
  final bool isMyDayOpen;

  /// An action is in flight: a sign out, a transfer, an absence.
  final bool isWorking;

  bool get isLoading => status == DashboardStatus.loading;
  bool get isFailed => status == DashboardStatus.failed;

  ChildDay? get selectedChild {
    final children = snapshot.children;
    if (children.isEmpty) return null;
    for (final child in children) {
      if (child.id == selectedChildId) return child;
    }
    return children.first;
  }

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSnapshot? snapshot,
    String? selectedChildId,
    bool? isMyDayOpen,
    bool? isWorking,
  }) => DashboardState(
    persona: persona,
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    selectedChildId: selectedChildId ?? this.selectedChildId,
    isMyDayOpen: isMyDayOpen ?? this.isMyDayOpen,
    isWorking: isWorking ?? this.isWorking,
  );

  @override
  List<Object?> get props => [
    persona,
    status,
    snapshot,
    selectedChildId,
    isMyDayOpen,
    isWorking,
  ];
}
