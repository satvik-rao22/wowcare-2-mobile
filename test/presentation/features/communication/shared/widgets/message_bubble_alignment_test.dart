/// Widget tests verifying MessageBubble alignment and bubble-fill rules.
///
/// Scenarios covered (see docs/messaging/06-ui-standards.md §6.1):
///
/// Parent dashboard (viewerIsGuardian no longer used — alignment always by identity):
///   • Current guardian (isMe=true)  → right-aligned, primary gradient, light text
///   • Staff sender (isMe=false, orgSide=true) → left-aligned, white bubble
///
/// Staff/Admin dashboard:
///   • Guardian sender (isMe=false, orgSide=false) → left-aligned, pink gradient
///   • Current staff user (isMe=true, orgSide=true) → right-aligned, primary gradient
///   • Other staff (isMe=false, orgSide=true)       → left-aligned, white bubble
///
/// Staff Direct (orgSide=null — legacy two-tone):
///   • isMe=true  → right-aligned, primary gradient
///   • isMe=false → left-aligned, flat light-blue color, no gradient
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
      home: Scaffold(
        body: SizedBox(width: 400, height: 600, child: child),
      ),
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
    testWidgets('current user message is right-aligned regardless of role',
        (tester) async {
      await tester.pumpWidget(
        _bubble(isMe: true, senderIsOrgSide: true), // staff viewer, own message
      );
      expect(_bubbleAlignment(tester), Alignment.centerRight);
    });

    testWidgets('other-user message is left-aligned regardless of role',
        (tester) async {
      await tester.pumpWidget(
        _bubble(isMe: false, senderIsOrgSide: false), // guardian sender, not me
      );
      expect(_bubbleAlignment(tester), Alignment.centerLeft);
    });
  });

  group('MessageBubble — Room/Admin Chat bubble fill', () {
    testWidgets(
        'current user (isMe) always gets primary gradient regardless of orgSide',
        (tester) async {
      // isMe=true, orgSide=true (current staff member's own message)
      await tester.pumpWidget(_bubble(isMe: true, senderIsOrgSide: true));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNotNull, reason: 'should have gradient');
      expect(deco.color, isNull, reason: 'gradient, not flat color');
      final grad = deco.gradient as LinearGradient;
      expect(
        grad.colors.first,
        equals(AppColors.primaryGradientColors.first),
        reason: 'should use primary gradient colors',
      );
    });

    testWidgets(
        'current guardian (isMe, orgSide=false) gets primary gradient',
        (tester) async {
      await tester.pumpWidget(_bubble(isMe: true, senderIsOrgSide: false));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNotNull);
      final grad = deco.gradient as LinearGradient;
      expect(grad.colors.first, equals(AppColors.primaryGradientColors.first));
    });

    testWidgets('other org-side sender (staff, not me) gets white bubble',
        (tester) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: true));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNull, reason: 'white bubble has no gradient');
      expect(deco.color, equals(Colors.white),
          reason: 'staff non-me bubble must be white');
    });

    testWidgets('guardian sender (not me) gets pink gradient', (tester) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: false));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNotNull, reason: 'should have pink gradient');
      expect(deco.color, isNull);
      final grad = deco.gradient as LinearGradient;
      expect(
        grad.colors.first,
        equals(AppColors.pinkGradientColors.first),
        reason: 'should use pink gradient',
      );
    });
  });

  group('MessageBubble — Staff Direct (orgSide=null, legacy two-tone)', () {
    testWidgets('own message gets gradient', (tester) async {
      await tester.pumpWidget(_bubble(isMe: true, senderIsOrgSide: null));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNotNull);
    });

    testWidgets("other's message gets flat light-blue, no gradient",
        (tester) async {
      await tester.pumpWidget(_bubble(isMe: false, senderIsOrgSide: null));
      final deco = _bubbleDecoration(tester);
      expect(deco.gradient, isNull, reason: 'no gradient for legacy receiver');
      expect(deco.color, equals(const Color.fromRGBO(220, 230, 255, 1)));
    });
  });
}
