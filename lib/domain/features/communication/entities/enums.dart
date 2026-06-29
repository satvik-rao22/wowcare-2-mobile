/// Conversation types in the WowCare communication module.
///
/// ROOM_CHAT: Student-scoped group conversation.
///   Participants: Parents, Teachers, Staff, Admins, Directors
///
/// ADMIN_CHAT: Administrative conversation tied to a student.
///   Participants: Parents, Admins, Directors
///   Excluded: Teachers, Staff
///
/// STAFF_DIRECT: Peer-to-peer staff conversation. No student scope.
///   Participants: Teachers, Staff, Admins, Directors
///   Excluded: Parents
enum ConversationType {
  roomChat,
  adminChat,
  staffDirect;

  /// Serialise to the string sent by the backend API.
  String toApiString() {
    switch (this) {
      case ConversationType.roomChat:
        return 'ROOM_CHAT';
      case ConversationType.adminChat:
        return 'ADMIN_CHAT';
      case ConversationType.staffDirect:
        return 'STAFF_DIRECT';
    }
  }

  /// Parse from the string returned by the backend API.
  static ConversationType fromApiString(String value) {
    switch (value.toUpperCase()) {
      case 'ROOM_CHAT':
        return ConversationType.roomChat;
      case 'ADMIN_CHAT':
        return ConversationType.adminChat;
      case 'STAFF_DIRECT':
        return ConversationType.staffDirect;
      default:
        throw ArgumentError('Unknown ConversationType: $value');
    }
  }

  /// Whether this conversation type is scoped to a student.
  bool get isStudentScoped =>
      this == ConversationType.roomChat || this == ConversationType.adminChat;
}

/// Roles a user can have within a conversation.
/// Maps to the [role] field on [ConversationParticipant].
enum ParticipantRole {
  parent,
  teacher,
  staff,
  admin,
  director;

  String toApiString() {
    switch (this) {
      case ParticipantRole.parent:
        return 'PARENT';
      case ParticipantRole.teacher:
        return 'TEACHER';
      case ParticipantRole.staff:
        return 'STAFF';
      case ParticipantRole.admin:
        return 'ADMIN';
      case ParticipantRole.director:
        return 'DIRECTOR';
    }
  }

  /// Parse from the role string on a conversation participant record.
  ///
  /// WowCare backend may send granular role codes (TEACHER, DIRECTOR,
  /// SCHOOL_ADMIN, ORGANIZATION_ADMIN, GUARDIAN) or the normalised
  /// persona strings used by RoleCubit ('admin', 'staff', 'parent').
  /// Both forms are handled here.
  static ParticipantRole fromApiString(String value) {
    final v = value.toUpperCase();

    // Exact matches (preferred — sent by conversations API)
    if (v == 'PARENT' || v == 'GUARDIAN') return ParticipantRole.parent;
    if (v == 'TEACHER') return ParticipantRole.teacher;
    if (v == 'DIRECTOR' || v == 'ASSISTANT_DIRECTOR') return ParticipantRole.director;
    // OWNER is the highest org-level role (above Admin) per the Staff
    // module's real designation list (staff_filter_screen.dart's
    // _designationCodes) — was previously falling through to the generic
    // `staff` default below, which incorrectly failed `canJoinAdminChat`
    // and any other "is this an admin" check for an Owner-designated user.
    if (v == 'ADMIN' ||
        v == 'SCHOOL_ADMIN' ||
        v == 'ORGANIZATION_ADMIN' ||
        v == 'OWNER') {
      return ParticipantRole.admin;
    }
    if (v == 'STAFF') return ParticipantRole.staff;

    // RoleCubit persona strings (lowercase, used in app-level checks)
    if (v == 'parent'.toUpperCase()) return ParticipantRole.parent;
    if (v == 'staff'.toUpperCase()) return ParticipantRole.staff;
    if (v == 'admin'.toUpperCase()) return ParticipantRole.admin;

    // Substring fallbacks for multi-word roles (e.g. 'HEAD_TEACHER')
    if (v.contains('GUARDIAN') || v.contains('PARENT')) return ParticipantRole.parent;
    if (v.contains('DIRECTOR')) return ParticipantRole.director;
    if (v.contains('ADMIN')) return ParticipantRole.admin;
    if (v.contains('TEACHER')) return ParticipantRole.teacher;
    if (v.contains('STAFF')) return ParticipantRole.staff;

    // Unknown role — default to staff (least privileged non-parent)
    return ParticipantRole.staff;
  }

