import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_connection_status.dart';

/// A subtle strip that surfaces degraded realtime health (P2). Renders nothing
/// while `connected` — and while the very first `connecting`, where the normal
/// loading spinner already communicates progress — so it only appears when live
/// updates are actually impaired: reconnecting after a drop, or offline.
class MessagingConnectionBanner extends StatelessWidget {
  const MessagingConnectionBanner({super.key, required this.status});

  final MessagingConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (String? label, Color bg, Color fg, bool spinner) = switch (status) {
      MessagingConnectionStatus.connected => (null, Colors.transparent, Colors.transparent, false),
      MessagingConnectionStatus.connecting => (null, Colors.transparent, Colors.transparent, false),
      MessagingConnectionStatus.reconnecting => (
          'Reconnecting…',
          const Color(0xFFFFF4E5),
          const Color(0xFF8A5A00),
          true,
        ),
      MessagingConnectionStatus.offline => (
          "You're offline — messages will sync when the connection returns",
          const Color(0xFFF1F1F4),
          const Color(0xFF5B5B66),
          false,
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: label == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(status),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: bg,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (spinner) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(Icons.cloud_off_rounded, size: 14, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
