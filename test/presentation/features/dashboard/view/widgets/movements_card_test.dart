import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/movements_card.dart';

class MockIndividualMovementsCubit extends Cubit<IndividualMovementsState> implements IndividualMovementsCubit {
  MockIndividualMovementsCubit() : super(const IndividualMovementsState.initial());
  
  void setBoard(IndividualMovementBoard board) {
    emit(IndividualMovementsState.loaded(board: board, isFromCache: false));
  }

  @override
  Future<void> refresh({List<String>? studentCodes, List<String>? fromClassroomCodes, List<String>? toClassroomCodes, DateTime? dateFrom, DateTime? dateTo, List<String>? status}) async {}
  
  @override
  Future<void> init() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('MovementsCard displays statuses in Overdue -> Confirmed -> Upcoming order', (WidgetTester tester) async {
    final cubit = MockIndividualMovementsCubit();
    
    final now = DateTime.now();
    final overdueMovement = IndividualMovement(
      id: 1,
      code: 'code1',
      studentCode: 'S1',
      studentName: 'Student 1',
      studentAvatarInitials: 'S1',
      fromClassroomCode: 'C1',
      fromClassroomName: 'Class 1',
      toClassroomCode: 'C2',
      toClassroomName: 'Class 2',
      movementDate: now.subtract(const Duration(days: 5)),
      movementType: IndividualMovementType.moveToNextClassroom,
      status: IndividualMovementWorkflowStatus.confirmed,
      source: 'test',
      comment: '',
      bucket: 'overdue',
    );
    
    final confirmedMovement = IndividualMovement(
      id: 2,
      code: 'code2',
      studentCode: 'S2',
      studentName: 'Student 2',
      studentAvatarInitials: 'S2',
      fromClassroomCode: 'C1',
      fromClassroomName: 'Class 1',
      toClassroomCode: 'C2',
      toClassroomName: 'Class 2',
      movementDate: now.subtract(const Duration(days: 1)),
      movementType: IndividualMovementType.moveToNextClassroom,
      status: IndividualMovementWorkflowStatus.confirmed,
      source: 'test',
      comment: '',
      bucket: 'confirmed',
    );

    final upcomingMovement = IndividualMovement(
      id: 3,
      code: 'code3',
      studentCode: 'S3',
      studentName: 'Student 3',
      studentAvatarInitials: 'S3',
      fromClassroomCode: 'C1',
      fromClassroomName: 'Class 1',
      toClassroomCode: 'C2',
      toClassroomName: 'Class 2',
      movementDate: now.add(const Duration(days: 2)),
      movementType: IndividualMovementType.moveToNextClassroom,
      status: IndividualMovementWorkflowStatus.confirmed,
      source: 'test',
      comment: '',
      bucket: 'upcoming',
    );

    final board = IndividualMovementBoard(
      overdue: [overdueMovement],
      upcoming: [upcomingMovement],
      confirmed: [confirmedMovement],
      rejected: [],
    );

    cubit.setBoard(board);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<IndividualMovementsCubit>.value(
          value: cubit,
          child: const Scaffold(body: MovementsCard()),
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    final overdueFinder = find.text('Overdue');
    final confirmedFinder = find.text('Confirmed');
    final upcomingFinder = find.text('Upcoming');

    expect(overdueFinder, findsOneWidget);
    expect(confirmedFinder, findsOneWidget);
    expect(upcomingFinder, findsOneWidget);
    
    // Verify vertical ordering by finding Y coordinates
    final overdueY = tester.getTopLeft(overdueFinder).dy;
    final confirmedY = tester.getTopLeft(confirmedFinder).dy;
    final upcomingY = tester.getTopLeft(upcomingFinder).dy;
    
    expect(overdueY < confirmedY, isTrue, reason: 'Overdue should be above Confirmed');
    expect(confirmedY < upcomingY, isTrue, reason: 'Confirmed should be above Upcoming');
  });
}
