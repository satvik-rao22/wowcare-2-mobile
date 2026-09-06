import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/student_health_update_request_mapper.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';

void main() {
  test('studentHealthUpdateRequestToPayload shapes the exact body', () {
    const request = StudentHealthUpdateRequest(
      allergy: 'Peanuts',
      medications: 'Inhaler',
      dietRestrictions: 'Vegetarian',
      photoPermission: true,
    );

    final payload = studentHealthUpdateRequestToPayload(request);

    expect(payload, <String, dynamic>{
      'allergy': 'Peanuts',
      'medications': 'Inhaler',
      'dietRestrictions': 'Vegetarian',
      'photoPermission': true,
    });
  });
}
