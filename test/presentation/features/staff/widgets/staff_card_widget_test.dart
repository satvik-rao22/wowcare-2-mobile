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
// RenderFlex overflow across widths, in BOTH the collapsed layout the roster
// renders by default AND the expanded layout (tapped open) — the expanded
// detail rows (Designation / Phone Number) previously overflowed at narrow
// widths until their value widgets were wrapped in Flexible. A RoleCubit is
// provided because the card reads it to gate the expand-only action row.

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

StaffCard _card({bool expanded = false}) => StaffCard(
  staffCode: 'STF-1',
  name: 'Alice Johnson',
  classroom: 'Sunflower Room',
  allowedClassrooms: const <String>['Sunflower Room', 'Rose Room'],
  schedule: const <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  designation: 'ASSOCIATE_TEACHER',
  // A long value + email exercise the expanded detail rows that used to overflow.
  email: 'alice.johnson.longlocalpart@childcarewow.example.com',
  phoneNumber: '+1 555 010 2020',
  isActive: true,
  status: 'ACTIVE',
  initiallyExpanded: expanded,
  availableClassrooms: const <String>['Sunflower Room', 'Rose Room', 'Tulip Room'],
  classroomCodeByName: const <String, String>{
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

  group('StaffCard collapsed — responsive (no overflow at 320/375/768/1024)', () {
    for (final width in <double>[320, 375, 768, 1024]) {
      testWidgets('lays out with no RenderFlex overflow at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(_host(width: width, child: _card()));
        expect(
          tester.takeException(),
          isNull,
          reason: 'StaffCard (collapsed) overflowed at ${width.toInt()}px',
        );
      });
    }
  });

  group('StaffCard expanded — responsive (no overflow at 320/375/768/1024)', () {
    // The expanded Designation / Email / Phone-Number detail rows put a fixed
    // label beside a value; before the fix the Designation + Phone values were
    // unconstrained and overflowed narrow widths. Their values are now Flexible,
    // so even a long email/designation ellipsizes/wraps instead of overflowing.
    for (final width in <double>[320, 375, 768, 1024]) {
      testWidgets('lays out with no RenderFlex overflow at ${width.toInt()}px', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(width: width, child: _card(expanded: true)),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'StaffCard (expanded) overflowed at ${width.toInt()}px',
        );
      });
    }
  });
}
