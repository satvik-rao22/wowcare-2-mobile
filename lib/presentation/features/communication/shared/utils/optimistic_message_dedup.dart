import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

/// How far apart (in send time) an optimistic message and an incoming confirmed
/// message may be and still be treated as the same send, when no shared code
/// links them yet.
///
/// A still-pending optimistic message never carries the server's real `code`
/// (the backend isn't told the client's `localTempCode`), so when Firestore
/// delivers the confirmed copy BEFORE this send's own REST response returns to
/// swap it in, the only link is a content match. This window bounds that match.
const Duration kOptimisticContentMatchWindow = Duration(seconds: 30);

/// Returns the optimistic [pending] messages that have NOT yet been confirmed by
/// the [fresh] (server-confirmed) list, so the caller can keep showing them.
///
/// Matching, in order of strength:
///  1. exact `code` — a pending whose code already appears in [fresh] is
///     confirmed and dropped;
///  2. content match — a still-`pending` message is confirmed by a [fresh]
///     message with the same `senderCode` + `text` sent within [window].
///
/// The content match is **greedy one-to-one**: pendings are considered
/// oldest-first and each claims the nearest-in-time confirmation that no other
/// pending has already claimed. This is the key correctness property — two
/// quick identical messages (e.g. "Ok" twice) can no longer both collapse onto
/// a single confirmation (which would drop one of them) nor both survive
/// against two confirmations (which would duplicate them).
///
/// `failed` messages are always kept: a failed send must never be silently
/// hidden just because its text happens to match another message.
List<MessageEntity> unconfirmedOptimisticMessages({
  required List<MessageEntity> pending,
  required List<MessageEntity> fresh,
  Duration window = kOptimisticContentMatchWindow,
}) {
  if (pending.isEmpty) return const <MessageEntity>[];

  final freshCodes = <String>{
    for (final f in fresh)
      if (f.code.isNotEmpty) f.code,
  };

  // Claim confirmations for pendings oldest-first, one confirmation per pending.
  final claimedFresh = <int>{};
  final absorbed = Set<MessageEntity>.identity();
  final chronological = [
    for (final m in pending)
      if (m.isPending && !(m.code.isNotEmpty && freshCodes.contains(m.code))) m,
  ]..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  for (final m in chronological) {
    var bestIndex = -1;
    var bestDelta = window;
    for (var i = 0; i < fresh.length; i++) {
      if (claimedFresh.contains(i)) continue;
      final f = fresh[i];
      if (f.senderCode != m.senderCode || f.text != m.text) continue;
      final delta = f.sentAt.difference(m.sentAt).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestIndex = i;
      }
    }
    if (bestIndex >= 0) {
      claimedFresh.add(bestIndex);
      absorbed.add(m);
    }
  }

  return pending.where((m) {
    // Confirmed by exact code — drop the optimistic copy.
    if (m.code.isNotEmpty && freshCodes.contains(m.code)) return false;
    // A failed send is always kept (never silently hidden by a content match).
    if (!m.isPending) return true;
    // A pending is kept only if no confirmation claimed it.
    return !absorbed.contains(m);
  }).toList();
}
