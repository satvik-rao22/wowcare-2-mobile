import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HlsWebPlayer extends StatefulWidget {
  const HlsWebPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<HlsWebPlayer> createState() => _HlsWebPlayerState();
}

class _HlsWebPlayerState extends State<HlsWebPlayer> with WidgetsBindingObserver {
  BetterPlayerController? _controller;
  final GlobalKey _playerKey = GlobalKey();
  bool _isEnteringPip = false;
  bool _isPipActive = false;
  bool _wasPlayingBeforeBackground = false;

  // The underlying VideoPlayerController we've attached _onVideoValueChanged
  // to, so it can be detached on rebuild/dispose.
  ValueNotifier<VideoPlayerValue>? _observedVideoController;
  double? _lastAppliedAspectRatio;

  // BetterPlayerController.isFullScreen has no public stream/notifier we can
  // subscribe to (the controller event stream that flips it is a private
  // package type), so it's watched every frame instead — cheap (one bool
  // compare) and catches both the icon-tap and system-back exit paths.
  bool? _wasFullScreen;
  bool _watchingFullScreen = false;
  static const List<String> _limitedTrackNames = <String>[
    'Auto',
    '360p',
    '720p',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  // Mirrors YouTube's iOS behaviour: leaving the app while a video is
  // playing shrinks it into the floating PiP window instead of pausing it.
  // `paused` is Flutter's signal for applicationDidEnterBackground — the
  // point Apple's docs say to call startPictureInPicture() from, which is
  // also why the app enables the `audio` UIBackgroundMode and a `.playback`
  // AVAudioSession category (see AppDelegate.swift): both are required for
  // AVPictureInPictureController to keep running once the app is backgrounded.
  //
  // BetterPlayerConfiguration.handleLifecycle is intentionally off (see
  // _initPlayer): its own AppLifecycleState handling pauses playback on
  // every backgrounding with no regard for PiP, which would instantly
  // freeze the floating window instead of letting it keep playing. We take
  // over that pause/resume bookkeeping here so an active/about-to-start PiP
  // session is exempted.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.paused) {
      if (_isPipActive) return;
      final isPlaying = controller.isPlaying() ?? false;
      _wasPlayingBeforeBackground = isPlaying;
      if (isPlaying) {
        _handleBackgrounding();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isPipActive && _wasPlayingBeforeBackground) {
        controller.play();
      }
      _wasPlayingBeforeBackground = false;
    }
  }

  @override
  void didUpdateWidget(covariant HlsWebPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      // Detach before disposing — removeListener on an already-disposed
      // notifier asserts, and the old controller is about to become one.
      _observedVideoController?.removeListener(_applyAspectRatio);
      _observedVideoController = null;
      _lastAppliedAspectRatio = null;
      _controller?.dispose();
      _initPlayer();
    }
  }

  // Independent of BuildContext/MediaQuery (safe to call before the first
  // build) so it can feed BetterPlayerConfiguration.fullScreenAspectRatio at
  // controller-creation time. Locked to portrait since fullscreen no longer
  // rotates — this is the shape the fullscreen box will actually be.
  double _currentScreenAspectRatio() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    if (size.width <= 0 || size.height <= 0) return 9 / 16;
    return size.width / size.height;
  }

  void _initPlayer() {
    final url = widget.videoUrl.trim();
    final lower = url.toLowerCase();
    final isHls = lower.contains('.m3u8');

    final config = BetterPlayerConfiguration(
      autoPlay: true,
      fit: BoxFit.contain,
      // better_player_plus falls back to a hardcoded 16:9 box (landscape)
      // until the real aspect ratio is known (see _applyAspectRatio) — most
      // activity clips are recorded portrait, so default the loading box to
      // 9:16 instead. This also covers the (rare) case where the video never
      // reports a usable aspect ratio at all and _applyAspectRatio never
      // overrides it.
      aspectRatio: 9 / 16,
      // Handled manually in didChangeAppLifecycleState so an active PiP
      // session is exempted from the pause-on-background behaviour.
      handleLifecycle: false,
      // The reported aspect ratio can't be trusted to tell portrait from
      // landscape (a backend transcode step has been observed delivering a
      // portrait-shot video as a rotation-free 16:9 stream), so fullscreen
      // no longer rotates or sizes the box off it at all. Fullscreen always
      // stays in the app's current orientation and fills the true screen
      // shape; _watchFullScreenState/_fitFor crop the video content itself
      // with BoxFit.cover to fill that box edge-to-edge.
      autoDetectFullscreenDeviceOrientation: false,
      autoDetectFullscreenAspectRatio: false,
      deviceOrientationsOnFullScreen: const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      fullScreenAspectRatio: _currentScreenAspectRatio(),
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.material,
        iconsColor: Colors.white,
        textColor: Colors.white,
        enableFullscreen: true,
        // Better Player's built-in PiP callback is not guarded and can issue
        // overlapping native PiP requests. The dedicated control below routes
        // every request through [_enterPipMode] instead.
        enablePip: false,
        enableQualities: true,
        enableSubtitles: false,
        enablePlaybackSpeed: true,
        controlsHideTime: Duration(milliseconds: 2200),
        controlBarHeight: 52,
        controlBarColor: Color(0xD910141A),
        progressBarPlayedColor: Color(0xFF35B6FF),
        progressBarHandleColor: Color(0xFF35B6FF),
        progressBarBufferedColor: Color(0x8AE0E8F1),
        progressBarBackgroundColor: Color(0x5A6A7789),
        overflowMenuIcon: Icons.more_vert_rounded,
        qualitiesIcon: Icons.high_quality_rounded,
        playbackSpeedIcon: Icons.speed_rounded,
        fullscreenEnableIcon: Icons.fullscreen_rounded,
        fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        playIcon: Icons.play_arrow_rounded,
        pauseIcon: Icons.pause_rounded,
        overflowModalColor: Color(0xFF111827),
        overflowModalTextColor: Color(0xFFEAF2FF),
        overflowMenuIconsColor: Colors.white,
      ),
      translations: [
        BetterPlayerTranslations(
          overflowMenuQuality: 'Quality',
          qualityAuto: 'Auto',
          overflowMenuPlaybackSpeed: 'Speed',
          overflowMenuSubtitles: 'Subtitles',
        ),
      ],
    );

    final source = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: isHls
          ? BetterPlayerVideoFormat.hls
          : BetterPlayerVideoFormat.other,
      asmsTrackNames: isHls ? _limitedTrackNames : null,
      useAsmsSubtitles: false,
      cacheConfiguration: const BetterPlayerCacheConfiguration(useCache: false),
    );

    final c = BetterPlayerController(config);
    c.setupDataSource(source);
    c.addEventsListener(_onPlayerEvent);
    _controller = c;
    _wasFullScreen = null;
    if (!_watchingFullScreen) {
      _watchingFullScreen = true;
      _watchFullScreenState();
    }
  }

  // Reel-style fullscreen for every video, not just ones detected as
  // portrait — the reported aspect ratio can't be trusted to tell portrait
  // from landscape (see the comment on fullScreenAspectRatio above), so
  // fullscreen always fills the screen edge-to-edge and crops any excess
  // rather than branching on a ratio that might be wrong. The embedded
  // (non-fullscreen) view keeps BoxFit.contain so the complete frame stays
  // visible there, letterboxed if needed.
  BoxFit _fitFor(bool isFullScreen) =>
      isFullScreen ? BoxFit.cover : BoxFit.contain;

  void _watchFullScreenState() {
    if (!mounted) {
      _watchingFullScreen = false;
      return;
    }
    final controller = _controller;
    if (controller != null) {
      final isFullScreen = controller.isFullScreen;
      if (_wasFullScreen != isFullScreen) {
        _wasFullScreen = isFullScreen;
        controller.setOverriddenFit(_fitFor(isFullScreen));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _watchFullScreenState());
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.pipStart) {
      _isPipActive = true;
    } else if (event.betterPlayerEventType == BetterPlayerEventType.pipStop) {
      _isPipActive = false;
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      _applyAspectRatio();
      // For HLS in particular, the video's real dimensions can still be
      // provisional/default at the moment `initialized` fires — ExoPlayer
      // hasn't necessarily decoded the first rendition sample yet. Attach a
      // listener so a corrected aspect ratio reported a moment later still
      // gets picked up instead of leaving the player stuck on the fallback
      // 16:9 box for a video that is actually portrait.
      final videoController = _controller?.videoPlayerController;
      if (videoController != null && videoController != _observedVideoController) {
        _observedVideoController?.removeListener(_applyAspectRatio);
        _observedVideoController = videoController;
        videoController.addListener(_applyAspectRatio);
      }
    }
  }

  // BetterPlayer locks the player box to a 16:9 AspectRatio unless told
  // otherwise, which letterboxes/crops portrait videos. Match the box to
  // the video's real ratio so vertical videos render at their native size.
  void _applyAspectRatio() {
    final controller = _controller;
    final videoAspectRatio = controller?.videoPlayerController?.value.aspectRatio;
    if (controller == null || videoAspectRatio == null) return;
    if (videoAspectRatio <= 0 || !videoAspectRatio.isFinite) return;
    if (_lastAppliedAspectRatio != null &&
        (videoAspectRatio - _lastAppliedAspectRatio!).abs() < 0.01) {
      return;
    }
    _lastAppliedAspectRatio = videoAspectRatio;
    controller.setOverriddenAspectRatio(videoAspectRatio);
    // Re-derive fit from _fitFor rather than leaving whatever was last set —
    // a later aspect-ratio correction (e.g. an ASMS rendition switch) can
    // change whether the video counts as portrait, which should flip the
    // fullscreen fit too.
    controller.setOverriddenFit(_fitFor(controller.isFullScreen));
  }

  /// Returns whether PiP was actually requested, so callers driven by
  /// backgrounding (see [_handleBackgrounding]) know whether to fall back
  /// to a plain pause instead of leaving the video playing off-screen.
  Future<bool> _enterPipMode() async {
    if (_isEnteringPip) return false;
    final controller = _controller;
    if (controller == null || _playerKey.currentContext == null) return false;

    setState(() => _isEnteringPip = true);
    try {
      final supported = await controller.isPictureInPictureSupported();
      if (!mounted) return false;
      if (!supported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PiP is not supported on this device right now.'),
          ),
        );
        return false;
      }
      await controller.enablePictureInPicture(_playerKey);
      return true;
    } catch (error, stackTrace) {
      // The plugin delegates this to the platform activity. A lifecycle race
      // (for example, entering PiP while the player is disposing) used to
      // bubble up as an unhandled exception and terminate the screen/app.
      debugPrint('Unable to enter picture-in-picture: $error\n$stackTrace');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start picture-in-picture.')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isEnteringPip = false);
    }
  }

  // Falls back to a plain pause when auto-PiP can't be started (unsupported
  // device, race with disposal, etc.) so the video doesn't keep playing
  // silently off-screen with nothing showing it.
  Future<void> _handleBackgrounding() async {
    final started = await _enterPipMode();
    if (!started) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeEventsListener(_onPlayerEvent);
    _observedVideoController?.removeListener(_applyAspectRatio);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              key: _playerKey,
              color: Colors.black,
              child: Theme(
                data: Theme.of(context).copyWith(
                  brightness: Brightness.dark,
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.white,
                    secondary: Colors.white,
                    onSecondary: Colors.white,
                    surface: Colors.black,
                    onSurface: Colors.white,
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  primaryIconTheme: const IconThemeData(color: Colors.white),
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                ),
                child: BetterPlayer(controller: _controller!),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                // The host screen (ShowFullScreenMedia / ShowFullScreenMediaView)
                // now overlays its back/download row on top of the video instead
                // of reserving a fixed AppBar — pushed down here so PiP doesn't
                // sit underneath it.
                padding: const EdgeInsets.only(top: 58, right: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xB010141A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x6635B6FF)),
                  ),
                  child: IconButton(
                    tooltip: 'PiP',
                    onPressed: _isEnteringPip ? null : _enterPipMode,
                    icon: const Icon(
                      Icons.picture_in_picture_alt_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
