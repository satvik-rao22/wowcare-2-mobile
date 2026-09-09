import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// Parent / guardian sign-in & sign-out selection must only list that user's
/// linked children. Staff and admin flows pass through unchanged ([null]).
///
/// Returns **uppercase** trimmed student codes for stable matching against API
/// payloads. Empty set means the parent account has no linked children in the
/// current school context.
Future<Set<String>?> loadGuardianStudentAllowlistForSelection(
  BuildContext context,
) async {
  final isParent = context.read<RoleCubit>().isParent;
  if (!isParent) return null;

  final provider = context.read<ParentChildCubit>();
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
