import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// The `/users/details` module permissions are the outer gate on Events,
/// Holidays, RSVP, Calendar and Tasks: a persona that would otherwise be
/// allowed must still be denied when the backend withholds the module.

class _NullStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// RoleCubit double with a fixed persona and an explicit grant table, so the
/// async bootstrap can't influence the assertions.
class _Roles extends RoleCubit {
  _Roles(this._role, {this.read = const {}, this.write = const {}});

  final String _role;
  final Set<String> read;
  final Set<String> write;

  @override
  String get role => _role;
  @override
  bool get isParent => _role == 'parent';
  @override
  bool get isAdmin => _role == 'admin' || _role == 'staff';
  @override
  bool get isStaff => _role == 'staff';

  @override
  bool canReadModule(String module) =>
      read.contains(module) || write.contains(module);
  @override
  bool canWriteModule(String module) => write.contains(module);
  @override
  bool canOpenModule(String module) => canReadModule(module);
  @override
  bool canAccessAny(List<String> modules) => modules.any(canReadModule);
}

Event _event({String createdBy = 'STF_ME', bool includeParents = false}) =>
    Event(
  includeParents: includeParents,
  code: 'EVT_1',
  type: EventType.classroom,
  name: 'E',
  date: DateTime(2026, 7, 15),
  allDay: false,
  createdBy: createdBy,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Task _task({String createdBy = 'STF_ME'}) => Task(
  code: 'TSA_1',
  taskCode: 'TSK_1',
  title: 'T',
  assigneeCode: createdBy,
  createdBy: createdBy,
  startDate: DateTime(2026, 7, 15),
  dueDate: DateTime(2026, 7, 17),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  // RoleCubit resolves StorageService from the locator during construction.
  if (!GetIt.I.isRegistered<StorageService>()) {
    GetIt.I.registerSingleton<StorageService>(_NullStorage());
  }

  group('Events module gate', () {
    test('read-only EVENT hides create and blocks manage', () {
      final staff = _Roles('staff', read: {AppAccessModules.event});

      expect(EventAccess.canOpenModule(staff), isTrue);
      expect(EventAccess.canCreateEvents(staff), isFalse);
      expect(
        EventAccess.canManageEvent(
          roles: staff,
          event: _event(),
          userCode: 'STF_ME',
        ),
        isFalse,
      );
    });

    test('EVENT write restores the persona rules underneath', () {
      final staff = _Roles('staff', write: {AppAccessModules.event});

      expect(EventAccess.canCreateEvents(staff), isTrue);
      // Own event: allowed. Someone else's: still denied by PRD §5.1.
      expect(
        EventAccess.canManageEvent(
          roles: staff,
          event: _event(),
          userCode: 'STF_ME',
        ),
        isTrue,
      );
      expect(
        EventAccess.canManageEvent(
          roles: staff,
          event: _event(createdBy: 'STF_OTHER'),
          userCode: 'STF_ME',
        ),
        isFalse,
      );
    });

    test('no Events modules at all closes the screen', () {
      expect(EventAccess.canOpenModule(_Roles('admin')), isFalse);
    });
  });

  group('Holiday and RSVP gates', () {
    test('admin without HOLIDAY write cannot manage holidays', () {
      final admin = _Roles('admin', read: {AppAccessModules.holiday});
      expect(EventAccess.canManageHolidays(admin), isFalse);

      final writer = _Roles('admin', write: {AppAccessModules.holiday});
      expect(EventAccess.canManageHolidays(writer), isTrue);
    });

    test('RSVP summary needs EVENT_RSVP read as well as admin', () {
      expect(EventAccess.canSeeRsvpSummary(_Roles('admin')), isFalse);
      expect(
        EventAccess.canSeeRsvpSummary(
          _Roles('admin', read: {AppAccessModules.eventRsvp}),
        ),
        isTrue,
      );
    });

    test('staff RSVP needs EVENT_RSVP write; parents keep the invite rule', () {
      final staff = _Roles('staff', read: {AppAccessModules.eventRsvp});
      expect(
        EventAccess.canRsvp(roles: staff, event: _event(), userCode: 'STF_ME'),
        isFalse,
      );

      final writer = _Roles('staff', write: {AppAccessModules.eventRsvp});
      expect(
        EventAccess.canRsvp(roles: writer, event: _event(), userCode: 'STF_ME'),
        isTrue,
      );

      // Parents are governed by includeParents alone — no module row needed.
      final parent = _Roles('parent');
      expect(
        EventAccess.canRsvp(
          roles: parent,
          event: _event(),
          userCode: 'PAR_1',
        ),
        isFalse,
      );
      expect(
        EventAccess.canRsvp(
          roles: parent,
          event: _event(includeParents: true),
          userCode: 'PAR_1',
        ),
        isTrue,
      );
    });
  });

  group('Tasks module gate', () {
    test('staff without TASK loses the module, create and manage', () {
      final staff = _Roles('staff');

      expect(TaskAccess.canAccessModule(staff), isFalse);
      expect(TaskAccess.canCreateTasks(staff), isFalse);
      expect(
        TaskAccess.canViewTask(
          roles: staff,
          task: _task(),
          userCode: 'STF_ME',
        ),
        isFalse,
      );
    });

    test('TASK read opens the module but not writes', () {
      final staff = _Roles('staff', read: {AppAccessModules.task});

      expect(TaskAccess.canAccessModule(staff), isTrue);
      expect(TaskAccess.canCreateTasks(staff), isFalse);
      expect(
        TaskAccess.canViewTask(
          roles: staff,
          task: _task(),
          userCode: 'STF_ME',
        ),
        isTrue,
      );
      expect(
        TaskAccess.canManageTask(
          roles: staff,
          task: _task(),
          userCode: 'STF_ME',
        ),
        isFalse,
      );
    });
  });

  group('Calendar feed kinds', () {
    test('each row kind needs its own module', () {
      final roles = _Roles(
        'admin',
        read: {AppAccessModules.calendar, AppAccessModules.event},
      );

      // CALENDAR read alone must not leak task or holiday rows.
      expect(
        EventAccess.readableCalendarKinds(roles),
        <CalendarFeedKind>{CalendarFeedKind.event},
      );
    });

    test('all three modules yield all three kinds', () {
      final roles = _Roles(
        'admin',
        read: {
          AppAccessModules.event,
          AppAccessModules.holiday,
          AppAccessModules.task,
        },
      );

      expect(EventAccess.readableCalendarKinds(roles), <CalendarFeedKind>{
        CalendarFeedKind.event,
        CalendarFeedKind.holiday,
        CalendarFeedKind.task,
      });
    });
  });
}
