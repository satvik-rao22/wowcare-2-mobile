part of 'staff_dashboard_cubit.dart';

class StaffDashboardState extends Equatable {
  const StaffDashboardState({
    required this.cards,
    this.userName = 'Sarah Johnson',
  });

  final List<StaffDashboardCard> cards;
  final String userName;

  StaffDashboardState copyWith({
    List<StaffDashboardCard>? cards,
    String? userName,
  }) {
    return StaffDashboardState(
      cards: cards ?? this.cards,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [cards, userName];
}
