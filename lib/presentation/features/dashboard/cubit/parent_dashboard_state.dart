part of 'parent_dashboard_cubit.dart';

class ParentDashboardState extends Equatable {
  const ParentDashboardState({
    required this.cards,
    this.userName = 'Jessica Johnson',
  });

  final List<ParentDashboardCard> cards;
  final String userName;

  ParentDashboardState copyWith({
    List<ParentDashboardCard>? cards,
    String? userName,
  }) {
    return ParentDashboardState(
      cards: cards ?? this.cards,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [cards, userName];
}
