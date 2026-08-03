import 'package:equatable/equatable.dart';

/// Lightweight staff record used by the Staff Messaging inbox search.
///
/// Only the fields needed to render a directory tile and start a conversation
/// are captured here — avoids pulling the full staff module into communication.
class MessagingStaffResult extends Equatable {
  const MessagingStaffResult({
    required this.userCode,
    required this.staffCode,
    required this.name,
    required this.designation,
    required this.status,
    this.avatarAssetCode,
  });

  final String userCode;
  final String staffCode;
  final String name;
  final String designation;
  final String status;
  final String? avatarAssetCode;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isUpcoming => status.toUpperCase() == 'UPCOMING';

  @override
  List<Object?> get props =>
      [userCode, staffCode, name, designation, status, avatarAssetCode];
}
