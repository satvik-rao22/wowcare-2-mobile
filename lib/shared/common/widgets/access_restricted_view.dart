import 'package:flutter/material.dart';

import '../../../presentation/features/students/module_access.dart';

/// Shown in place of content the user has no read permission for, so a
/// restricted module reads as "not yours" instead of "broken" or "empty".
///
/// Use this for a surface the user reached legitimately but cannot read (a tab
/// beside one they can read, a deep link). Where a whole feature is
/// unreadable, hide its entry point instead — see `CustomDrawer`.
class AccessRestrictedView extends StatelessWidget {
  const AccessRestrictedView({super.key, this.message});

  /// Defaults to [ModuleAccess.featureRestrictedMessage] so the wording matches
  /// the toast shown when a restricted action is attempted.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 44, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'Access restricted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? ModuleAccess.featureRestrictedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
