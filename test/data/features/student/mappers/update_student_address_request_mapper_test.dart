import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/update_student_address_request_mapper.dart';
import 'package:wowcare/domain/features/student/entities/update_student_address_request.dart';

void main() {
  test('maps to the exact address PATCH body (line1 == street; no schoolCode)',
      () {
    const request = UpdateStudentAddressRequest(
      street: '12 Oak St',
      line2: 'Apt 3',
      city: 'Nashua',
      state: 'NH',
      country: 'US',
      postalCode: '03060',
      addressType: 'CURRENT',
      schoolCode: 'SCH', // hint only — must NOT appear in the body
    );

    final body = updateStudentAddressRequestToPayload(request);

    expect(body, <String, dynamic>{
      'line1': '12 Oak St',
      'line2': 'Apt 3',
      'street': '12 Oak St',
      'city': 'Nashua',
      'state': 'NH',
      'country': 'US',
      'postalCode': '03060',
      'addressType': 'CURRENT',
    });
    expect(body.containsKey('schoolCode'), isFalse);
  });
}
