/// The app's SVG glyphs, painted in a theme colour.
///
/// An icon is a **shape**, not a picture: the asset supplies the outline and
/// the theme supplies the colour. That distinction is not cosmetic here —
/// 45 of the SVGs in `assets/icons` ship a baked-in gradient from the
/// previous look, so a bare `SvgPicture.asset` paints last season's brand
/// however the palette is set. [AppIcon] always paints through
/// `ColorFilter.mode(…, BlendMode.srcIn)`, which replaces every fill in the
/// asset with one token colour, so a glyph cannot fall out of the skin.
///
/// ```dart
/// AppIcon(MediaRes.filterIcon)                       // navy ink, 24 px
/// AppIcon(MediaRes.filterIcon, tone: IconTone.action) // pink, it is live
/// AppIcon(MediaRes.backButton, size: 18, color: someRowTint)
/// ```
///
/// `srcIn` matters as much as the filter itself: `dstIn`, which the bottom
/// bar used to use, treats the glyph as a *mask* and leaves the asset's own
/// gradient showing through.
///
/// **The one exception** is genuine artwork — an empty-state illustration, a
/// logo, the activity-type cartoons — where the colours are the content.
/// Those use [AppArtwork], which is the same call with the filter left off
/// and a name that says why.
///
/// ## Why a glyph is drawn as a raster, not a picture
///
/// A colour-filtered picture is composited through a `saveLayer`: an
/// offscreen render target per glyph, per frame, which under Impeller is not
/// cached. A screen with a bottom bar, an app bar and a list of rows carries
/// twenty or more glyphs, so that was twenty offscreen passes a frame, all
/// to recolour icons that never change. [RenderingStrategy.raster] draws the
/// glyph once into a small image and thereafter blits it with the filter on
/// the paint, no layer. The image is sized to the glyph's device pixels, so
/// it is as sharp as the picture was. Artwork keeps the picture strategy: it
/// has no filter, so it never paid for a layer.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;
import 'package:wowcare/core/theme/app_theme_config.dart';

/// The voices a glyph can speak in. Each maps to one [AppPalette] role, so a
/// new skin re-tones every icon in the app by editing that file alone.
enum IconTone {
  /// Navy ink. The default: a glyph reads as part of the text it sits with.
  standard,

  /// De-emphasised. Row affordances, metadata, an inactive tab.
  muted,

  /// Warm white, for a glyph on pink, navy or any other saturated face.
  onBrand,

  /// Pink. The glyph *is* the recommended action, or the state is live.
  action,

  /// Teal — a secondary action, and anything about a child.
  secondary,

  /// Green: signed in, on track, paid.
  success,

  /// Sun: due soon, needs attention.
  warning,

  /// Danger: absent, overdue, destructive.
  danger,
}

/// The [AppPalette] colour each [IconTone] resolves to.
extension IconToneColor on IconTone {
  Color get color => switch (this) {
    IconTone.standard => AppPalette.iconDefault,
    IconTone.muted => AppPalette.iconMuted,
    IconTone.onBrand => AppPalette.iconOnBrand,
    IconTone.action => AppPalette.iconAction,
    IconTone.secondary => AppPalette.actionSecondary,
    IconTone.success => AppPalette.statusSuccess,
    IconTone.warning => AppPalette.statusWarning,
    IconTone.danger => AppPalette.statusError,
  };
}

/// A themed SVG glyph. See the library doc for why the colour filter is not
/// optional.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size,
    this.tone = IconTone.standard,
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  });

  /// The asset path, normally a `MediaRes` constant.
  final String asset;

  /// A square edge length, the common case. [width] and [height] override it
  /// per axis. Leave all three off and the glyph takes its intrinsic size,
  /// exactly as a bare `SvgPicture` would.
  final double? size;

  /// Which palette role paints the glyph. Ignored when [color] is given.
  final IconTone tone;

  /// An explicit colour, for the rare glyph whose tone is data (a classroom's
  /// colour, a status resolved at runtime). Still a token — never a literal.
  final Color? color;

  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: width ?? size,
    height: height ?? size,
    fit: fit,
    semanticsLabel: semanticsLabel,
    colorFilter: ColorFilter.mode(color ?? tone.color, BlendMode.srcIn),
    renderingStrategy: RenderingStrategy.raster,
  );
}

/// An SVG whose own colours are the content: an empty-state illustration, a
/// logo, an activity-type cartoon.
///
/// Deliberately a separate name from [AppIcon]. Both render an asset; only
/// this one is allowed to keep the artwork's palette, and having to type
/// `AppArtwork` makes that a decision rather than an omission.
class AppArtwork extends StatelessWidget {
  const AppArtwork(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
    this.rasterize = false,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticsLabel;

  /// True for artwork that moves every frame (the update banners' breathing
  /// mark): it is drawn once into an image and then only blitted, instead of
  /// its paths being replayed on each frame. See the library doc.
  final bool rasterize;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: width,
    height: height,
    fit: fit,
    semanticsLabel: semanticsLabel,
    renderingStrategy: rasterize
        ? RenderingStrategy.raster
        : RenderingStrategy.picture,
  );
}

/// An SVG that is **content** — a user's upload, a server-sent badge — rather
/// than one of the app's own glyphs, loaded from somewhere other than the
/// bundle.
///
/// The `assets/icons` gradient problem [AppIcon] exists for does not apply:
/// these files are not ours to re-tone, so the colours stay the content's,
/// exactly as with [AppArtwork]. A [tint] is honoured only because a caller
/// asked for one explicitly. Kept here, beside [AppIcon], so this file stays
/// the one place in `lib/` that paints an SVG.
class AppSvgContent extends StatelessWidget {
  const AppSvgContent.network(
    String this.url, {
    super.key,
    this.headers,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.tint,
    this.semanticsLabel,
    this.placeholderBuilder,
    this.errorBuilder,
  }) : path = null,
       bytes = null;

  const AppSvgContent.file(
    String this.path, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.tint,
    this.semanticsLabel,
    this.placeholderBuilder,
    this.errorBuilder,
  }) : url = null,
       headers = null,
       bytes = null;

  const AppSvgContent.memory(
    Uint8List this.bytes, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.tint,
    this.semanticsLabel,
    this.placeholderBuilder,
    this.errorBuilder,
  }) : url = null,
       headers = null,
       path = null;

  final String? url;
  final Map<String, String>? headers;
  final String? path;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// Recolours every fill (srcIn). Leave null to keep the content's palette.
  final Color? tint;
  final String? semanticsLabel;
  final WidgetBuilder? placeholderBuilder;
  final SvgErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final filter = tint == null
        ? null
        : ColorFilter.mode(tint!, BlendMode.srcIn);
    if (url != null) {
      return SvgPicture.network(
        url!,
        headers: headers,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticsLabel,
        placeholderBuilder: placeholderBuilder,
        errorBuilder: errorBuilder,
      );
    }
    if (path != null) {
      return SvgPicture.file(
        File(path!),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticsLabel,
        placeholderBuilder: placeholderBuilder,
        errorBuilder: errorBuilder,
      );
    }
    return SvgPicture.memory(
      bytes!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter: filter,
      semanticsLabel: semanticsLabel,
      placeholderBuilder: placeholderBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
