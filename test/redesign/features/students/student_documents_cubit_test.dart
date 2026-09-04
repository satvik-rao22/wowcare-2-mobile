import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/students/cubit/student_documents_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';

import 'students_test_doubles.dart';

void main() {
  late FakeStudentsSource source;

  StudentDocumentsCubit build({String name = 'Aria Rowan'}) =>
      StudentDocumentsCubit(
        source: source,
        args: StudentDocumentsArgs(
          studentId: 'aria',
          studentName: name,
          classroomName: 'Sunflower',
        ),
      );

  setUp(() {
    source = FakeStudentsSource(
      documents: <StudentDocumentItem>[
        const StudentDocumentItem(
          id: 'doc-enrollment',
          name: 'Enrollment form',
          type: 'Registration Forms',
          kind: DocumentKind.pdf,
          detail: 'Registration Forms · 4 Sep 2025',
        ),
      ],
      picked: const PickedFile(
        name: 'exam-mar-2026.pdf',
        kind: DocumentKind.pdf,
        sizeKb: 1843,
      ),
    );
  });

  group('StudentDocumentsCubit', () {
    test('loads what is on file', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, DocumentsStatus.ready);
      expect(cubit.state.documents.length, 1);
      expect(cubit.state.upload, UploadStatus.idle);
      await cubit.close();
    });

    test(
      'a deep link with only an id fetches the name for its header',
      () async {
        final cubit = build(name: '');
        await cubit.load();

        expect(cubit.state.studentName, 'Aria Rowan');
        expect(cubit.state.classroomName, 'Sunflower');
        await cubit.close();
      },
    );

    test('a failed load is a failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, DocumentsStatus.failed);
      await cubit.close();
    });

    test('nothing is sent until the type is picked', () async {
      final cubit = build();
      await cubit.load();
      await cubit.chooseFile();

      expect(cubit.state.upload, UploadStatus.idle);
      expect(cubit.state.draft.fileName, 'exam-mar-2026.pdf');
      await cubit.close();
    });

    test('choosing a file sends it and puts it on the list', () async {
      final cubit = build();
      await cubit.load();
      cubit.setType('Health Forms');
      await cubit.chooseFile();

      expect(cubit.state.upload, UploadStatus.done);
      expect(cubit.state.percentSent, 1);
      expect(cubit.state.documents.first.name, 'exam-mar-2026.pdf');
      await cubit.close();
    });

    test('a dropped upload keeps the type and the expiry for Retry', () async {
      source.uploadFails = true;
      final cubit = build();
      await cubit.load();
      cubit
        ..setType('Health Forms')
        ..setExpiry(DateTime(2027, 3, 14));
      await cubit.chooseFile();

      expect(cubit.state.upload, UploadStatus.failed);
      expect(cubit.state.draft.type, 'Health Forms');
      expect(cubit.state.draft.expiryDate, DateTime(2027, 3, 14));
      expect(cubit.state.documents.length, 1, reason: 'nothing was saved');

      source.uploadFails = false;
      await cubit.send();
      expect(cubit.state.upload, UploadStatus.done);
      await cubit.close();
    });

    test('Add another empties the file and keeps the answers', () async {
      final cubit = build();
      await cubit.load();
      cubit.setType('Health Forms');
      await cubit.chooseFile();
      cubit.reset();

      expect(cubit.state.upload, UploadStatus.idle);
      expect(cubit.state.draft.fileName, isNull);
      expect(cubit.state.draft.type, 'Health Forms');
      await cubit.close();
    });

    test(
      'the fields are put away once there is nothing left to decide',
      () async {
        final cubit = build();
        await cubit.load();
        cubit.setType('Health Forms');
        await cubit.chooseFile();

        expect(cubit.state.showsFields, isFalse);
        expect(cubit.state.showsProgress, isTrue);
        await cubit.close();
      },
    );
  });
}
