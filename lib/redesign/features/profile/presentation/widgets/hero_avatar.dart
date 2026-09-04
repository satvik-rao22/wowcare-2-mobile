import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// The bubble at the top of 13a and 13c, in each of the four states 13a's
/// pills name: a photo on file, no photo yet, uploading, and an upload that
/// failed.
///
/// It is navy for everyone. The frame paints a guardian's pink, but pink is
/// the one action on a screen and 13c already spends it on Edit; the signed-in
/// person is the impact avatar everywhere else in the app.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    required this.initials,
    required this.hasPhoto,
    required this.photo,
    this.isGuardian = false,
    super.key,
  });

  final String initials;

  /// Whether the account has a photo. False draws the empty "add" bubble.
  final bool hasPhoto;

  final PhotoStatus photo;

  /// A guardian's hero avatar is one step smaller.
  final bool isGuardian;

  double get _size =>
      isGuardian ? ProfileSizes.guardianHeroAvatar : ProfileSizes.heroAvatar;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return switch (photo) {
      PhotoStatus.uploading => SizedBox.square(
        dimension: _size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[_bubble(), const LoadingRing()],
        ),
      ),
      PhotoStatus.failed => _glyphBubble(
        c,
        fill: c.dangerBg,
        icon: AppIcons.alertCircle,
        ink: c.danger,
      ),
      PhotoStatus.idle when !hasPhoto => _glyphBubble(
        c,
        fill: c.well,
        icon: AppIcons.plus,
        ink: c.ink3,
      ),
      PhotoStatus.idle => _bubble(),
    };
  }

  Widget _bubble() => AppAvatar(
    initials: initials,
    size: _size,
    tone: AvatarTone.impact,
    textStyle: isGuardian
        ? ProfileTextStyles.guardianHeroInitials
        : ProfileTextStyles.heroInitials,
  );

  Widget _glyphBubble(
    Colourway c, {
    required Color fill,
    required IconData icon,
    required Color ink,
  }) => SurfaceBox(
    surface: AppSurfaces.avatar(c, fill: fill, size: _size),
    width: _size,
    height: _size,
    alignment: Alignment.center,
    child: Icon(icon, size: ProfileSizes.heroGlyph, color: ink),
  );
}
