import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// What sits under the name in 13a's hero: the Change photo key, the invite
/// to add one, the upload's progress, or the card saying it did not go.
class PhotoBlock extends StatelessWidget {
  const PhotoBlock({
    required this.photo,
    required this.hasPhoto,
    required this.progress,
    required this.onChange,
    required this.onRetry,
    super.key,
  });

  final PhotoStatus photo;
  final bool hasPhoto;

  /// 0 to 1 while [photo] is uploading.
  final double progress;

  /// Opens the photo sheet.
  final VoidCallback onChange;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (photo) {
    PhotoStatus.uploading => _Uploading(progress: progress),
    PhotoStatus.failed => _Failed(onRetry: onRetry),
    PhotoStatus.idle when hasPhoto => Align(
      alignment: Alignment.centerLeft,
      child: SecondaryKey(
        label: ProfileStrings.changePhoto,
        expand: false,
        padding: ProfileSizes.smallKeyPad,
        onTap: onChange,
      ),
    ),
    PhotoStatus.idle => _NoPhotoYet(onChange: onChange),
  };
}

/// The invite the frame shows a person with no photo on file.
class _NoPhotoYet extends StatelessWidget {
  const _NoPhotoYet({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: ProfileSizes.photoBlockGap,
    children: <Widget>[
      Text(
        ProfileStrings.noPhotoHint,
        style: ProfileTextStyles.alertBody.copyWith(
          color: context.colours.ink2,
        ),
      ),
      PrimaryKey(
        label: ProfileStrings.chooseFromLibrary,
        expand: false,
        padding: ProfileSizes.navyKeyPad,
        onTap: onChange,
      ),
    ],
  );
}

/// The percentage, the trough, and the note about the last stretch.
class _Uploading extends StatelessWidget {
  const _Uploading({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ProfileSizes.photoBlockGap,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              ProfileStrings.uploading,
              style: ProfileTextStyles.uploadLabel.copyWith(color: c.ink),
            ),
            Text(
              ProfileStrings.percent(progress),
              style: ProfileTextStyles.uploadPercent.copyWith(color: c.pink),
            ),
          ],
        ),
        Trough(fraction: progress, fill: c.pink),
        Text(
          ProfileStrings.uploadingNote,
          style: ProfileTextStyles.alertBody.copyWith(color: c.ink3),
        ),
      ],
    );
  }
}

/// The red card 13a draws when the upload does not land. It says what is
/// still true, which is that nothing else changed.
class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.alertDanger(c),
      padding: ProfileSizes.notePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ProfileSizes.photoBlockGap,
        children: <Widget>[
          Text(
            ProfileStrings.photoFailedTitle,
            style: ProfileTextStyles.alertTitle.copyWith(color: c.dangerFg),
          ),
          Text(
            ProfileStrings.photoFailedBody,
            style: ProfileTextStyles.alertBody.copyWith(color: c.dangerFg),
          ),
          DestructiveKey(
            label: AppStrings.retry,
            expand: false,
            padding: ProfileSizes.smallKeyPad,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
