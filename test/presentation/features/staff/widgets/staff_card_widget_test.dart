import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart' show serviceLocator;
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_card.dart';

// StaffCard is the roster list card for a staff member. Its build reads a
// RoleCubit from context to gate the write actions, and its initState kicks off
// a school-open-days load via the service locator — but that load returns early
// once the (empty) school code is read, and the card falls back to its default
// day labels. These smoke + responsive tests pin that the card lays out without
// RenderFlex overflow across widths, in the collapsed layout the roster
// actually renders (the roster builds every card with initiallyExpanded=false;
// a RoleCubit is still provided because the card reads it to gate the
// expand-only action row).

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

StaffCard _card() => const StaffCard(
  staffCode: 'STF-1',
  name: 'Alice Johnson',
  classroom: 'Sunflower Room',
  allowedClassrooms: <String>['Sunflower Room', 'Rose Room'],
  schedule: <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  designation: 'ASSOCIATE_TEACHER',
  phoneNumber: '+1 555 010 2020',
  isActive: true,
  status: 'ACTIVE',
  availableClassrooms: <String>['Sunflower Room', 'Rose Room', 'Tulip Room'],
  classroomCodeByName: <String, String>{
    'Sunflower Room': 'CLS-1',
    'Rose Room': 'CLS-2',
    'Tulip Room': 'CLS-3',
  },
);

Widget _host({required double width, required Widget child}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: BlocProvider<RoleCubit>(
      create: (_) => _MockRoleCubit(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
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

  testWidgets('StaffCard renders the staff name', (tester) async {
    await tester.pumpWidget(_host(width: 400, child: _card()));
    expect(find.textContaining('Alice Johnson'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('StaffCard — responsive (no overflow at 320/768/1024)', () {
    for (final width in <double>[320, 375, 768, 1024]) {
      testWidgets('lays out with no RenderFlex overflow at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(_host(width: width, child: _card()));
        expect(
          tester.takeException(),
          isNull,
          reason: 'StaffCard overflowed at ${width.toInt()}px',
        );
      });
    }
  });
}
