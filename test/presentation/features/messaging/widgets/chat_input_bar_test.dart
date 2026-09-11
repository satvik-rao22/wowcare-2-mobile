import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ChatInputBar', () {
    testWidgets('shows the default placeholder, and honours an override', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () {},
            onAttachmentTap: () {},
          ),
        ),
      );

      // Pinned to ChatInputBar's own default rather than a copy string from a
      // PRD revision — the earlier 'Type your message here…' matched no build
      // of the widget.
      expect(find.text('Type a message…'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () {},
            onAttachmentTap: () {},
            hintText: 'Message the room',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Message the room'), findsOneWidget);
    });

    testWidgets('send button disabled when input is empty', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () {},
            onAttachmentTap: () {},
          ),
        ),
      );

      // The send icon uses color based on _hasText — find GestureDetector
      // wrapping the send button and verify its onTap is null when empty.
      // We verify indirectly: tapping sends nothing.
      var sendCalled = false;
      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () => sendCalled = true,
            onAttachmentTap: () {},
          ),
        ),
      );

      // Input is empty — tapping the send area should not invoke onSend.
      final sendFinder = find.byIcon(Icons.send_rounded);
      await tester.tap(sendFinder);
      await tester.pump();
      expect(sendCalled, isFalse);
    });

    testWidgets('send button enabled after text is entered', (tester) async {
      final controller = TextEditingController();
      var sendCalled = false;

      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () => sendCalled = true,
            onAttachmentTap: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      final sendFinder = find.byIcon(Icons.send_rounded);
      await tester.tap(sendFinder);
      await tester.pump();
      expect(sendCalled, isTrue);
    });

    testWidgets('pending attachment strip is hidden when no attachments', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () {},
            onAttachmentTap: () {},
            pendingAttachments: const [],
          ),
        ),
      );

      // SizedBox.shrink is rendered; no ListView for attachments
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets(
      'pending attachment strip is visible when attachments present',
      (tester) async {
        final controller = TextEditingController();
        const attachment = ChatAttachment(
          name: 'photo.jpg',
          type: 'image',
          sizeBytes: 1024,
          mimeType: 'image/jpeg',
          remoteUrl: '',
          localPath: null,
        );

        await tester.pumpWidget(
          _wrap(
            ChatInputBar(
              controller: controller,
              onSend: () {},
              onAttachmentTap: () {},
              pendingAttachments: const [attachment],
            ),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'an image attachment with no local file renders a placeholder instead of '
      'throwing',
      (tester) async {
        // A pending attachment can legitimately have no file on disk (restored
        // draft, rehydrated after a failed send). The strip used to
        // force-unwrap `localPath` inside the ListView's itemBuilder, so this
        // took down the whole input bar with a null-check error.
        final controller = TextEditingController();
        const attachment = ChatAttachment(
          name: 'photo.jpg',
          type: 'image',
          sizeBytes: 1024,
          mimeType: 'image/jpeg',
          remoteUrl: '',
          localPath: null,
        );

        await tester.pumpWidget(
          _wrap(
            ChatInputBar(
              controller: controller,
              onSend: () {},
              onAttachmentTap: () {},
              pendingAttachments: const [attachment],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      },
    );

    testWidgets('character counter visible when showCharCounter is true', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            controller: controller,
            onSend: () {},
            onAttachmentTap: () {},
            showCharCounter: true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // TextField with maxLength shows counter when showCharCounter != ''
      expect(find.byType(TextField), findsOneWidget);
      final tf = tester.widget<TextField>(find.byType(TextField));
      // counterText is null (not empty string) when showCharCounter is true
      expect(tf.decoration?.counterText, isNull);
    });
  });
}
