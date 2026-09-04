import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_profile_cubit.dart';

/// The classroom photo's four states (7f): nothing on file, uploading, on
/// file, and an upload that failed.
///
/// A failure never loses what was already on file, which is what the line
/// under it promises.
class PhotoWell extends StatelessWidget {
  const PhotoWell({
    required this.status,
    this.fileName,
    this.progress = 0,
    this.onRemove,
    this.onRetry,
    super.key,
  });

  final PhotoUploadStatus status;

  /// The file being uploaded, or the one on file.
  final String? fileName;

  /// How far the upload has got, 0 to 1.
  final double progress;

  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return switch (status) {
      PhotoUploadStatus.idle => _empty(c),
      PhotoUploadStatus.uploading => _uploading(c),
      PhotoUploadStatus.done => _done(c),
      PhotoUploadStatus.failed => _failed(c),
    };
  }

  Widget _empty(Colourway c) => AppWell(
    padding: ClassroomsSizes.uploadWellPad,
    child: Row(
      spacing: ClassroomsSizes.uploadGap,
      children: <Widget>[
        _Glyph(icon: AppIcons.upload, color: c.ink2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ClassroomsSizes.statTileTextGap,
            children: <Widget>[
              Text(
                ClassroomsStrings.addPhotoTitle,
                style: ClassroomsTextStyles.uploadTitle.copyWith(color: c.ink),
              ),
              Text(
                ClassroomsStrings.addPhotoHint,
                style: ClassroomsTextStyles.uploadHint.copyWith(color: c.ink3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _uploading(Colourway c) => SurfaceBox(
    surface: AppSurfaces.card(c),
    padding: ClassroomsSizes.uploadBusyPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClassroomsSizes.uploadBusyGap,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                fileName ?? '',
                style: ClassroomsTextStyles.uploadFile.copyWith(color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              ClassroomsStrings.uploadPercent((progress * 100).round()),
              style: ClassroomsTextStyles.uploadPercent.copyWith(
                color: c.student,
              ),
            ),
          ],
        ),
        Trough(fraction: progress),
        Text(
          ClassroomsStrings.uploading,
          style: ClassroomsTextStyles.uploadHint.copyWith(color: c.ink3),
        ),
      ],
    ),
  );

  Widget _done(Colourway c) => Container(
    padding: ClassroomsSizes.uploadStatePad,
    decoration: BoxDecoration(
      color: c.successBg,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: c.successLine),
    ),
    child: Row(
      spacing: ClassroomsSizes.uploadGap,
      children: <Widget>[
        _Glyph(icon: AppIcons.check, color: c.successFg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ClassroomsSizes.statTileTextGap,
            children: <Widget>[
              Text(
                ClassroomsStrings.onFile(fileName ?? ''),
                style: ClassroomsTextStyles.uploadTitle.copyWith(
                  color: c.successFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ClassroomsStrings.showsOnList,
                style: ClassroomsTextStyles.uploadHint.copyWith(
                  color: c.successFg,
                ),
              ),
            ],
          ),
        ),
        if (onRemove != null)
          Semantics(
            button: true,
            label: ClassroomsStrings.remove,
            child: Pressable.surface(
              onTap: onRemove,
              child: Text(
                ClassroomsStrings.remove,
                style: ClassroomsTextStyles.uploadAction.copyWith(
                  color: c.dangerFg,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _failed(Colourway c) => Container(
    padding: ClassroomsSizes.uploadStatePad,
    decoration: BoxDecoration(
      color: c.dangerBg,
      borderRadius: AppRadii.innerR,
      border: Border.all(color: c.dangerLine),
    ),
    child: Row(
      spacing: ClassroomsSizes.uploadGap,
      children: <Widget>[
        _Glyph(icon: AppIcons.close, color: c.dangerFg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ClassroomsSizes.statTileTextGap,
            children: <Widget>[
              Text(
                ClassroomsStrings.uploadFailedAt((progress * 100).round()),
                style: ClassroomsTextStyles.uploadTitle.copyWith(
                  color: c.dangerFg,
                ),
              ),
              Text(
                ClassroomsStrings.nothingLost(fileName ?? ''),
                style: ClassroomsTextStyles.uploadHint.copyWith(
                  color: c.dangerFg,
                ),
              ),
            ],
          ),
        ),
        if (onRetry != null)
          Semantics(
            button: true,
            label: ClassroomsStrings.retry,
            child: Pressable.surface(
              onTap: onRetry,
              child: Container(
                padding: ClassroomsSizes.retryKeyPad,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(
                    ClassroomsSizes.retryKeyRadius,
                  ),
                ),
                child: Text(
                  ClassroomsStrings.retry,
                  style: ClassroomsTextStyles.retryKey.copyWith(
                    color: c.dangerFg,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The square tile the upload states lead with.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.glyphTile(
      context.colours,
      fill: context.colours.card,
      radius: AppRadii.inner,
    ),
    width: ClassroomsSizes.uploadTile,
    height: ClassroomsSizes.uploadTile,
    alignment: Alignment.center,
    child: Icon(icon, size: ClassroomsSizes.uploadGlyph, color: color),
  );
}
