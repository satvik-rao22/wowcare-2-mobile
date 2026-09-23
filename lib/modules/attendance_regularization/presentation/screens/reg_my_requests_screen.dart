import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';

import '../entry/reg_requests_list.dart';
import '../widgets/reg_scaffold.dart';

/// Staff "my regularizations", the destination of the approval notification.
///
/// Deliberately thin: the list, its paging and its actions live in
/// [RegRequestsList], which the attendance profile embeds. No staff code is
/// passed — the token already scopes the request to the caller.
class RegMyRequestsScreen extends StatelessWidget {
  const RegMyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RegScaffold(
      title: 'My regularizations',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            Av2Spacing.md, 0, Av2Spacing.md, Av2Spacing.lg),
        child: RegRequestsList.connected(),
      ),
    );
  }
}