  /// Whether this role is allowed to participate in an Admin Chat.
  /// Blocked: TEACHER, STAFF.
  bool get canJoinAdminChat =>
      this == ParticipantRole.parent ||
      this == ParticipantRole.admin ||
      this == ParticipantRole.director;

  /// Whether this role is allowed to participate in Staff Direct.
  /// Blocked: PARENT.
  bool get canJoinStaffDirect =>
      this == ParticipantRole.teacher ||
      this == ParticipantRole.staff ||
      this == ParticipantRole.admin ||
      this == ParticipantRole.director;

  /// Whether this role maps to the WowCare 'admin' app persona.
  /// Used when checking RoleCubit.isAdmin alongside participant role.
  bool get isAdminPersona =>
      this == ParticipantRole.admin || this == ParticipantRole.director;
}

/// Type of a message payload.
enum MessageType {
  text,
  image,
  file,
  system;

  String toApiString() {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.system:
        return 'SYSTEM';
    }
  }

  static MessageType fromApiString(String value) {
    switch (value.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'SYSTEM':
        return MessageType.system;
      case 'TEXT':
      default:
        return MessageType.text;
    }
  }
}

/// Delivery / sync status of a locally composed message.
enum MessageStatus {
  /// Queued locally; API call not yet made.
  pending,

  /// API accepted the message; awaiting server confirmation.
  sending,

  /// Server confirmed; visible to all participants.
  sent,

  /// Delivered to at least one recipient device.
  delivered,

  /// API call failed; can be retried.
  failed;

  String toApiString() => name.toUpperCase();

  static MessageStatus fromApiString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return MessageStatus.pending;
      case 'SENDING':
        return MessageStatus.sending;
      case 'SENT':
        return MessageStatus.sent;
      case 'DELIVERED':
        return MessageStatus.delivered;
      case 'FAILED':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
}

/// Type of file attachment.
enum AttachmentType {
  image,
  document,
  video,
  audio,
  other;

  /// Derive from MIME type string.
  static AttachmentType fromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (lower.startsWith('image/')) return AttachmentType.image;
    if (lower.startsWith('video/')) return AttachmentType.video;
    if (lower.startsWith('audio/')) return AttachmentType.audio;
    if (lower.contains('pdf') ||
        lower.contains('document') ||
        lower.contains('spreadsheet') ||
        lower.contains('presentation') ||
        lower.contains('text/')) {
      return AttachmentType.document;
    }
    return AttachmentType.other;
  }

  String toApiString() => name.toUpperCase();
}

/// Status of a pending offline sync operation.
enum SyncOperationStatus {
  pending,
  processing,
  completed,
  failed;

  String toStorageString() => name.toUpperCase();

  static SyncOperationStatus fromStorageString(String value) {
    switch (value.toUpperCase()) {
      case 'PROCESSING':
        return SyncOperationStatus.processing;
      case 'COMPLETED':
        return SyncOperationStatus.completed;
      case 'FAILED':
        return SyncOperationStatus.failed;
      case 'PENDING':
      default:
        return SyncOperationStatus.pending;
    }
  }
}

/// Type of offline sync operation to be retried.
enum SyncOperationType {
  sendMessage,
  editMessage,
  deleteMessage,
  addReaction,
  removeReaction,
  markRead,
  togglePrivateMode;

  String toStorageString() {
    switch (this) {
      case SyncOperationType.sendMessage:
        return 'SEND_MESSAGE';
      case SyncOperationType.editMessage:
        return 'EDIT_MESSAGE';
      case SyncOperationType.deleteMessage:
        return 'DELETE_MESSAGE';
      case SyncOperationType.addReaction:
        return 'ADD_REACTION';
      case SyncOperationType.removeReaction:
        return 'REMOVE_REACTION';
      case SyncOperationType.markRead:
        return 'MARK_READ';
      case SyncOperationType.togglePrivateMode:
        return 'TOGGLE_PRIVATE_MODE';
    }
  }

  static SyncOperationType fromStorageString(String value) {
    switch (value.toUpperCase()) {
      case 'EDIT_MESSAGE':
        return SyncOperationType.editMessage;
      case 'DELETE_MESSAGE':
        return SyncOperationType.deleteMessage;
      case 'ADD_REACTION':
        return SyncOperationType.addReaction;
      case 'REMOVE_REACTION':
        return SyncOperationType.removeReaction;
      case 'MARK_READ':
        return SyncOperationType.markRead;
      case 'TOGGLE_PRIVATE_MODE':
        return SyncOperationType.togglePrivateMode;
      case 'SEND_MESSAGE':
      default:
        return SyncOperationType.sendMessage;
    }
  }
}
