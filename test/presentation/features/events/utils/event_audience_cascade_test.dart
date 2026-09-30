import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/events/utils/event_audience_cascade.dart';

const _roomA = EventAttendee(code: 'CLS_A', name: 'Bumblebees');
const _roomB = EventAttendee(code: 'CLS_B', name: 'Fireflies');

Student _student(String code, String name, String classroom) => Student(
      code: code,
      firstName: name,
      lastName: '',
      status: 'ACTIVE',
      classroom: classroom,
    );

StaffMember _staff(
  String code,
  String name, {
  String primary = '',
  List<String> allowed = const [],
}) =>
    StaffMember(
      code: code,
      name: name,
      primaryClassroomCode: primary,
      allowedClassroomCodes: allowed,
      designation: 'Teacher',
      phoneNumber: '',
      status: 'ACTIVE',
      email: '',
    );

void main() {
  // Student.classroom may hold the classroom name OR code (the students
  // API sends either); staff link via primary/allowed classroom codes.
  final students = [
    _student('STD_1', 'Emma', 'Bumblebees'), // room A by name
    _student('STD_2', 'Liam', 'CLS_A'), // room A by code
    _student('STD_3', 'Ava', 'Fireflies'), // room B
    _student('STD_4', 'Noah', ''), // no classroom
  ];
  final staff = [
    _staff('STF_1', 'Ms. Lee', primary: 'CLS_A'),
    _staff('STF_2', 'Mr. Ray', allowed: ['CLS_A', 'CLS_B']),
    _staff('STF_3', 'Ms. Kim', primary: 'CLS_B'),
  ];

  group('EventAudienceCascade.nextStudents', () {
    test('selecting a classroom pre-selects its students by name or code',
        () {
      final result = EventAudienceCascade.nextStudents(
        current: const [],
        previousClassrooms: const [],
        nextClassrooms: const [_roomA],
        allStudents: students,
      );

      expect(result.map((a) => a.code), ['STD_1', 'STD_2']);
      expect(result.first.name, 'Emma');
    });

    test('deselecting a classroom removes its students but keeps manual picks',
        () {
      const manual = EventAttendee(code: 'STD_4', name: 'Noah');
      final result = EventAudienceCascade.nextStudents(
        current: const [
          EventAttendee(code: 'STD_1', name: 'Emma'),
          EventAttendee(code: 'STD_2', name: 'Liam'),
          manual,
        ],
        previousClassrooms: const [_roomA],
        nextClassrooms: const [],
        allStudents: students,
      );

      expect(result, [manual]);
    });

    test('a manually deselected student is not re-added by another classroom',
        () {
      // Room A picked, Emma toggled off; now room B is added.
      final result = EventAudienceCascade.nextStudents(
        current: const [EventAttendee(code: 'STD_2', name: 'Liam')],
        previousClassrooms: const [_roomA],
        nextClassrooms: const [_roomA, _roomB],
        allStudents: students,
      );

      expect(result.map((a) => a.code), ['STD_2', 'STD_3']);
    });
  });

  group('EventAudienceCascade.nextStaff', () {
    test('selecting a classroom pre-selects its primary and allowed staff',
        () {
      final result = EventAudienceCascade.nextStaff(
        current: const [],
        previousClassrooms: const [],
        nextClassrooms: const [_roomA],
        allStaff: staff,
      );

      expect(result.map((a) => a.code), ['STF_1', 'STF_2']);
    });

    test('staff shared by a still-selected classroom survive a deselection',
        () {
      // Both rooms selected; Mr. Ray is allowed in both. Removing room A
      // must keep him (room B still covers him) but drop Ms. Lee.
      final result = EventAudienceCascade.nextStaff(
        current: const [
          EventAttendee(code: 'STF_1', name: 'Ms. Lee'),
          EventAttendee(code: 'STF_2', name: 'Mr. Ray'),
          EventAttendee(code: 'STF_3', name: 'Ms. Kim'),
        ],
        previousClassrooms: const [_roomA, _roomB],
        nextClassrooms: const [_roomB],
        allStaff: staff,
      );

      expect(result.map((a) => a.code), ['STF_2', 'STF_3']);
    });
  });
}
