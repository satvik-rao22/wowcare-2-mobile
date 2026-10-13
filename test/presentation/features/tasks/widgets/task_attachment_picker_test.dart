// SUPERSEDED with the widget it covered (TaskAttachmentPicker). The shared
// replacement is covered by test/shared/attachment_picker_field_test.dart.
//
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:wowcare/core/utils/file_picker_utils.dart';
// import 'package:wowcare/core/network/api_client.dart';
// import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
// import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
// import 'package:wowcare/presentation/features/tasks/widgets/task_attachment_picker.dart';
// import 'package:wowcare/shared/services/asset/asset_service.dart';
//
// const _existing = TaskAttachment(
//   code: 'ATT_1',
//   assetCode: 'AST_1',
//   fileName: 'permission-slip.pdf',
//   contentType: 'application/pdf',
//   sizeBytes: 284913,
//   mediaType: 'DOCUMENT',
//   status: 'READY',
// );
//
// final _pending = PickedFile(
//           path: '/tmp/notes.pdf',
//           name: 'notes.pdf',
//           sizeBytes: 2048,
//           extension: 'pdf',
//           mimeType: 'application/pdf',
//         );
//
// void main() {
//   late AssetService service;
//
//   setUp(() {
//     service = AssetService(ApiClient(baseUrl: 'http://localhost'));
//   });
//
//   Future<void> pumpPicker(
//     WidgetTester tester, {
//     List<TaskAttachment> existing = const [],
//     List<PickedFile> pending = const [],
//     Map<String, int> uploadProgress = const {},
//     bool isUploading = false,
//     bool enabled = true,
//     ValueChanged<List<PickedFile>>? onPendingChanged,
//     ValueChanged<TaskAttachment>? onExistingRemoved,
//   }) async {
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Scaffold(
//           body: SingleChildScrollView(
//             child: TaskAttachmentPicker(
//               existing: existing,
//               pending: pending,
//               uploadService: service,
//               uploadProgress: uploadProgress,
//               isUploading: isUploading,
//               enabled: enabled,
//               onPendingChanged: onPendingChanged ?? (_) {},
//               onExistingRemoved: onExistingRemoved ?? (_) {},
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   testWidgets('empty state offers the add tile with the documented limits',
//       (tester) async {
//     await pumpPicker(tester);
//
//     expect(find.text('Add attachments'), findsOneWidget);
//     expect(find.text(TaskAttachmentUtils.limitsLabel), findsOneWidget);
//   });
//
//   testWidgets('lists existing and pending attachments together',
//       (tester) async {
//     await pumpPicker(tester, existing: [_existing], pending: [_pending]);
//
//     expect(find.text('permission-slip.pdf'), findsOneWidget);
//     expect(find.text('notes.pdf'), findsOneWidget);
//     // A held file is explicit that it isn't in storage yet.
//     expect(find.text('2 KB • waiting to upload'), findsOneWidget);
//     // With attachments present the tile invites more rather than repeating.
//     expect(find.text('Add more attachments'), findsOneWidget);
//   });
//
//   testWidgets('removing a pending file reports the shortened list',
//       (tester) async {
//     List<PickedFile>? reported;
//     await pumpPicker(
//       tester,
//       pending: [_pending],
//       onPendingChanged: (files) => reported = files,
//     );
//
//     await tester.tap(find.byIcon(Icons.close));
//     await tester.pump();
//
//     expect(reported, isEmpty);
//   });
//
//   testWidgets('removing a saved attachment reports which one', (tester) async {
//     TaskAttachment? removed;
//     await pumpPicker(
//       tester,
//       existing: [_existing],
//       onExistingRemoved: (a) => removed = a,
//     );
//
//     await tester.tap(find.byIcon(Icons.close));
//     await tester.pump();
//
//     expect(removed, _existing);
//   });
//
//   testWidgets('upload progress shows a bar and hides the remove control',
//       (tester) async {
//     await pumpPicker(
//       tester,
//       pending: [_pending],
//       uploadProgress: const {'/tmp/notes.pdf': 40},
//       isUploading: true,
//     );
//
//     expect(find.text('2 KB • uploading 40%'), findsOneWidget);
//     expect(find.byType(LinearProgressIndicator), findsOneWidget);
//     // Nothing may be removed mid-upload — the batch is already in flight.
//     expect(find.byIcon(Icons.close), findsNothing);
//   });
//
//   testWidgets('a completed upload drops the progress bar', (tester) async {
//     await pumpPicker(
//       tester,
//       pending: [_pending],
//       uploadProgress: const {'/tmp/notes.pdf': 100},
//       isUploading: true,
//     );
//
//     expect(find.text('2 KB • uploaded'), findsOneWidget);
//     expect(find.byType(LinearProgressIndicator), findsNothing);
//   });
//
//   testWidgets('at the cap the add tile is replaced by an explanation',
//       (tester) async {
//     await pumpPicker(
//       tester,
//       existing: List.generate(
//         TaskAttachmentUtils.maxAttachmentCount,
//         (i) => TaskAttachment(
//           code: 'ATT_$i',
//           assetCode: 'AST_$i',
//           fileName: 'file$i.pdf',
//           contentType: 'application/pdf',
//         ),
//       ),
//     );
//
//     expect(find.text('Add attachments'), findsNothing);
//     expect(find.text('Add more attachments'), findsNothing);
//     expect(
//       find.text(
//         'Maximum ${TaskAttachmentUtils.maxAttachmentCount} attachments '
//         'reached.',
//       ),
//       findsOneWidget,
//     );
//   });
//
//   testWidgets('a read-only picker offers no add tile and no remove controls',
//       (tester) async {
//     await pumpPicker(tester, existing: [_existing], enabled: false);
//
//     expect(find.text('permission-slip.pdf'), findsOneWidget);
//     expect(find.text('Add attachments'), findsNothing);
//     expect(find.byIcon(Icons.close), findsNothing);
//   });
// }

// Retained as a placeholder so the runner has an entry point.
void main() {}
