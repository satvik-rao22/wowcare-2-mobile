import 'package:bloc/bloc.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart' show serviceLocator;
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/students/widgets/student_card.dart';

// StudentCard is the roster list card. It reads a RoleCubit from context for
// permission-gated buttons, and its initState kicks off a school-open-days load
// via the service locator — but that load returns early once the (empty) school
// code is read, and the card falls back gracefully. These smoke + responsive
// tests pin that the card lays out without RenderFlex overflow across widths.

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Minimal RoleCubit stand-in: admin persona that may write (so the card shows
/// its full action set — the densest layout to overflow-test).
class _MockRoleCubit extends Cubit<RoleState> implements RoleCubit {
  _MockRoleCubit() : super(const RoleState(role: 'admin'));
  @override
  bool get isStaff => false;
  @override
  bool canWriteModule(String module) => true;
  @override
  bool canReadModule(String module) => true;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

StudentCard _card() => StudentCard(
  studentCode: 'STU-1',
  name: 'Alice Johnson',
  classroom: 'Sunflower Room',
  tags: const ['Allergy', 'VIP'],
  sibling: const StudentSiblingInfo(),
  schedule: const ['MON', 'TUE', 'WED', 'THU', 'FRI'],
  birthDate: '2020-01-15',
  movementDate: '2024-09-01',
  status: 'ACTIVE',
  isActive: true,
);

Widget _host({required double width, required Widget child}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: BlocProvider<RoleCubit>(
      create: (_) => _MockRoleCubit(),
      child: Scaffold(body: SizedBox(width: width, child: child)),
    ),
  ),
);

void main() {
  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerFactory<StorageService>(() => _FakeStorage());
  });

  tearDown(() async {
    await serviceLocator.reset();
  });

  testWidgets('StudentCard renders the student name', (tester) async {
    await tester.pumpWidget(_host(width: 400, child: _card()));
    expect(find.textContaining('Alice Johnson'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('StudentCard — responsive (no overflow at 375/768/1024)', () {
    for (final width in <double>[375, 768, 1024]) {
      testWidgets('lays out with no RenderFlex overflow at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(_host(width: width, child: _card()));
        expect(
          tester.takeException(),
          isNull,
          reason: 'StudentCard overflowed at ${width.toInt()}px',
        );
      });
    }
  });
}
