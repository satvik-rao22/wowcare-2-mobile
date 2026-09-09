/// Integration smoke test for the composer wiring shared by the three thread
/// screens after Mandate 2: a [ComposerCubit] driving a [ChatInputBar] through
/// a `BlocBuilder`. Verifies that quoting / editing / cancelling via the cubit
/// is reflected in the input bar exactly as the screens rely on — without any
/// of the DI-heavy screen scaffolding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/cubit/composer_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/composer_state.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_input_bar.dart';

Message _msg(String text) => Message(
  id: 'm1',
  code: 'c1',
  text: text,
  isSentByMe: false,
  senderName: 'Alice',
  time: DateTime(2026, 1, 1, 10),
);

void main() {
  late ComposerCubit<Message> composer;
  late TextEditingController controller;

  setUp(() {
    composer = ComposerCubit<Message>();
    controller = TextEditingController();
  });
  tearDown(() {
    composer.close();
    controller.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocBuilder<ComposerCubit<Message>, ComposerState<Message>>(
            bloc: composer,
            builder: (context, s) => Column(
              children: [
                Text('q=${s.isQuoting} e=${s.isEditing}'),
                Expanded(
                  child: ChatInputBar(
                    controller: controller,
                    onSend: () {},
                    onAttachmentTap: () {},
                    quotedMessage: s.quotedMessage,
                    editingMessage: s.editingMessage,
                    pendingAttachments: s.pendingAttachments,
                    onCancelQuote: composer.clearQuote,
                    onRemoveAttachment: composer.removeAttachment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('quoting shows the reply preview; clearQuote hides it', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('q=false e=false'), findsOneWidget);

    composer.quote(_msg('QuoteBody'));
    await tester.pumpAndSettle();
    // The BlocBuilder rebuilt with the new state...
    expect(find.text('q=true e=false'), findsOneWidget);
    // ...and the input bar rendered the reply preview (sender + body).
    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('QuoteBody'), findsOneWidget);

    composer.clearQuote();
    await tester.pumpAndSettle();
    expect(find.text('q=false e=false'), findsOneWidget);
    expect(find.textContaining('QuoteBody'), findsNothing);
  });

  testWidgets('editing shows the edit preview; cancelEdit hides it', (
    tester,
  ) async {
    await pump(tester);

    composer.startEdit(_msg('EditBody'));
    await tester.pumpAndSettle();
    // The edit preview strip renders an "Editing message" affordance.
    expect(find.textContaining('Edit'), findsWidgets);

    composer.cancelEdit();
    await tester.pumpAndSettle();
    expect(composer.state.isEditing, isFalse);
  });
}
