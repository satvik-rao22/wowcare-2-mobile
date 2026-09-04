import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/docked_bar.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// The row that docks under the roster while students are being picked (5a).
///
/// With nothing picked the key is off and says so, rather than being pink and
/// doing nothing. It sits above the tab bar, so the five slots are still
/// reachable while a selection is being made.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    required this.selectedCount,
    required this.onClear,
    required this.onSignIn,
    super.key,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    // No safe-area pad of its own: the tab bar sits under this and carries
    // the inset for both.
    return DockedBar(
      child: Row(
        spacing: StudentsSizes.dockGap,
        children: <Widget>[
          SecondaryKey(
            label: AppStrings.clear,
            expand: false,
            padding: StudentsSizes.dockSubKeyPad,
            onTap: onClear,
          ),
          Expanded(
            child: PrimaryKey(
              label: hasSelection
                  ? StudentsStrings.signInCount(selectedCount)
                  : StudentsStrings.pickStudents,
              enabled: hasSelection,
              onTap: onSignIn,
            ),
          ),
        ],
      ),
    );
  }
}
