import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../custom_shimmer_loader.dart';
import 'app_image_source.dart';
import 'app_image_viewer.dart';

export 'app_image_source.dart';
export 'app_image_viewer.dart';

/// The single image widget for the app: raster (png/jpg/webp/gif/heic), SVG
/// and Lottie, from network, asset, file or memory.
///
/// ```dart
/// AppImage(source: user.photoUrl, width: 48, height: 48, shape: BoxShape.circle)
/// AppImage(source: MediaRes.sleepIcon, width: 20, color: AppColors.primaryColor)
/// AppImage(source: photo.url, height: 200, fit: BoxFit.cover, enableFullScreen: true)
/// ```
///
/// [source] is resolved by [AppImageSource.from]; pass an [AppImageSource] when
/// auto-detection can't tell (e.g. an extension-less SVG URL).
///
/// Network rasters are disk-cached. Network SVG/Lottie are only memory-cached.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.color,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.enableFullScreen = false,
    this.heroTag,
    this.onTap,
    this.semanticLabel,
    this.lottieRepeat = true,
  }) : assert(
         !(enableFullScreen && onTap != null),
         'Use either enableFullScreen or onTap, not both.',
       );

  /// URL, `assets/…` path, absolute file path, `Uint8List`, `File`, or an
  /// [AppImageSource]. Null/blank shows [errorWidget].
  final Object? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  /// Tints SVGs and rasters (srcIn). Ignored for Lottie.
  final Color? color;
  final BorderRadius? borderRadius;

  /// [BoxShape.circle] clips to a circle (avatars); [borderRadius] is ignored.
  final BoxShape shape;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Tap opens [AppImageViewer] with pinch-zoom.
  final bool enableFullScreen;

  /// Opt-in Hero animation into the full-screen viewer. Must be unique on the
  /// screen — never derive it from the URL alone, a list can repeat a URL.
  final Object? heroTag;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool lottieRepeat;

  /// Drops a network image from the memory and disk cache, e.g. after the
  /// object behind a stable URL/cache key was replaced.
  static Future<void> evict(String url, {String? cacheKey}) {
    return CachedNetworkImage.evictFromCache(
      url,
      cacheKey: cacheKey ?? NetworkAppImageSource.stableCacheKey(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = AppImageSource.from(source);

    Widget child = resolved == null
        ? _error(context)
        : switch (resolved.format) {
            AppImageFormat.raster => _raster(context, resolved),
            AppImageFormat.svg => _svg(context, resolved),
            AppImageFormat.lottie => _lottie(context, resolved),
          };

    child = SizedBox(width: width, height: height, child: child);
    if (backgroundColor != null) {
      child = ColoredBox(color: backgroundColor!, child: child);
    }
    if (shape == BoxShape.circle) {
      child = ClipOval(child: child);
    } else if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    final tap =
        onTap ??
        (enableFullScreen && resolved != null
            ? () => AppImageViewer.open(context, resolved, heroTag: heroTag)
            : null);
    if (tap == null) return child;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------- raster

  Widget _raster(BuildContext context, AppImageSource src) {
    final cacheWidth = _decodeWidth(context);
    final blend = color == null ? null : BlendMode.srcIn;
    Widget onError(BuildContext c, Object _, StackTrace? __) => _error(c);

    return switch (src) {
      NetworkAppImageSource() => CachedNetworkImage(
        imageUrl: src.url,
        cacheKey: src.effectiveCacheKey,
        httpHeaders: src.headers,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment.resolve(Directionality.of(context)),
        color: color,
        colorBlendMode: blend,
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (c, _) => _placeholder(c),
        errorWidget: (c, _, __) => _error(c),
      ),
      AssetAppImageSource() => Image.asset(
        src.path,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: blend,
        cacheWidth: cacheWidth,
        semanticLabel: semanticLabel,
        errorBuilder: onError,
      ),
      FileAppImageSource() => Image.file(
        File(src.path),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: blend,
        cacheWidth: cacheWidth,
        semanticLabel: semanticLabel,
        errorBuilder: onError,
      ),
      MemoryAppImageSource() => Image.memory(
        src.bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: blend,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        errorBuilder: onError,
      ),
    };
  }

  /// Decode rasters at display size instead of full resolution: a 4000px
  /// camera photo in a 48px avatar otherwise costs ~64MB of memory.
  ///
  /// Only width is passed so aspect ratio is kept. Using the larger box side
  /// keeps [BoxFit.cover] sharp for portrait images; very wide images in a
  /// tall box may soften slightly. No hint when the size is unbounded.
  int? _decodeWidth(BuildContext context) {
    final w = width, h = height;
    final candidates = [w, h].whereType<double>().where((v) => v.isFinite);
    if (candidates.isEmpty) return null;
    final side = candidates.reduce(math.max);
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    return (side * dpr).round();
  }

  // ------------------------------------------------------------------- svg

  Widget _svg(BuildContext context, AppImageSource src) {
    final filter = color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn);
    Widget onError(BuildContext c, Object _, StackTrace __) => _error(c);
    // Local SVGs parse in a frame or two — a shimmer would just flicker.
    Widget blank(BuildContext _) => SizedBox(width: width, height: height);

    return switch (src) {
      NetworkAppImageSource() => SvgPicture.network(
        src.url,
        headers: src.headers,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: _placeholder,
        errorBuilder: onError,
      ),
      AssetAppImageSource() => SvgPicture.asset(
        src.path,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: blank,
        errorBuilder: onError,
      ),
      FileAppImageSource() => SvgPicture.file(
        File(src.path),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: blank,
        errorBuilder: onError,
      ),
      MemoryAppImageSource() => SvgPicture.memory(
        src.bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        colorFilter: filter,
        semanticsLabel: semanticLabel,
        placeholderBuilder: blank,
        errorBuilder: onError,
      ),
    };
  }

  // ---------------------------------------------------------------- lottie

  Widget _lottie(BuildContext context, AppImageSource src) {
    Widget frame(BuildContext c, Widget child, LottieComposition? comp) =>
        comp == null ? _placeholder(c) : child;
    Widget onError(BuildContext c, Object _, StackTrace? __) => _error(c);

    return switch (src) {
      NetworkAppImageSource() => Lottie.network(
        src.url,
        headers: src.headers,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: lottieRepeat,
        frameBuilder: frame,
        errorBuilder: onError,
      ),
      AssetAppImageSource() => Lottie.asset(
        src.path,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: lottieRepeat,
        errorBuilder: onError,
      ),
      FileAppImageSource() => Lottie.file(
        File(src.path),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: lottieRepeat,
        errorBuilder: onError,
      ),
      MemoryAppImageSource() => Lottie.memory(
        src.bytes,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: lottieRepeat,
        errorBuilder: onError,
      ),
    };
  }

  // ---------------------------------------------------------------- states

  Widget _placeholder(BuildContext context) {
    return placeholder ??
        ShimmerLoader(
          width: width,
          height: height,
          borderRadius: shape == BoxShape.circle
              ? BorderRadius.circular(9999)
              : (borderRadius ?? BorderRadius.zero),
        );
  }

  Widget _error(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    final sides = [width, height].whereType<double>().where((v) => v.isFinite);
    final iconSize = sides.isEmpty
        ? 24.0
        : (sides.reduce(math.min) * 0.45).clamp(12.0, 48.0);
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: iconSize,
        color: Colors.grey.shade500,
      ),
    );
  }
}
