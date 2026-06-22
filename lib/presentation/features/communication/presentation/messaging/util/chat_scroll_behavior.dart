import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// Keyboard-aware, "near-bottom" scroll tracking for a chat message list,
/// matching WhatsApp/Telegram/Messenger behavior:
///
///  - Opening the keyboard scrolls to the latest message — but only when the
///    user is already near the bottom, never while reading older history.
///  - Sending a message always scrolls to bottom ([scrollToBottom]).
///  - An incoming message scrolls to bottom if near it, otherwise raises
///    [showNewMessageIndicator] instead of jumping the view.
class ChatScrollBehavior {
  ChatScrollBehavior(
    this.controller, {
    this.bottomThreshold = 120,
    this.reverse = false,
  });

  final AutoScrollController controller;

  /// Distance (in logical pixels) from the end of the scroll extent within
  /// which the user is still considered "at the bottom".
  final double bottomThreshold;

  /// Whether the list this controller drives is built with
  /// `ListView(reverse: true)` (index 0 = newest, resting at `pixels == 0`)
  /// rather than the default `reverse: false` (newest at `maxScrollExtent`).
  /// "Bottom" means opposite ends of the scroll range depending on this —
  /// get it wrong and every method below scrolls to the *oldest* message
  /// instead of the newest.
  final bool reverse;

  /// Flips to true when a message arrives while the user is reading older
  /// history, so the caller can show a "↓ New Messages" chip instead of
  /// forcing a jump. Reset to false once [scrollToBottom] runs.
  final ValueNotifier<bool> showNewMessageIndicator = ValueNotifier(false);

  Timer? _keyboardSettleTimer;

  bool get isNearBottom {
    if (!controller.hasClients) return true;
    final position = controller.position;
    if (reverse) return position.pixels <= bottomThreshold;
    return (position.maxScrollExtent - position.pixels) <= bottomThreshold;
  }

  /// Scrolls to the bottom of the list. Always defers to a post-frame
  /// callback first so `maxScrollExtent` reflects layout that already
  /// accounts for whatever triggered the call (a just-sent message, a
  /// just-arrived realtime message, …) — calling this synchronously from a
  /// Bloc listener runs *before* the rebuild that adds the new item, landing
  /// one message short of the true bottom.
  ///
  /// [onSettled], if given, fires once the list has actually finished
  /// landing on the true edge (after the correction pass below) — callers
  /// doing the very first open of a thread can use this to keep the real
  /// message list hidden behind a loading placeholder until this fires,
  /// so the user never sees it visibly jump/scroll from the top down to the
  /// latest message; it just appears already positioned there.
  void scrollToBottom({bool animate = true, VoidCallback? onSettled}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) {
        onSettled?.call();
        return;
      }
      showNewMessageIndicator.value = false;
      _scrollToEdge(animate: animate, onSettled: onSettled);
    });
  }

  void _scrollToEdge({required bool animate, VoidCallback? onSettled}) {
    if (!controller.hasClients) {
      onSettled?.call();
      return;
    }
    final target = reverse ? 0.0 : controller.position.maxScrollExtent;
    if (animate) {
      controller
          .animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) => _settleToTrueEdge(onSettled: onSettled));
    } else {
      controller.jumpTo(target);
      _settleToTrueEdge(onSettled: onSettled);
    }
  }

  /// A chat bubble's height isn't known until its content (text length,
  /// attachments, reactions) has actually laid out, so `maxScrollExtent` at
  /// the moment of the first jump/animate can still be an underestimate —
  /// landing just short of the true latest message instead of fully on it.
  /// One extra post-frame correction snaps the rest of the way once layout
  /// has settled and `maxScrollExtent` is accurate.
  void _settleToTrueEdge({VoidCallback? onSettled}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) {
        onSettled?.call();
        return;
      }
      final target = reverse ? 0.0 : controller.position.maxScrollExtent;
      final current = controller.position.pixels;
      if ((target - current).abs() > 1) {
        controller.jumpTo(target);
      }
      onSettled?.call();
    });
  }

  /// Call on every `WidgetsBindingObserver.didChangeMetrics` tick while the
  /// keyboard is opening. The system keyboard's open animation fires many
  /// metrics-changed events in quick succession — scrolling on each one
  /// would restart the scroll animation mid-flight (visible stutter), so
  /// this debounces down to a single [scrollToBottom] once the inset
  /// stops changing. Only scrolls when the user was already near the
  /// bottom. WhatsApp-style: always scroll to show latest message above
  /// keyboard when typing, regardless of scroll position.
  void onKeyboardOpened() {
    // Always scroll to bottom when keyboard opens, to show latest message
    // above the keyboard input field, matching WhatsApp behavior
    _keyboardSettleTimer?.cancel();
    _keyboardSettleTimer = Timer(const Duration(milliseconds: 120), scrollToBottom);
  }

  /// Call whenever the message list grows with a message that wasn't sent
  /// by the local user (an incoming message). Scrolls to bottom when already
  /// near it; otherwise surfaces the "new messages" indicator.
  void onIncomingMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isNearBottom) {
        scrollToBottom();
      } else {
        showNewMessageIndicator.value = true;
      }
    });
  }

  void dispose() {
    _keyboardSettleTimer?.cancel();
    showNewMessageIndicator.dispose();
  }
}
