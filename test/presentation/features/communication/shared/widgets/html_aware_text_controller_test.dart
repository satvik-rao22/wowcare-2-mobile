import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/html_aware_text_controller.dart';

/// Simulates pressing Enter at [offset]: the TextField/IME would insert a
/// bare `\n` and report a collapsed cursor right after it — exactly the
/// TextEditingValue shape the controller's `value` setter receives from a
/// real keypress, which is what [_continueListPrefixIfNeeded] pattern-matches
/// against.
void _pressEnterAt(HtmlAwareTextController controller, int offset) {
  final text = controller.text;
  controller.value = TextEditingValue(
    text: '${text.substring(0, offset)}\n${text.substring(offset)}',
    selection: TextSelection.collapsed(offset: offset + 1),
  );
}

/// Simulates typing a single character at [offset].
void _typeCharAt(HtmlAwareTextController controller, int offset, String char) {
  final text = controller.text;
  controller.value = TextEditingValue(
    text: '${text.substring(0, offset)}$char${text.substring(offset)}',
    selection: TextSelection.collapsed(offset: offset + 1),
  );
}

void main() {
  group('list-prefix continuation', () {
    test('Enter after a bulleted line continues the bullet', () {
      final controller = HtmlAwareTextController(text: '• first item');
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, '• first item\n• ');
      expect(controller.selection, const TextSelection.collapsed(offset: 15));
    });

    test('Enter after a numbered line continues with the next number', () {
      final controller = HtmlAwareTextController(text: '1. first item');
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, '1. first item\n2. ');
    });

    test('numbering keeps incrementing across several lines', () {
      final controller = HtmlAwareTextController(text: '1. first');
      _pressEnterAt(controller, controller.text.length);
      controller.text += 'second'; // simulate typing the next item's content
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, '1. first\n2. second\n3. ');
    });

    test('Enter on an empty bulleted line ends the list instead of repeating it', () {
      final controller = HtmlAwareTextController(text: 'notes:\n• ');
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, 'notes:\n');
      expect(controller.selection, const TextSelection.collapsed(offset: 7));
    });

    test('Enter on an empty numbered line ends the list', () {
      final controller = HtmlAwareTextController(text: '1. ');
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, '');
    });

    test('Enter on a plain (non-list) line is left untouched', () {
      final controller = HtmlAwareTextController(text: 'just a sentence');
      _pressEnterAt(controller, controller.text.length);

      expect(controller.text, 'just a sentence\n');
    });

    test('Enter as the very first character of an empty field does not throw', () {
      // Regression: lastIndexOf('\n', insertAt - 2) with insertAt == 1
      // passed a negative start index and threw
      // "RangeError: Invalid value: Only valid value is 0: -1".
      final controller = HtmlAwareTextController(text: '');
      expect(() => _pressEnterAt(controller, 0), returnsNormally);
      expect(controller.text, '\n');
    });

    test('continuing a bullet mid-message (not at the end) inserts inline', () {
      final controller = HtmlAwareTextController(text: '• first\n• third');
      // Cursor right after "first", before the '\n'.
      _pressEnterAt(controller, 7);

      expect(controller.text, '• first\n• \n• third');
    });
  });

  group('sentence auto-capitalization', () {
    test('capitalizes the first letter of the message', () {
      final controller = HtmlAwareTextController(text: '');
      _typeCharAt(controller, 0, 'h');

      expect(controller.text, 'H');
    });

    test('capitalizes the letter typed right after ". "', () {
      final controller = HtmlAwareTextController(text: 'Hello there. ');
      _typeCharAt(controller, controller.text.length, 'w');

      expect(controller.text, 'Hello there. W');
    });

    test('capitalizes after "! " and "? " too', () {
      final exclaim = HtmlAwareTextController(text: 'Wow! ');
      _typeCharAt(exclaim, exclaim.text.length, 'n');
      expect(exclaim.text, 'Wow! N');

      final question = HtmlAwareTextController(text: 'Really? ');
      _typeCharAt(question, question.text.length, 'y');
      expect(question.text, 'Really? Y');
    });

    test('capitalizes the first letter of a new line', () {
      final controller = HtmlAwareTextController(text: 'line one\n');
      _typeCharAt(controller, controller.text.length, 'l');

      expect(controller.text, 'line one\nL');
    });

    test('capitalizes the first letter typed after a fresh bullet (toolbar-inserted)', () {
      // e.g. tapping the Bullet toolbar button on an empty/new line.
      final controller = HtmlAwareTextController(text: '• ');
      _typeCharAt(controller, controller.text.length, 'm');

      expect(controller.text, '• M');
    });

    test('capitalizes the first letter typed after a fresh numbered prefix', () {
      final controller = HtmlAwareTextController(text: '1. ');
      _typeCharAt(controller, controller.text.length, 'm');

      expect(controller.text, '1. M');
    });

    test('capitalizes the first letter after a bullet continued via Enter', () {
      final controller = HtmlAwareTextController(text: '• first item');
      _pressEnterAt(controller, controller.text.length);
      _typeCharAt(controller, controller.text.length, 's');

      expect(controller.text, '• first item\n• S');
    });

    test('does not capitalize once a bullet line already has content', () {
      final controller = HtmlAwareTextController(text: '• already typing');
      _typeCharAt(controller, controller.text.length, 's');

      expect(controller.text, '• already typings');
    });

    test('does not capitalize mid-sentence typing', () {
      final controller = HtmlAwareTextController(text: 'hello wor');
      _typeCharAt(controller, controller.text.length, 'l');

      expect(controller.text, 'hello worl');
    });

    test('does not capitalize a period directly followed by a letter with no space', () {
      final controller = HtmlAwareTextController(text: 'e.g.');
      _typeCharAt(controller, controller.text.length, 'g');

      expect(controller.text, 'e.g.g');
    });

    test('leaves digits and symbols alone', () {
      final controller = HtmlAwareTextController(text: 'Total: ');
      _typeCharAt(controller, controller.text.length, '5');

      expect(controller.text, 'Total: 5');
    });
  });

  group('interop with existing controller methods', () {
    test('pasteFromClipboard-style multi-char insert is unaffected by the new logic', () {
      final controller = HtmlAwareTextController(text: 'a bullet: ');
      // Mirrors insertClipboardContent's own value assignment shape: a
      // multi-character replacement, not a single keypress.
      controller.value = controller.value.copyWith(
        text: '${controller.text}• pasted item',
        selection: TextSelection.collapsed(
          offset: controller.text.length + '• pasted item'.length,
        ),
      );

      expect(controller.text, 'a bullet: • pasted item');
    });

    test('selectAllText does not trigger continuation/capitalization', () {
      final controller = HtmlAwareTextController(text: '• item');
      controller.selectAllText();

      expect(controller.text, '• item');
      expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 6));
    });
  });
}
