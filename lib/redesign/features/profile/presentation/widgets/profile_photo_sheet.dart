import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// What the Change photo key opens.
enum PhotoChoice { choose, remove }

/// The photo sheet: choose a new one, or take the one on file away.
///
/// Resolves to the choice made, or null when the sheet is dismissed. Remove
/// only appears when there is a photo to remove.
Future<PhotoChoice?> showProfilePhotoSheet(
  BuildContext context, {
  required bool hasPhoto,
}) => showAppSheet<PhotoChoice>(
  context,
  builder: (sheetContext) => AppBottomSheet(
    title: ProfileStrings.photoSheetTitle,
    subtitle: ProfileStrings.photoSheetSubtitle,
    body: const SizedBox.shrink(),
    footer: <Widget>[
      if (hasPhoto)
        DestructiveKey(
          label: ProfileStrings.removePhoto,
          onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.remove),
        ),
      PrimaryKey(
        label: ProfileStrings.chooseFromLibrary,
        onTap: () => Navigator.of(sheetContext).pop(PhotoChoice.choose),
      ),
    ],
  ),
);
