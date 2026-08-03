import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/data/features/tasks/models/task_models.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';

void main() {
  group('TaskAttachment type classification', () {
    test('mediaType wins when the payload provides it', () {
      const image = TaskAttachment(assetCode: 'AST_1', mediaType: 'IMAGE');
      const video = TaskAttachment(assetCode: 'AST_2', mediaType: 'VIDEO');
      const doc = TaskAttachment(assetCode: 'AST_3', mediaType: 'DOCUMENT');

      expect(image.isImage, isTrue);
      expect(video.isVideo, isTrue);
      expect(doc.isDocument, isTrue);
      expect(doc.isImage, isFalse);
    });

    test('falls back to contentType when mediaType is absent', () {
      const image =
          TaskAttachment(assetCode: 'AST_1', contentType: 'image/webp');
      const video =
          TaskAttachment(assetCode: 'AST_2', contentType: 'video/quicktime');
      const pdf =
          TaskAttachment(assetCode: 'AST_3', contentType: 'application/pdf');

      expect(image.isImage, isTrue);
      expect(video.isVideo, isTrue);
      expect(pdf.isDocument, isTrue);
    });

    test('falls back to the file extension when both are absent', () {
      const image = TaskAttachment(assetCode: 'AST_1', fileName: 'photo.PNG');
      const video = TaskAttachment(assetCode: 'AST_2', fileName: 'clip.mp4');
      const sheet = TaskAttachment(assetCode: 'AST_3', fileName: 'roster.xlsx');

      expect(image.isImage, isTrue);
      expect(video.isVideo, isTrue);
      expect(sheet.isDocument, isTrue);
    });

    test('an unknown file with no metadata is treated as a document', () {
      const unknown = TaskAttachment(assetCode: 'AST_1', fileName: 'notes');
      expect(unknown.isDocument, isTrue);
    });

    test('blank, READY and UPLOADED are showable; FAILED is not', () {
      expect(const TaskAttachment(assetCode: 'A').isReady, isTrue);
      expect(
        const TaskAttachment(assetCode: 'A', status: 'ready').isReady,
        isTrue,
      );
      // document-ms parks task attachments at UPLOADED and serves them fine
      // there, so treating that as "still processing" hid working attachments.
      expect(
        const TaskAttachment(assetCode: 'A', status: 'UPLOADED').isReady,
        isTrue,
      );
      expect(
        const TaskAttachment(assetCode: 'A', status: 'FAILED').isReady,
        isFalse,
      );
    });

    test('displaySize switches from KB to MB and hides an unknown size', () {
      expect(const TaskAttachment(assetCode: 'A', sizeBytes: 0).displaySize, '');
      // Formatting is FilePickerUtils.formatBytes now — shared with every other
      // attachment surface, so KB keeps one decimal below 10.
      expect(
        const TaskAttachment(assetCode: 'A', sizeBytes: 2048).displaySize,
        '2.0 KB',
      );
      expect(
        const TaskAttachment(assetCode: 'A', sizeBytes: 5 * 1024 * 1024)
            .displaySize,
        '5.0 MB',
      );
    });
  });

  group('TaskResponseParser.attachmentList', () {
    test('reads the documented events-style items envelope', () {
      final result = TaskResponseParser.attachmentList({
        'data': {
          'items': [
            {
              'code': 'ATT_1',
              'assetCode': 'AST_1',
              'fileName': 'permission.pdf',
              'contentType': 'application/pdf',
              'sizeBytes': 284913,
              'mediaType': 'DOCUMENT',
              'status': 'READY',
              'deliveryUrl': 'https://cdn/permission.pdf',
            },
          ],
        },
      });

      expect(result.length, 1);
      final attachment = result.single;
      expect(attachment.code, 'ATT_1');
      expect(attachment.assetCode, 'AST_1');
      expect(attachment.fileName, 'permission.pdf');
      expect(attachment.sizeBytes, 284913);
      expect(attachment.url, 'https://cdn/permission.pdf');
      expect(attachment.isDocument, isTrue);
    });

    test('reads a bare data array', () {
      final result = TaskResponseParser.attachmentList({
        'data': [
          {'assetCode': 'AST_1', 'fileName': 'a.png'},
        ],
      });
      expect(result.single.assetCode, 'AST_1');
    });

    test('reads asset metadata nested under an asset object', () {
      final result = TaskResponseParser.attachmentList({
        'data': {
          'items': [
            {
              'code': 'ATT_9',
              'asset': {
                'assetCode': 'AST_9',
                'fileName': 'photo.jpg',
                'contentType': 'image/jpeg',
                'contentLengthBytes': 1024,
                'thumbnailUrl': 'https://cdn/thumb.jpg',
              },
            },
          ],
        },
      });

      final attachment = result.single;
      expect(attachment.code, 'ATT_9');
      expect(attachment.assetCode, 'AST_9');
      expect(attachment.contentType, 'image/jpeg');
      expect(attachment.sizeBytes, 1024);
      expect(attachment.thumbnailUrl, 'https://cdn/thumb.jpg');
      expect(attachment.isImage, isTrue);
    });

    test('prefers attachmentCode over code for the detach key', () {
      final result = TaskResponseParser.attachmentList({
        'data': {
          'items': [
            {'attachmentCode': 'ATT_REAL', 'code': 'AST_X', 'assetCode': 'AST_X'},
          ],
        },
      });
      expect(result.single.code, 'ATT_REAL');
    });

    test('drops rows carrying neither code and tolerates junk payloads', () {
      expect(
        TaskResponseParser.attachmentList({
          'data': {
            'items': [
              {'fileName': 'orphan.pdf'},
              'not-a-map',
            ],
          },
        }),
        isEmpty,
      );
      expect(TaskResponseParser.attachmentList(null), isEmpty);
      expect(TaskResponseParser.attachmentList({'data': null}), isEmpty);
      expect(TaskResponseParser.attachmentList({'data': 42}), isEmpty);
    });
  });

  group('TaskAttachmentUtils', () {
    test('limits match the documented backend caps', () {
      // TASK_SYSTEM_DESIGN_DOC: "attachment ≤ 10 MB; allowed types
      // JPEG/PNG/WebP/PDF (validated server-side)".
      expect(TaskAttachmentUtils.maxAttachmentBytes, 10 * 1024 * 1024);
      expect(
        TaskAttachmentUtils.allowedExtensions,
        containsAll(<String>['jpg', 'jpeg', 'png', 'webp', 'pdf']),
      );
      // Nothing the server would reject may be offered by the picker.
      expect(TaskAttachmentUtils.allowedExtensions, hasLength(5));
    });

    test('extensionLabel uppercases the extension and handles bare names', () {
      expect(TaskAttachmentUtils.extensionLabel('report.pdf'), 'PDF');
      expect(TaskAttachmentUtils.extensionLabel('photo.JPeG'), 'JPEG');
      expect(TaskAttachmentUtils.extensionLabel('noextension'), 'FILE');
    });

    test('docTypeStyle distinguishes the common office types', () {
      IconData iconFor(String name, [String type = '']) =>
          TaskAttachmentUtils.docTypeStyle(name, type).icon;

      expect(iconFor('a.pdf'), Icons.picture_as_pdf_rounded);
      expect(iconFor('a.xlsx'), Icons.table_chart_rounded);
      expect(iconFor('a.docx'), Icons.article_rounded);
      expect(iconFor('a.pptx'), Icons.slideshow_rounded);
      expect(iconFor('a.zip'), Icons.insert_drive_file_rounded);
      // Content type alone is enough when the name carries no extension.
      expect(iconFor('unnamed', 'application/pdf'),
          Icons.picture_as_pdf_rounded);
    });

    // Sizes are formatted by the shared FilePickerUtils.formatBytes now; its
    // own behaviour is covered in the picker/manager suites.
    test('displaySize is empty for an unknown size and set otherwise', () {
      expect(const TaskAttachment(assetCode: 'AST_1').displaySize, '');
      expect(
        const TaskAttachment(assetCode: 'AST_1', sizeBytes: 2048).displaySize,
        isNotEmpty,
      );
    });
  });

  // An attachment reconstructed from a task's `assetCodes` knows only its code.
  // Nothing on the payload says what kind of file it is, so the type has to come
  // from the resolved delivery URL — otherwise every such image would render and
  // open as a document.
  group('TaskAttachment — type unknown until the URL resolves', () {
    const bare = TaskAttachment(assetCode: 'AST_F51F0D20-F');

    test('an assetCodes-only attachment reports an unknown type', () {
      expect(bare.hasKnownType, isFalse);
      // Both false for lack of evidence — `isDocument` is only the fallback.
      expect(bare.isImage, isFalse);
      expect(bare.isVideo, isFalse);
    });

    test('anything the payload said about the type counts as known', () {
      expect(
        const TaskAttachment(assetCode: 'A', mediaType: 'IMAGE').hasKnownType,
        isTrue,
      );
      expect(
        const TaskAttachment(assetCode: 'A', contentType: 'application/pdf')
            .hasKnownType,
        isTrue,
      );
      expect(
        const TaskAttachment(assetCode: 'A', fileName: 'a.png').hasKnownType,
        isTrue,
      );
      // A name without an extension says nothing about the type.
      expect(
        const TaskAttachment(assetCode: 'A', fileName: 'scan').hasKnownType,
        isFalse,
      );
    });

    test('withResolvedUrl infers an image from the URL extension', () {
      final resolved =
          bare.withResolvedUrl('https://cdn.example.com/a/b/photo.JPG?sig=xyz');
      expect(resolved.url, 'https://cdn.example.com/a/b/photo.JPG?sig=xyz');
      expect(resolved.isImage, isTrue);
      expect(resolved.hasKnownType, isTrue);
    });

    test('withResolvedUrl infers pdf and video', () {
      expect(bare.withResolvedUrl('https://x.test/f.pdf').isDocument, isTrue);
      expect(
        bare.withResolvedUrl('https://x.test/f.pdf').contentType,
        'application/pdf',
      );
      expect(bare.withResolvedUrl('https://x.test/clip.mp4').isVideo, isTrue);
    });

    test('an opaque URL leaves the type unknown, so the doc fallback stands',
        () {
      final resolved = bare.withResolvedUrl('https://x.test/assets/9f2a1b3c');
      expect(resolved.url, 'https://x.test/assets/9f2a1b3c');
      expect(resolved.hasKnownType, isFalse);
      expect(resolved.isDocument, isTrue);
    });

    test('never overrides a type the payload already stated', () {
      const stated =
          TaskAttachment(assetCode: 'A', mediaType: 'IMAGE', fileName: 'a.png');
      final resolved = stated.withResolvedUrl('https://x.test/f.pdf');
      expect(resolved.isImage, isTrue);
      expect(resolved.contentType, '');
      expect(resolved.url, 'https://x.test/f.pdf');
    });

    test('a blank URL changes nothing', () {
      expect(bare.withResolvedUrl('   '), bare);
    });

    test('is ready by default, so it renders instead of showing "processing"',
        () {
      expect(bare.isReady, isTrue);
    });
  });

  group('PendingTaskAttachment', () {
    test('classifies by content type and formats its size', () {
      final image = PickedFile(
          path: '/tmp/a.png',
          name: 'a.png',
          sizeBytes: 3 * 1024 * 1024,
          extension: 'png',
          mimeType: 'image/png',
        );
      expect(image.isImage, isTrue);
      expect(image.isVideo, isFalse);
      expect(image.readableSize, '3.0 MB');
    });
  });
}
