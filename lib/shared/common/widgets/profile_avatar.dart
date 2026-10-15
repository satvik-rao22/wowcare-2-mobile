import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_string_extension.dart';
import 'package:wowcare/shared/common/widgets/app_image/app_image.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// The one avatar for a person or classroom: their photo, or their initials
/// on a colour that stays the same for that name.
///
/// ```dart
/// ProfileAvatar(name: staff.fullName, staffCode: staff.code)
/// ProfileAvatar(name: student.name, assetCode: student.photoAssetCode, size: 56)
/// ProfileAvatar(
///   name: student.name,
///   studentCode: student.code,
///   statusDot: AttendanceStatusDot(studentCode: student.code),
/// )
/// ```
///
/// Give it whatever the screen already has — a ready [imageUrl], an
/// [assetCode], or the owner's [studentCode] / [staffCode] / [userCode] /
/// [classroomCode] — and AssetService finds the photo (cached and shared, so
/// a list asks once per person). The initials show at once and the photo
/// fades in over them; with no photo the initials stay.
///
/// The photo is drawn by [AppImage], so its caching and loading behaviour is
/// the app's single image pipeline.
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.assetCode,
    this.studentCode,
    this.staffCode,
    this.userCode,
    this.classroomCode,
    this.lookUpProfilePhoto = true,
    this.size = 40,
    this.fontSize,
    this.statusDot,
    this.onTap,
  });

  /// Gives the initials and the colour. Blank shows a person icon.
  final String name;

  /// A photo URL that's ready to show. Skips every lookup.
  final String? imageUrl;

  /// The photo's media asset code.
  final String? assetCode;
  final String? studentCode;
  final String? staffCode;

  /// An account code (`USR_*`), e.g. a messaging participant; mapped to the
  /// staff code to find the photo.
  final String? userCode;

  /// Shows the classroom's logo.
  final String? classroomCode;

  /// False when the screen's data already says there's no photo, so the
  /// student/staff profile isn't asked. [assetCode] and [classroomCode] are
  /// still looked up.
  final bool lookUpProfilePhoto;

  final double size;

  /// Defaults to a size that fits the circle.
  final double? fontSize;

  /// Shown at the top-right, e.g. an [AttendanceStatusDot]. Sized to the
  /// avatar.
  final Widget? statusDot;
  final VoidCallback? onTap;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  AssetService? _assets;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    if (serviceLocator.isRegistered<AssetService>()) {
      _assets = serviceLocator<AssetService>();
      _assets!.profilePhotoChanges.addListener(_findPhoto);
    }
    _photoUrl = _readyUrl();
    _findPhoto();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_owner(oldWidget) == _owner(widget)) return;
    // This element now shows someone else (e.g. a reused list row): never
    // leave the previous person's photo up while the new one is found.
    _photoUrl = _readyUrl();
    _findPhoto();
  }

  @override
  void dispose() {
    _assets?.profilePhotoChanges.removeListener(_findPhoto);
    super.dispose();
  }

  static String _owner(ProfileAvatar w) => [
    w.imageUrl,
    w.assetCode,
    w.classroomCode,
    w.studentCode,
    w.staffCode,
    w.userCode,
  ].map((code) => code?.trim() ?? '').join('|');

  /// The given URL, or a photo already in the cache — so a known photo paints
  /// on the first frame.
  String? _readyUrl() {
    final given = widget.imageUrl?.trim() ?? '';
    if (given.isNotEmpty) return given;
    return _assets?.cachedProfilePhotoUrl(
      assetCode: widget.assetCode,
      classroomCode: widget.classroomCode,
      studentCode: widget.studentCode,
      staffCode: widget.staffCode,
      userCode: widget.userCode,
    );
  }

  Future<void> _findPhoto() async {
    final assets = _assets;
    if (assets == null || (widget.imageUrl?.trim() ?? '').isNotEmpty) return;
    final owner = _owner(widget);
    final found = await assets.profilePhotoUrl(
      assetCode: widget.assetCode,
      classroomCode: widget.classroomCode,
      studentCode: widget.studentCode,
      staffCode: widget.staffCode,
      userCode: widget.userCode,
      lookUpProfile: widget.lookUpProfilePhoto,
    );
    // Ignore an answer for someone this element no longer shows.
    if (!mounted || owner != _owner(widget)) return;
    if (found.url != null && found.url != _photoUrl) {
      setState(() => _photoUrl = found.url);
    } else if (found.url == null && found.deleted && _photoUrl != null) {
      setState(() => _photoUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _Initials(
      name: widget.name,
      size: widget.size,
      fontSize: widget.fontSize,
    );
    final url = _photoUrl;
    Widget avatar = url == null
        ? initials
        : AppImage(
            source: url,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            shape: BoxShape.circle,
            placeholder: initials,
            errorWidget: initials,
            semanticLabel: widget.name,
          );

    final dot = widget.statusDot;
    if (dot != null) {
      final dotSize = widget.size * 0.27;
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 2,
            top: 2,
            child: SizedBox.square(dimension: dotSize, child: dot),
          ),
        ],
      );
    }

    final onTap = widget.onTap;
    return SizedBox.square(
      dimension: widget.size,
      child: onTap == null
          ? avatar
          : GestureDetector(onTap: onTap, child: avatar),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size, this.fontSize});

  final String name;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final initials = name.initials;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: initials.isEmpty ? AppColors.shimmerBase : _colorFor(name),
      ),
      child: initials.isEmpty
          ? Icon(
              Icons.person,
              size: size * 0.6,
              color: AppColors.userProfileMutedIconColor,
            )
          : Text(
              initials,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize ?? size * 0.36,
                color: AppPalette.textOnDark,
              ),
            ),
    );
  }

  /// The same colour for the same name, everywhere in the app.
  static Color _colorFor(String name) {
    const palette = AppColors.profileAvatarColors;
    if (palette.isEmpty) return AppColors.primaryColor;
    return palette[name.trim().hashCode.abs() % palette.length];
  }
}
