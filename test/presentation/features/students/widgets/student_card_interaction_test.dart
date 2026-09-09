import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart' show serviceLocator;
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/presentation/features/students/widgets/student_card.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';

/// StudentCard reads a RoleCubit from context for permission-gated action
/// buttons and kicks off a school-open-days load via the service locator (which
/// returns early on the empty school code). No production API/network is hit.

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _RoleCubit extends Cubit<RoleState> implements RoleCubit {
  _RoleCubit({required this.write}) : super(const RoleState(role: 'admin'));
  final bool write;
  @override
  bool get isStaff => false;
  @override
  bool canWriteModule(String module) => write;
  @override
  bool canReadModule(String module) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host({required Widget child, bool write = true, double width = 500}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 1000)),
        child: BlocProvider<RoleCubit>(
          create: (_) => _RoleCubit(write: write),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

StudentCard _card({
  required bool isActive,
  String status = 'ACTIVE',
  bool expanded = false,
  VoidCallback? onPrimaryAction,
  VoidCallback? onDeleteAction,
  VoidCallback? onEdit,
}) => StudentCard(
  studentCode: 'STU-1',
  name: 'Alice Johnson',
  classroom: 'Sunflower Room',
  tags: const ['Allergy'],
  sibling: const StudentSiblingInfo(),
  schedule: const ['MON', 'TUE'],
  birthDate: '2020-01-15',
  movementDate: '2024-09-01',
  status: status,
  isActive: isActive,
  initiallyExpanded: expanded,
  onPrimaryAction: onPrimaryAction,
  onDeleteAction: onDeleteAction,
  onEdit: onEdit,
);

void main() {
  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerFactory<StorageService>(() => _FakeStorage());
  });
  tearDown(() async => serviceLocator.reset());

  testWidgets('tapping a collapsed card expands it to reveal actions', (
    tester,
  ) async {
    await tester.pumpWidget(_host(child: _card(isActive: true)));
    await tester.pump();

    // Collapsed: the action buttons are not shown yet.
    expect(find.text(StudentStrings.deactivate), findsNothing);

    await tester.tap(find.text('Alice Johnson'));
    await tester.pumpAndSettle();

    // Expanded: the active-student actions appear.
    expect(find.text(StudentStrings.deactivate), findsOneWidget);
    expect(find.text(StudentStrings.edit), findsOneWidget);
  });

  testWidgets('active student shows Deactivate + Edit, not Reactivate/Delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(child: _card(isActive: true, expanded: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text(StudentStrings.deactivate), findsOneWidget);
    expect(find.text(StudentStrings.edit), findsOneWidget);
    expect(find.text(StudentStrings.reactivate), findsNothing);
    expect(find.text(StudentStrings.delete), findsNothing);
  });

  testWidgets('inactive student shows Reactivate + Delete + Edit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(child: _card(isActive: false, status: 'INACTIVE', expanded: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text(StudentStrings.reactivate), findsOneWidget);
    expect(find.text(StudentStrings.delete), findsOneWidget);
    expect(find.text(StudentStrings.edit), findsOneWidget);
    expect(find.text(StudentStrings.deactivate), findsNothing);
  });

  testWidgets('a read-only role hides the write actions', (tester) async {
    await tester.pumpWidget(
      _host(write: false, child: _card(isActive: true, expanded: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text(StudentStrings.deactivate), findsNothing);
    expect(find.text(StudentStrings.edit), findsNothing);
  });

  testWidgets(
    'Deactivate is guarded — it opens a confirmation sheet, not a direct call',
    (tester) async {
      var deactivated = false;
      await tester.pumpWidget(
        _host(
          child: _card(
            isActive: true,
            expanded: true,
            onPrimaryAction: () => deactivated = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(StudentStrings.deactivate));
      await tester.pumpAndSettle();

      // A confirmation sheet is shown; the callback must NOT have fired yet.
      expect(find.byType(DeleteConfirmationBottomSheet), findsOneWidget);
      expect(deactivated, isFalse);
    },
  );

  testWidgets('Edit fires its callback directly', (tester) async {
    var edited = false;
    await tester.pumpWidget(
      _host(
        child: _card(
          isActive: true,
          expanded: true,
          onEdit: () => edited = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(StudentStrings.edit));
    await tester.pump();
    expect(edited, isTrue);
  });
}
