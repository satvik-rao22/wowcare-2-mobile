part of 'admin_dashboard_cubit.dart';

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    required this.cards,
    this.userName = 'Sarah Johnson',
  });

  final List<AdminDashboardCard> cards;
  final String userName;

  AdminDashboardState copyWith({
    List<AdminDashboardCard>? cards,
    String? userName,
  }) {
    return AdminDashboardState(
      cards: cards ?? this.cards,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [cards, userName];
}
