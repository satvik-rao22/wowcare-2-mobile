import 'package:equatable/equatable.dart';

/// A bulk-messaging recipient — a staff member or a student — carried between
/// the selection screen, the composition cubit/screen and the route args.
///
/// This is presentation view-config, not wire data (Mandate 8): it is built
/// from `StaffMember`/`Student` entities in the selection screen and read back
/// when broadcasting per-recipient sends. It replaces the previous untyped
/// `Map<String, dynamic>`; only the fields the old map actually carried and
/// that some site read are modelled (the always-constant `dateTime`/`isSigned`/
/// `isFavorite`/`unreadCount` placeholders were write-only and are dropped).
class MessagingRecipient extends Equatable {
  const MessagingRecipient({
    required this.code,
    required this.name,
    this.userCode,
    this.avatar = '',
    this.designation,
    this.status = '',
    this.classroom = '',
    this.classroomCode,
    this.tags = const [],
    this.hasGuardian = true,
    this.studentCode,
    this.staffCode,
    this.message = '',
  });

  /// Staff `code` or student `code` — the primary identifier.
  final String code;
  final String name;

  /// Staff user code (used first when resolving [resolvedCode]); null for students.
  final String? userCode;
  final String avatar;

  /// Staff designation; null for students.
  final String? designation;
  final String status;
  final String classroom;

  /// Student classroom code; null for staff.
  final String? classroomCode;

  /// Student tags; empty for staff.
  final List<String> tags;

  /// Student has at least one guardian to message; always true for staff.
  final bool hasGuardian;
  final String? studentCode;
  final String? staffCode;

  /// Always '' today — retained so the selection screen's search (which reads
  /// it) behaves exactly as before.
  final String message;

  /// The code used to address this recipient — mirrors the old `_recipientCode`
  /// precedence: userCode → code → staffCode → studentCode.
  String get resolvedCode =>
      (userCode ?? code.ifNotEmpty ?? staffCode ?? studentCode ?? '').trim();

  @override
  List<Object?> get props => [
    code,
    name,
    userCode,
    avatar,
    designation,
    status,
    classroom,
    classroomCode,
    tags,
    hasGuardian,
    studentCode,
    staffCode,
    message,
  ];
}

extension _NonEmpty on String {
  String? get ifNotEmpty => isEmpty ? null : this;
}
