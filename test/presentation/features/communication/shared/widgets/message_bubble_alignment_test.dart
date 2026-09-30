/// Widget tests verifying MessageBubble alignment and bubble-fill rules.
///
/// Scenarios covered (see docs/messaging/06-ui-standards.md §6.1):
///
/// Parent dashboard (viewerIsGuardian no longer used — alignment always by identity):
///   • Current guardian (isMe=true)  → right-aligned, pink face, light text
///   • Staff sender (isMe=false, orgSide=true) → left-aligned, card face
///
/// Staff/Admin dashboard:
///   • Guardian sender (isMe=false, orgSide=false) → left-aligned, navy face
///   • Current staff user (isMe=true, orgSide=true) → right-aligned, pink face
///   • Other staff (isMe=false, orgSide=true)       → left-aligned, card face
///
/// Staff Direct (orgSide=null — no role colouring):
///   • isMe=true  → right-aligned, pink face
///   • isMe=false → left-aligned, card face
///
/// Every fill is flat: rule 3 of the design language forbids gradients.
library;

import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/message_bubble_widget.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _currentUserCode = 'USR-ME';
const _otherUserCode = 'USR-OTHER';

Message _msg({required bool isMe}) => Message(
  id: 'msg-1',
  code: 'msg-1',
  text: 'Hello world',
  isSentByMe: false,
  senderUserCode: isMe ? _currentUserCode : _otherUserCode,
  time: DateTime(2026, 1, 1, 10),
);

ReactionsController _reactions() =>
    ReactionsController(currentUserId: _currentUserCode);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
);

Widget _bubble({
  required bool isMe,
  required bool? senderIsOrgSide,
  ReactionsController? reactions,
}) {
  final ctrl = reactions ?? _reactions();
  return _wrap(
    MessageBubble(
      message: _msg(isMe: isMe),
      currentUserCode: _currentUserCode,
      reactionsController: ctrl,
      senderIsOrgSide: senderIsOrgSide,
    ),
  );
}

/// Find the primary alignment widget (the Align that positions the bubble
/// left or right) by walking the GestureDetector > Transform > Align path.
Alignment _bubbleAlignment(WidgetTester tester) {
  final aligns = tester.widgetList<Align>(find.byType(Align)).toList();
  // The first Align with a non-center horizontal alignment is the one that
  // positions the bubble. centerLeft / centerRight both have dy == 0.
  for (final a in aligns) {
    if (a.alignment == Alignment.centerRight ||
        a.alignment == Alignment.centerLeft) {
      return a.alignment as Alignment;
    }
  }
  throw TestFailure('No left/right Align found in widget tree');
}

/// Return the BoxDecoration applied to the innermost bubble Container —
/// the one whose margin shrinks on the non-bubble side.
BoxDecoration _bubbleDecoration(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final c in containers) {
    final deco = c.decoration;
    if (deco is BoxDecoration && deco.borderRadius != null) {
      return deco;
    }
  }
  throw TestFailure('No decorated Container found');
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MessageBubble — alignment is always identity-based', () {
    testWidgets('current user message is right-aligned regardless of role', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bubble(isMe: true, senderIsOrgSide: true), // staff viewer, own message
      );
      expect(_bubbleAlignment(tester), Alignment.centerRight);
    });

    testWidgets('other-user message is left-aligned regardless of role', (
      tester,
    ) async {
      await tester.pumpWidget(
        _bubble(isMe: false, senderIsOrgSide: false), // guardian sender, not me
      );
      expect(_bubbleAlignment(tester), Alignment.centerLeft);
    });
  });

  group('MessageBubble — bubble fill', () {
    // Three flat faces, no gradients anywhere: pink is my own voice, navy is
    // a guardian's when staff read it, and the card face is everyone else.
    void expectFlat(WidgetTester tester, Color face) {
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNull, reason: 'the design language is flat');
      expect(deco.color, equals(face));
    }

    testWidgets('my own message is the pink action face, whatever my role', (
      tester,
    ) async {
      for (final bool? orgSide in <bool?>[true, false, null]) {
        await tester.pumpWidget(_bubble(isMe: true, senderIsOrgSide: orgSide));
        expectFlat(tester, AppColors.messagingBubbleMine);
      }
    });

    testWidgets("a guardian's message read by staff is the navy impact face", (
      tester,
    ) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: false));
      expectFlat(tester, AppColors.messagingBubbleGuardian);
    });

    testWidgets('another staff member gets the plain card face', (
      tester,
    ) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: true));
      expectFlat(tester, AppColors.messagingBubbleReceived);
    });

    testWidgets('Staff Direct (orgSide null) receiver gets the card face', (
      tester,
    ) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: null));
      expectFlat(tester, AppColors.messagingBubbleReceived);
    });
  });
}
