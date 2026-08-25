import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer skeleton for chat thread loading — replaces CircularProgressIndicator
/// in StaffMessagingThread, ParentMessagingThread, and ConversationThreadScreen.
///
/// Shows alternating sent/received bubble skeletons to mimic a real conversation.
class ChatThreadShimmer extends StatelessWidget {
  const ChatThreadShimmer({super.key, this.itemCount = 10});

  final int itemCount;

  static const _baseColor = Color(0xFFE2E8F0);
  static const _highlightColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _baseColor,
      highlightColor: _highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, i) => _BubbleShimmerRow(isMe: i.isEven),
      ),
    );
  }
}

class _BubbleShimmerRow extends StatelessWidget {
  const _BubbleShimmerRow({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bubbleWidth = 140.0 + (isMe ? 60.0 : 40.0) * ((isMe ? 1 : 0.7));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[_Circle(size: 32), const SizedBox(width: 8)],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                _Rect(width: 72, height: 10, radius: 6),
                const SizedBox(height: 4),
              ],
              _Bubble(width: bubbleWidth, isMe: isMe),
              const SizedBox(height: 4),
              _Rect(width: 44, height: 8, radius: 4),
            ],
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.width, required this.isMe});

  final double width;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final hasSecondLine = width > 160;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rect(width: width * 0.85, height: 11, radius: 6),
          if (hasSecondLine) ...[
            const SizedBox(height: 6),
            _Rect(width: width * 0.55, height: 11, radius: 6),
          ],
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

class _Rect extends StatelessWidget {
  const _Rect({
    required this.width,
    required this.height,
    required this.radius,
  });
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
