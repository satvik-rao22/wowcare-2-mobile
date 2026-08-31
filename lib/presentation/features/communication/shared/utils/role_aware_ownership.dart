import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

/// A single account can hold more than one persona in the SAME conversation
/// — e.g. a staff member who is also the enrolled child's guardian shows up
/// in `participants` twice (once per role), sharing one `userCode`.
/// `isSentByMe` is only ever computed upstream by comparing that raw
/// userCode against the viewer's own, which can't tell those two personas
/// apart: a message the account sent under its OTHER persona would
/// otherwise render as "mine" on any screen that can be viewed as either
/// persona.
///
/// [viewingAsGuardian] tells us which persona the CURRENT screen instance is
/// showing (see `ParentMessagingThread.isGuardian`). Narrows (never widens)
/// [Message.isSentByMe] to `false` when [m]'s own [Message.senderRole] says
/// it was sent under the other persona. A message with no senderRole
/// recorded (older cached rows, or screens where persona ambiguity isn't
/// possible) is returned unchanged — there's no positive evidence of a
/// mismatch to act on.
Message withRoleAwareOwnership(Message m, {required bool viewingAsGuardian}) {
  if (!m.isSentByMe) return m;
  final role = m.senderRole;
  if (role == null || role.isEmpty) return m;
  final senderIsGuardianRole =
      ParticipantRole.fromApiString(role) == ParticipantRole.parent;
  if (senderIsGuardianRole == viewingAsGuardian) return m;
  return m.copyWith(isSentByMe: false);
}
