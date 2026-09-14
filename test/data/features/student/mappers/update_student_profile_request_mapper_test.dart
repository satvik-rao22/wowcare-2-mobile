import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/update_student_profile_request_mapper.dart';
import 'package:wowcare/domain/features/student/entities/update_student_profile_request.dart';

void main() {
  test('includes dob + gender + nested classroom when present', () {
    const request = UpdateStudentProfileRequest(
      firstName: 'Ada',
      lastName: 'Lovelace',
      status: 'ACTIVE',
      dob: '2021-04-02',
      notes: 'n',
      subsidy: true,
      gender: 'FEMALE',
      classroomCode: 'CLS_1',
      classroomName: 'Blue-A',
      schoolCode: 'SCH',
    );

    final body = updateStudentProfileRequestToPayload(request);

    expect(body, <String, dynamic>{
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'status': 'ACTIVE',
      'dob': '2021-04-02',
      'notes': 'n',
      'subsidy': true,
      'gender': 'FEMALE',
      'classroom': {'code': 'CLS_1', 'name': 'Blue-A'},
    });
    expect(body.containsKey('schoolCode'), isFalse);
  });

  test('omits dob + gender when null', () {
    const request = UpdateStudentProfileRequest(
      firstName: 'Ada',
      lastName: 'Lovelace',
      status: 'UPCOMING',
      classroomCode: 'CLS_1',
      classroomName: 'Blue-A',
    );

    final body = updateStudentProfileRequestToPayload(request);

    expect(body.containsKey('dob'), isFalse);
    expect(body.containsKey('gender'), isFalse);
    expect(body['subsidy'], isFalse);
    expect(body['classroom'], {'code': 'CLS_1', 'name': 'Blue-A'});
  });
}
