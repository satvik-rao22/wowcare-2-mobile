/// Unit tests for [ComposerCubit] — the extracted message-composer state
/// (quote / edit / pending attachments) that the three thread screens each
/// held in `setState` fields before Mandate 2. Pure cubit, no dependencies.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/view_model/composer_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/composer_state.dart';

Message _msg(String id) => Message(
  id: id,
  code: 'C-$id',
  text: 'body $id',
  isSentByMe: true,
  time: DateTime(2026, 1, 1, 10),
);

ChatAttachment _att(String name) => ChatAttachment(
  name: name,
  type: 'image',
  sizeBytes: 1,
  mimeType: 'image/png',
  remoteUrl: 'https://x/$name',
);

void main() {
  late ComposerCubit<Message> cubit;

  setUp(() => cubit = ComposerCubit());
  tearDown(() => cubit.close());

  test('starts empty', () {
    expect(cubit.state, const ComposerState<Message>());
    expect(cubit.state.isQuoting, isFalse);
    expect(cubit.state.isEditing, isFalse);
    expect(cubit.state.hasAttachments, isFalse);
  });

  group('quote', () {
    test('sets the quoted message', () {
      cubit.quote(_msg('1'));
      expect(cubit.state.quotedMessage, _msg('1'));
      expect(cubit.state.isQuoting, isTrue);
    });

    test('a second quote replaces the first', () {
      cubit
        ..quote(_msg('1'))
        ..quote(_msg('2'));
      expect(cubit.state.quotedMessage, _msg('2'));
    });

    test('clearQuote removes it; a no-op when not quoting', () {
      cubit.clearQuote(); // no-op — must not emit
      expect(cubit.state, const ComposerState<Message>());

      cubit
        ..quote(_msg('1'))
        ..clearQuote();
      expect(cubit.state.quotedMessage, isNull);
    });

    test('quoting leaves an in-progress edit and attachments intact', () {
      cubit
        ..startEdit(_msg('edit'))
        ..addAttachments([_att('a')])
        ..quote(_msg('reply'));
      expect(cubit.state.editingMessage, _msg('edit'));
      expect(cubit.state.pendingAttachments, [_att('a')]);
      expect(cubit.state.quotedMessage, _msg('reply'));
    });
  });

  group('edit', () {
    test('startEdit sets the editing message; cancelEdit clears it', () {
      cubit.startEdit(_msg('e'));
      expect(cubit.state.editingMessage, _msg('e'));
      expect(cubit.state.isEditing, isTrue);

      cubit.cancelEdit();
      expect(cubit.state.editingMessage, isNull);
    });

    test('cancelEdit is a no-op when not editing', () {
      final emitted = <ComposerState<Message>>[];
      final sub = cubit.stream.listen(emitted.add);
      cubit.cancelEdit();
      expect(emitted, isEmpty);
      sub.cancel();
    });

    test('editing leaves an active quote intact', () {
      cubit
        ..quote(_msg('q'))
        ..startEdit(_msg('e'));
      expect(cubit.state.quotedMessage, _msg('q'));
      expect(cubit.state.editingMessage, _msg('e'));
    });
  });

  group('attachments', () {
    test('addAttachments appends in order', () {
      cubit
        ..addAttachments([_att('a')])
        ..addAttachments([_att('b'), _att('c')]);
      expect(cubit.state.pendingAttachments.map((a) => a.name), [
        'a',
        'b',
        'c',
      ]);
    });

    test('addAttachments with an empty list is a no-op', () {
      final emitted = <ComposerState<Message>>[];
      final sub = cubit.stream.listen(emitted.add);
      cubit.addAttachments(const []);
      expect(emitted, isEmpty);
      sub.cancel();
    });

    test('removeAttachment removes the item at the index', () {
      cubit.addAttachments([_att('a'), _att('b'), _att('c')]);
      cubit.removeAttachment(1);
      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a', 'c']);
    });

    test('removeAttachment ignores an out-of-range index', () {
      cubit.addAttachments([_att('a')]);
      cubit
        ..removeAttachment(5)
        ..removeAttachment(-1);
      expect(cubit.state.pendingAttachments.map((a) => a.name), ['a']);
    });
  });

  group('reset', () {
    test('clears quote, edit and attachments', () {
      cubit
        ..quote(_msg('q'))
        ..startEdit(_msg('e'))
        ..addAttachments([_att('a')])
        ..reset();
      expect(cubit.state, const ComposerState<Message>());
    });

    test('is a no-op when already empty', () {
      final emitted = <ComposerState<Message>>[];
      final sub = cubit.stream.listen(emitted.add);
      cubit.reset();
      expect(emitted, isEmpty);
      sub.cancel();
    });
  });
}
