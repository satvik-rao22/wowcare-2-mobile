import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/student_documents_page.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/document_row.dart';

import 'students_test_doubles.dart';
import 'students_widget_harness.dart';

void main() {
  late FakeStudentsSource source;

  const args = StudentDocumentsArgs(
    studentId: 'aria',
    studentName: 'Aria Rowan',
    classroomName: 'Sunflower',
  );

  setUp(() async {
    source = FakeStudentsSource(
      documents: const <StudentDocumentItem>[
        StudentDocumentItem(
          id: 'doc-enrollment',
          name: 'Enrollment form',
          type: 'Registration Forms',
          kind: DocumentKind.pdf,
          detail: 'Registration Forms · 4 Sep 2025',
        ),
        StudentDocumentItem(
          id: 'doc-birth',
          name: 'Birth certificate',
          type: 'Birth Certificate',
          kind: DocumentKind.image,
          detail: 'Birth Certificate · 4 Sep 2025',
        ),
      ],
      picked: const PickedFile(
        name: 'exam-mar-2026.pdf',
        kind: DocumentKind.pdf,
        sizeKb: 1843,
      ),
    );
    await registerStudentsWith(source);
  });

  group('StudentDocumentsPage', () {
    testWidgets('opens on the add card over what is already on file', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentDocumentsPage(args: args));

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Aria Rowan · Sunflower'), findsOneWidget);

      expect(find.text('Add a document'), findsOneWidget);
      expect(find.text('Name it, pick a type, choose a file'), findsOneWidget);
      expect(find.text('ADD'), findsOneWidget);
      expect(find.text('Choose a file'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);

      expect(find.text('ON FILE · 2'), findsOneWidget);
      expect(find.byType(DocumentRow), findsNWidgets(2));
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('IMG'), findsOneWidget);
      expect(find.text('On file'), findsNWidgets(2));
    });

    testWidgets('picking a type and a file sends it and lands it on the list', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentDocumentsPage(args: args));

      await tester.tap(find.text('Pick a type'));
      await settle(tester);
      await tester.tap(find.text('Health Forms').last);
      await settle(tester);

      await tester.tap(find.text('Choose a file'));
      await settle(tester);

      // Once in the upload card, and once in the list under it.
      expect(find.text('exam-mar-2026.pdf'), findsNWidgets(2));
      expect(find.textContaining('On file · 1.8 MB'), findsOneWidget);
      expect(find.text('Add another'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('ON FILE · 3'), findsOneWidget);
    });

    testWidgets('a dropped upload keeps the answers and offers Retry', (
      tester,
    ) async {
      source.uploadFails = true;
      await pumpScreen(tester, const StudentDocumentsPage(args: args));

      await tester.tap(find.text('Pick a type'));
      await settle(tester);
      await tester.tap(find.text('Health Forms').last);
      await settle(tester);
      await tester.tap(find.text('Choose a file'));
      await settle(tester);

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.textContaining('lost the connection'), findsOneWidget);
      expect(find.text('ON FILE · 2'), findsOneWidget);
    });
  });
}
