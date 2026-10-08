part of 'app_image.dart';

/// Pinch / pan / double-tap zoom surface behind [AppImageInteraction.zoom] and
/// the full-screen viewer. The in-house replacement for `photo_view`, built on
/// [InteractiveViewer].
///
/// Matches photo_view's defaults:
/// - opens fitted (contain); pinch to zoom, pan while zoomed, fling with inertia;
/// - panning is bounded by the *image*, not the screen, so the letterbox bars
///   never scroll into view, and an image narrower than the screen stays
///   centred on that axis;
/// - double-tap cycles fit → cover → original pixel size → fit, animated and
///   anchored on the tapped point; after a free pinch it returns to fit;
/// - loading and error states replace the zoom surface.
///
/// Deliberate differences: pinching below fit is not allowed (photo_view lets
/// the image shrink to nothing), and zoom is capped at [_maxScale] (raised
/// automatically if original size needs more).
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({
    required this.source,
    this.backgroundColor = Colors.black,
    this.placeholder,
    this.errorBuilder,
    this.heroTag,
  });

  /// Anything [AppImage] accepts.
  final Object? source;

  final Color backgroundColor;

  /// Shown until a raster image has decoded. Defaults to a spinner.
  final Widget? placeholder;
  final AppImageErrorBuilder? errorBuilder;

  /// Pairs with the same tag on the thumbnail for a Hero transition.
  final Object? heroTag;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  /// Upper zoom bound, relative to the fitted size.
  static const double _maxScale = 8;

  final TransformationController _transform = TransformationController();
  // Created eagerly: a lazy `late final` would first be built in dispose() when
  // the user never zoomed (e.g. the error state), which throws.
  late final AnimationController _zoomAnimation;
  Animation<Matrix4>? _zoomTween;

  Offset _doubleTapAt = Offset.zero;
  Size _viewport = Size.zero;
  bool _clamping = false;

  AppImageSource? _source;
  Object? _resolvedFor;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  /// Decoded pixel size. Only known for rasters; SVG/Lottie fall back to
  /// viewport bounds and a fixed double-tap step.
  Size? _imageSize;
  Object? _error;
  StackTrace? _errorStack;

  bool get _awaitingDecode =>
      _source?.format == AppImageFormat.raster &&
      _imageSize == null &&
      _error == null;

  @override
  void initState() {
    super.initState();
    _zoomAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onZoomTick);
    _transform.addListener(_enforceBounds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolving needs the local ImageConfiguration (DPR picks the same asset
    // variant Image.asset does, so both share one cache entry).
    if (!identical(_resolvedFor, widget.source)) _resolve();
  }

  @override
  void didUpdateWidget(covariant _ZoomableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _transform.value = Matrix4.identity();
      _resolve();
    }
  }

  @override
  void dispose() {
    _stopListening();
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------- loading

  void _resolve() {
    _stopListening();
    _resolvedFor = widget.source;
    _source = AppImageSource.from(widget.source);
    _imageSize = null;
    _error = null;
    _errorStack = null;

    final provider = _rasterProvider(_source);
    if (provider == null) return;

    // Same provider + key AppImage builds for an unsized image, so this rides
    // the same download/decode instead of starting a second one.
    final stream = provider.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, synchronousCall) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        info.dispose();
        // First frame is all we need; staying subscribed would rebuild on
        // every frame of an animated GIF.
        _stopListening();
        if (!mounted) return;
        synchronousCall
            ? _imageSize = size
            : setState(() => _imageSize = size);
      },
      onError: (error, stackTrace) {
        _stopListening();
        if (!mounted) return;
        setState(() {
          _error = error;
          _errorStack = stackTrace;
        });
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _stopListening() {
    final stream = _stream, listener = _listener;
    _stream = null;
    _listener = null;
    if (stream != null && listener != null) stream.removeListener(listener);
  }

  static ImageProvider? _rasterProvider(AppImageSource? source) {
    if (source == null || source.format != AppImageFormat.raster) return null;
    return switch (source) {
      NetworkAppImageSource() => CachedNetworkImageProvider(
        source.url,
        cacheKey: source.effectiveCacheKey,
        headers: source.headers,
      ),
      AssetAppImageSource() => AssetImage(source.path),
      FileAppImageSource() => FileImage(File(source.path)),
      MemoryAppImageSource() => MemoryImage(source.bytes),
    };
  }

  // ------------------------------------------------------------- geometry

  /// Where the contained image sits inside the (viewport-sized) child.
  Rect get _imageRect {
    final vp = _viewport;
    final size = _imageSize;
    if (size == null || size.isEmpty || vp.isEmpty) return Offset.zero & vp;
    final fitted = applyBoxFit(BoxFit.contain, size, vp).destination;
    return Alignment.center.inscribe(fitted, Offset.zero & vp);
  }

  /// Scale at which one image pixel is one logical pixel.
  double? get _originalScale {
    final size = _imageSize;
    final rect = _imageRect;
    if (size == null || size.isEmpty || rect.isEmpty) return null;
    return size.width / rect.width;
  }

  double get _effectiveMaxScale =>
      math.max(_maxScale, _originalScale ?? 0);

  /// Double-tap stops, ascending: fit, cover, original. Stops that would not
  /// zoom in any further are dropped; a lone fit gets a 2.5x stop so
  /// double-tap always does something.
  List<double> get _doubleTapStops {
    final rect = _imageRect;
    final vp = _viewport;
    final stops = <double>[1];
    if (!rect.isEmpty && !vp.isEmpty) {
      final cover = math.max(vp.width / rect.width, vp.height / rect.height);
      for (final s in [cover, ?_originalScale]) {
        final clamped = math.min(s, _effectiveMaxScale);
        if (clamped > stops.last * 1.05) stops.add(clamped);
      }
    }
    if (stops.length == 1) stops.add(math.min(2.5, _effectiveMaxScale));
    return stops;
  }

  /// Keeps the image covering the viewport on each axis where it is larger
  /// than the viewport, and centred where it is smaller.
  Matrix4 _clamp(Matrix4 m) {
    final scale = m.getMaxScaleOnAxis();
    final rect = _imageRect;
    final vp = _viewport;
    final t = m.getTranslation();

    double axis(double tx, double start, double extent, double view) {
      final scaled = extent * scale;
      if (scaled <= view) return (view - scaled) / 2 - start * scale;
      return tx.clamp(view - (start + extent) * scale, -start * scale);
    }

    final x = axis(t.x, rect.left, rect.width, vp.width);
    final y = axis(t.y, rect.top, rect.height, vp.height);
    return Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(x, y, 0);
  }

  /// Runs after every change — pinch, pan, fling and our own animation — so
  /// InteractiveViewer's inertia can never carry the image out of bounds.
  void _enforceBounds() {
    if (_clamping || _viewport.isEmpty) return;
    final clamped = _clamp(_transform.value);
    if (clamped == _transform.value) return;
    _clamping = true;
    _transform.value = clamped;
    _clamping = false;
  }

  // ------------------------------------------------------------ double-tap

  void _onDoubleTap() {
    final current = _transform.value.getMaxScaleOnAxis();
    final stops = _doubleTapStops;
    final at = stops.indexWhere((s) => (s - current).abs() < 0.02);
    final target = (at == -1 || at == stops.length - 1) ? 1.0 : stops[at + 1];

    final Matrix4 end;
    if (target <= 1.0001) {
      end = Matrix4.identity();
    } else {
      // Keep the scene point under the finger under the finger.
      final scene = _transform.toScene(_doubleTapAt);
      end = _clamp(
        Matrix4.diagonal3Values(target, target, 1)..setTranslationRaw(
          _doubleTapAt.dx - scene.dx * target,
          _doubleTapAt.dy - scene.dy * target,
          0,
        ),
      );
    }

    _zoomTween = Matrix4Tween(begin: _transform.value, end: end).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
    );
    _zoomAnimation.forward(from: 0);
  }

  void _onZoomTick() {
    final tween = _zoomTween;
    if (tween != null) _transform.value = tween.value;
  }

  void _onViewportChanged(Size size) {
    if (size == _viewport) return;
    final hadViewport = !_viewport.isEmpty;
    _viewport = size;
    // Rotation / resize: the old matrix means nothing in the new box.
    if (hadViewport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _transform.value = Matrix4.identity();
      });
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_source == null || _error != null) {
      body =
          widget.errorBuilder?.call(context, _error, _errorStack) ??
          const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Colors.white54,
            ),
          );
    } else if (_awaitingDecode) {
      body =
          widget.placeholder ??
          const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          _onViewportChanged(constraints.biggest);
          return GestureDetector(
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            onDoubleTap: _onDoubleTap,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              maxScale: _effectiveMaxScale,
              // Bounds are enforced by _enforceBounds against the image rect;
              // InteractiveViewer's own child-rect bounds would let the
              // letterbox bars pan into view.
              boundaryMargin: const EdgeInsets.all(double.infinity),
              onInteractionStart: (_) => _zoomAnimation.stop(),
              child: SizedBox.fromSize(
                size: constraints.biggest,
                child: AppImage(
                  source: _source,
                  fit: BoxFit.contain,
                  placeholder: widget.placeholder,
                  errorBuilder: widget.errorBuilder,
                ),
              ),
            ),
          );
        },
      );
    }

    if (widget.heroTag != null) body = Hero(tag: widget.heroTag!, child: body);
    return ColoredBox(color: widget.backgroundColor, child: body);
  }
}
