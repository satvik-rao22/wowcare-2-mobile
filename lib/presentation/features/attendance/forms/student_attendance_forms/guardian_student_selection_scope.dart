import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';

/// Parent / guardian sign-in & sign-out selection must only list that user's
/// linked children. Staff and admin flows pass through unchanged ([null]).
///
/// Returns **uppercase** trimmed student codes for stable matching against API
/// payloads. Empty set means the parent account has no linked children in the
/// current school context.
Future<Set<String>?> loadGuardianStudentAllowlistForSelection(
  BuildContext context,
) async {
  final isParent = context.read<RoleProvider>().isParent;
  if (!isParent) return null;

  final provider = context.read<ParentChildProvider>();
  await provider.ensureLoaded();

  return {
    for (final c in provider.children)
      if (c.code.trim().isNotEmpty) c.code.trim().toUpperCase(),
  };
}

bool studentCodeAllowedForGuardianAllowlist(
  String studentCode,
  Set<String> allowUppercase,
) {
  final code = studentCode.trim().toUpperCase();
  return code.isNotEmpty && allowUppercase.contains(code);
}
