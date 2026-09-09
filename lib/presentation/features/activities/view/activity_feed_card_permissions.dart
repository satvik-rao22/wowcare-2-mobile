import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'activity_item.dart';

/// True when the viewer's ACTIVE persona is an admin persona (not the staff
/// persona). Reads the live RoleCubit so the current persona — not a once-read
/// staffType — decides whether admin approve/reject actions are shown. A
/// dual-role user currently acting as staff gets `false`.
bool activeAdminPersona(BuildContext context) {
  final role = context.read<RoleCubit>();
  return role.isAdmin && !role.isStaff;
}

String normalizeApprovalStatus(String? rawStatus) {
  final raw = (rawStatus ?? '').trim().toUpperCase();
  return raw.isEmpty ? 'NOT_REQUIRED' : raw;
}

bool isIncidentActivityItem(ActivityItem activity) {
  final name = activity.name.trim().toLowerCase();
  return name == 'incident' || name.contains('incident');
}

bool isAttendanceCardActivityItem(ActivityItem activity) {
  final normalized = activity.name.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  return normalized == 'signin' ||
      normalized == 'signout' ||
      normalized == 'transfer' ||
      normalized == 'markedabsent' ||
      normalized == 'absent';
}

bool staffMayEditDeleteByApprovalStatus(String normalizedStatus) {
  return normalizedStatus == 'PENDING_ADMIN_APPROVAL' ||
      normalizedStatus == 'PENDING';
}

bool staffMayEditByApprovalStatus(String normalizedStatus) {
  return staffMayEditDeleteByApprovalStatus(normalizedStatus) ||
      normalizedStatus == 'NOT_REQUIRED';
}

bool canEditActivityItem(
  ActivityItem activity, {
  required bool isAdminPersona,
  String? viewerStaffCode,
}) {
  final status = normalizeApprovalStatus(activity.approvalStatus);
  if (status == 'REJECTED') return false;

  if (isAdminPersona) {
    return !isAttendanceCardActivityItem(activity);
  }
  final viewerCode = (viewerStaffCode ?? '').trim().toUpperCase();
  final presentCode = (activity.staffPresentCode ?? '').trim().toUpperCase();
  if (viewerCode.isEmpty || presentCode.isEmpty || viewerCode != presentCode) {
    return false;
  }
  if (!staffMayEditByApprovalStatus(status)) return false;
  return true;
}

bool canDeleteActivityItem(
  ActivityItem activity, {
  required bool isAdminPersona,
}) {
  final status = normalizeApprovalStatus(activity.approvalStatus);
  if (isAdminPersona) {
    return true;
  }
  if (status == 'REJECTED') return false;
  if (!staffMayEditDeleteByApprovalStatus(status)) return false;
  if (isIncidentActivityItem(activity) &&
      isLikelyAdminDesignationLabel(activity.createdBy)) {
    return false;
  }
  return true;
}

bool isLikelyAdminDesignationLabel(String raw) {
  final v = raw.trim().toUpperCase();
  if (v.isEmpty) return false;
  const directMatches = <String>{
    'SCHOOL_ADMIN',
    'ORGANIZATION_ADMIN',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'OWNER',
  };
  if (directMatches.contains(v)) return true;
  return v.contains('ADMIN') || v.contains('DIRECTOR') || v.contains('OWNER');
}

bool canAdminApproveOrRejectActivityItem(
  ActivityItem activity, {
  required bool isAdminPersona,
}) {
  if (!isAdminPersona) return false;
  final status = normalizeApprovalStatus(activity.approvalStatus);
  return status == 'PENDING_ADMIN_APPROVAL' || status == 'PENDING';
}
