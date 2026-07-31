import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('a blank status counts as ready, FAILED and UPLOADED do not', () {
      expect(const TaskAttachment(assetCode: 'A').isReady, isTrue);
      expect(
        const TaskAttachment(assetCode: 'A', status: 'ready').isReady,
        isTrue,
      );
      expect(
        const TaskAttachment(assetCode: 'A', status: 'UPLOADED').isReady,
        isFalse,
      );
      expect(
        const TaskAttachment(assetCode: 'A', status: 'FAILED').isReady,
        isFalse,
      );
    });

    test('displaySize switches from KB to MB and hides an unknown size', () {
      expect(const TaskAttachment(assetCode: 'A', sizeBytes: 0).displaySize, '');
      expect(
        const TaskAttachment(assetCode: 'A', sizeBytes: 2048).displaySize,
        '2 KB',
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

    test('formatAttachmentSize never rounds a small file down to "0 KB"', () {
      expect(formatAttachmentSize(0), '');
      expect(formatAttachmentSize(512), '512 B');
      expect(formatAttachmentSize(1024), '1 KB');
    });
  });

  group('PendingTaskAttachment', () {
    test('classifies by content type and formats its size', () {
      const image = PendingTaskAttachment(
        filePath: '/tmp/a.png',
        fileName: 'a.png',
        contentType: 'image/png',
        sizeBytes: 3 * 1024 * 1024,
      );
      expect(image.isImage, isTrue);
      expect(image.isVideo, isFalse);
      expect(image.displaySize, '3.0 MB');
    });
  });
}
