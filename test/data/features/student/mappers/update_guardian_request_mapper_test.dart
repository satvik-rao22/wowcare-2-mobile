import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/update_guardian_request_mapper.dart';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';

void main() {
  test('custody flow: omits code / relationshipDescription / updatedBy', () {
    const request = UpdateGuardianRequest(
      userCode: 'U1',
      schoolCode: 'SCH',
      studentCode: 'S1',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@x.com',
      mobile: '5551234567',
      relationToStudent: 'MOTHER',
      primaryContact: true,
      legalCustody: true,
    );

    final body = updateGuardianRequestToPayload(request);

    expect(body, <String, dynamic>{
      'userCode': 'U1',
      'schoolCode': 'SCH',
      'studentCode': 'S1',
      'firstName': 'Jane',
      'lastName': 'Doe',
      'email': 'jane@x.com',
      'mobile': '5551234567',
      'relationToStudent': 'MOTHER',
      'primaryContact': true,
      'legalCustody': true,
    });
  });

  test('edit-guardian flow: includes code / relationshipDescription / updatedBy',
      () {
    const request = UpdateGuardianRequest(
      userCode: 'U1',
      code: 'G1',
      schoolCode: 'SCH',
      studentCode: 'S1',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@x.com',
      mobile: '5551234567',
      relationToStudent: 'OTHER',
      relationshipDescription: 'Aunt',
      primaryContact: false,
      legalCustody: false,
      updatedBy: 'STAFF9',
    );

    final body = updateGuardianRequestToPayload(request);

    expect(body['code'], 'G1');
    expect(body['relationshipDescription'], 'Aunt');
    expect(body['updatedBy'], 'STAFF9');
    expect(body['primaryContact'], isFalse);
    expect(body['legalCustody'], isFalse);
  });
}
