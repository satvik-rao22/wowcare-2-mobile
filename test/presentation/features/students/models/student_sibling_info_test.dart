import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/students/models/student_sibling_info.dart';

void main() {
  test('defaults to empty lists and isEmpty', () {
    const info = StudentSiblingInfo();
    expect(info.names, isEmpty);
    expect(info.relations, isEmpty);
    expect(info.statuses, isEmpty);
    expect(info.isEmpty, isTrue);
  });

  test('holds index-aligned lists and value-compares', () {
    const a = StudentSiblingInfo(
      names: ['Sam', 'Alex'],
      relations: ['Sibling', 'Sibling'],
      statuses: ['active', 'inactive'],
    );
    const b = StudentSiblingInfo(
      names: ['Sam', 'Alex'],
      relations: ['Sibling', 'Sibling'],
      statuses: ['active', 'inactive'],
    );
    expect(a.names.length, 2);
    expect(a.isEmpty, isFalse);
    expect(a, b);
  });
}
