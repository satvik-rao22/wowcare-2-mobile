import 'individual_movement.dart';

class IndividualMovementBoard {
  const IndividualMovementBoard({
    required this.overdue,
    required this.upcoming,
    required this.confirmed,
    required this.rejected,
  });

  final List<IndividualMovement> overdue;
  final List<IndividualMovement> upcoming;
  final List<IndividualMovement> confirmed;
  final List<IndividualMovement> rejected;

  List<IndividualMovement> get all => <IndividualMovement>[
    ...overdue,
    ...upcoming,
    ...confirmed,
    ...rejected,
  ];
}
