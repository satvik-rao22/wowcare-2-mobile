import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/html_aware_text_controller.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboardText;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        switch (methodCall.method) {
          case 'Clipboard.setData':
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            clipboardText = args['text'] as String?;
            return <String, dynamic>{};
          case 'Clipboard.getData':
            return <String, dynamic>{'text': clipboardText};
          default:
            return null;
        }
      });

  group('MessageContentProcessor preview detection', () {
    test('detects the first URL in plain text', () {
      final preview = MessageContentProcessor.detectFirstPreview(
        'Please review https://example.com before continuing.',
      );

      expect(preview, isNotNull);
      expect(preview!.kind, PreviewKind.url);
      expect(preview.value, 'https://example.com');
    });

    test('detects an email address when no URL is present', () {
      final preview = MessageContentProcessor.detectFirstPreview(
        'Contact us at admin@example.com for support.',
      );

      expect(preview, isNotNull);
      expect(preview!.kind, PreviewKind.email);
      expect(preview.value, 'admin@example.com');
    });

    test('detects a phone number when no URL or email is present', () {
      final preview = MessageContentProcessor.detectFirstPreview(
        'Call us at (555) 123-4567 today.',
      );

      expect(preview, isNotNull);
      expect(preview!.kind, PreviewKind.phone);
      expect(preview.value, '(555) 123-4567');
    });
  });

  group('HtmlAwareTextController clipboard handling', () {
    test('normalizes rich clipboard payloads into safe inline html', () {
      final controller = HtmlAwareTextController();

      final normalized = controller.normalizeClipboardPayload(
        '<p>Hello</p><p><b>World</b></p>',
      );

      expect(normalized, 'Hello\n<b>World</b>');
    });

    test('inserts clipboard content at the current selection', () {
      final controller = HtmlAwareTextController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 5);

      controller.insertClipboardContent(' <b>World</b>');

      expect(controller.text, 'Hello <b>World</b>');
      expect(controller.selection.baseOffset, 18);
    });

    test(
      'cuts the selection to the clipboard and removes it from the editor',
      () async {
        final controller = HtmlAwareTextController(text: 'Hello world');
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 5,
        );

        final copied = await controller.cutSelectionToClipboard();

        expect(copied, isTrue);
        expect(controller.text, ' world');
        expect(await Clipboard.getData(Clipboard.kTextPlain), isNotNull);
      },
    );

    test('selects all text when requested', () {
      final controller = HtmlAwareTextController(text: 'Hello world');

      controller.selectAllText();

      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 11),
      );
    });
  });
}
