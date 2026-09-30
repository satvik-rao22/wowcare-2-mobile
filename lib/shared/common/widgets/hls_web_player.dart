import 'package:better_player_plus/better_player_plus.dart';
// PIP-DISABLED (App Review 2.5.4, Sept 2026): foundation was imported for
// `defaultTargetPlatform`, whose only caller (the _policy field) is commented
// out below; material re-exports everything else this file uses. Restore this
// import alongside _policy. Restoring PiP also needs `audio` back in
// UIBackgroundModes (ios/Runner/Info.plist) + a screen recording for review.
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

// PIP-DISABLED (App Review 2.5.4, Sept 2026): restoring PiP requires re-adding
// `audio` to UIBackgroundModes in ios/Runner/Info.plist plus a screen recording
// of the PiP control for the review notes.
//
// [VideoLifecycleAction] and [VideoLifecyclePolicy] are deliberately left
// compiling rather than commented out: they are a pure decision table that
// issues no PiP calls of its own, and video_lifecycle_policy_test.dart still
// covers them, so the behaviour stays pinned for whoever turns PiP back on.
// Nothing in the widget consults them while PiP is off — the commented-out
// didChangeAppLifecycleState below was their only caller, and
// BetterPlayerConfiguration.handleLifecycle is back to true so the plugin does
// the pause/resume itself.

/// What [HlsWebPlayer] should do in response to an app lifecycle change.
enum VideoLifecycleAction { none, enterPip, exitPip, pause, resume }

/// The pause/PiP bookkeeping [HlsWebPlayer] runs in place of
/// `BetterPlayerConfiguration.handleLifecycle`, kept as a pure decision table
/// so both platforms can be asserted against each other in tests.
///
/// The player is otherwise identical on iPhone and Android; only *when* PiP
/// may be requested and *who* ends it differ, and those two facts live here
/// and nowhere else.
@visibleForTesting
class VideoLifecyclePolicy {
  const VideoLifecyclePolicy(this.platform);

  final TargetPlatform platform;

  bool get _isIos => platform == TargetPlatform.iOS;

  /// The last lifecycle state at which PiP can still be started.
  ///
  /// Android's `Activity.enterPictureInPictureMode()` stays legal all the way
  /// to `onUserLeaveHint`, which Flutter reports as [AppLifecycleState.paused].
  /// iOS is stricter: `AVPictureInPictureController` refuses to start once the
  /// process is actually in the background, so the request has to go out on
  /// [AppLifecycleState.inactive] — the state iOS passes through on its way
  /// out (home swipe, app switcher) while the app is still on screen. Asking
  /// at `paused` on iOS is always too late, which is why leaving the app used
  /// to merely pause the video on iPhone while it floated on Android.
  AppLifecycleState get pipTrigger =>
      _isIos ? AppLifecycleState.inactive : AppLifecycleState.paused;

  /// Whether coming back to the app has to tear PiP down by hand.
  ///
  /// On Android PiP *is* the activity, so re-entering the app ends it and the
  /// plugin's own watchdog reports `pipStop`. Never call
  /// `disablePictureInPicture()` there — its Android implementation runs
  /// `activity.moveTaskToBack(false)`, which would shove the app the user just
  /// reopened straight back out. iOS instead keeps the floating window alive
  /// on top of the reopened app, so it has to be closed explicitly to land
  /// where Android lands.
  bool get exitsPipOnResume => _isIos;

  VideoLifecycleAction actionFor({
    required AppLifecycleState state,
    required bool isPlaying,
    required bool isPipActive,
    required bool isEnteringPip,
    required bool wasPlayingBeforeBackground,
  }) {
    if (state == AppLifecycleState.resumed) {
      if (isPipActive) {
        return exitsPipOnResume
            ? VideoLifecycleAction.exitPip
            : VideoLifecycleAction.none;
      }
      return wasPlayingBeforeBackground
          ? VideoLifecycleAction.resume
          : VideoLifecycleAction.none;
    }

    // PiP already owns playback. Handling lifecycle by hand exists precisely
    // so these states cannot pause a window that is still on screen.
    if (isPipActive || isEnteringPip) return VideoLifecycleAction.none;

    if (state == pipTrigger && isPlaying) return VideoLifecycleAction.enterPip;

    // Backgrounded with no PiP to catch it — a device that refused the
    // request, or a video that was already paused. Audio must never keep
    // running under a screen the user can't see.
    if (state == AppLifecycleState.paused && isPlaying) {
      return VideoLifecycleAction.pause;
    }
    return VideoLifecycleAction.none;
  }
}

class HlsWebPlayer extends StatefulWidget {
  const HlsWebPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<HlsWebPlayer> createState() => _HlsWebPlayerState();
}

// PIP-DISABLED (App Review 2.5.4, Sept 2026): `with WidgetsBindingObserver`
// dropped with didChangeAppLifecycleState below — it had no other user.
// Restoring needs `audio` back in UIBackgroundModes + a review screen recording.
class _HlsWebPlayerState extends State<HlsWebPlayer> {
  BetterPlayerController? _controller;
  // PIP-DISABLED (App Review 2.5.4, Sept 2026): this GlobalKey existed only to
  // hand enablePictureInPicture() the render box to shrink. Restoring needs
  // `audio` back in UIBackgroundModes + a review screen recording.
  // final GlobalKey _playerKey = GlobalKey();
  // final VideoLifecyclePolicy _policy = VideoLifecyclePolicy(
  //   defaultTargetPlatform,
  // );
  // bool _isEnteringPip = false;
  // bool _isPipActive = false;
  // bool _wasPlayingBeforeBackground = false;
  // // Asked of the platform once the data source is ready instead of assumed
  // // from the OS, so the control is offered wherever PiP actually works.
  // bool _pipSupported = false;
  // AppLifecycleState _lastLifecycleState = AppLifecycleState.resumed;

  // // How long to wait for the platform to confirm PiP actually started before
  // // treating the request as refused. better_player_plus starts iOS PiP from a
  // // native delegate ~200ms after the call returns and implements no
  // // `failedToStartPictureInPictureWithError` callback, so a refusal produces
  // // no event at all — see [_confirmPipStarted].
  // static const Duration _pipStartTimeout = Duration(milliseconds: 1200);

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
    // PIP-DISABLED (App Review 2.5.4, Sept 2026): no lifecycle observer while
    // PiP is off — handleLifecycle:true hands pause/resume back to the plugin.
    // Restoring needs `audio` back in UIBackgroundModes + a review recording.
    // WidgetsBinding.instance.addObserver(this);
    _initPlayer();
  }

  // PIP-DISABLED (App Review 2.5.4, Sept 2026): this whole lifecycle hook only
  // existed to start/stop PiP on backgrounding; with `audio` gone from
  // UIBackgroundModes iOS refuses the request, so it just burned the
  // _pipStartTimeout wait before falling back to a pause. handleLifecycle is
  // back to true in _initPlayer and the plugin pauses/resumes on its own.
  // Restoring needs `audio` re-added to UIBackgroundModes plus a screen
  // recording of the PiP control for the review notes.
  //
  // Leaving the app while a video is playing shrinks it into the floating PiP
  // window instead of pausing it, on iPhone as well as Android. Which
  // lifecycle state that request has to be made from — and whether coming back
  // has to close the window by hand — is the only thing that differs between
  // the two, and both live in [VideoLifecyclePolicy].
  //
  // BetterPlayerConfiguration.handleLifecycle is intentionally off (see
  // _initPlayer): its own AppLifecycleState handling pauses playback on
  // every backgrounding with no regard for PiP, which would instantly
  // freeze the floating window instead of letting it keep playing. We take
  // over that pause/resume bookkeeping here so an active/about-to-start PiP
  // session is exempted.
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   final controller = _controller;
  //   if (controller == null) return;
  //   _lastLifecycleState = state;
  //
  //   final isPlaying = controller.isPlaying() ?? false;
  //   // Recorded on the way out rather than at `paused` alone: on iOS the PiP
  //   // request goes out one state earlier, so `paused` can arrive with playback
  //   // already handed to the floating window.
  //   if (state != AppLifecycleState.resumed && isPlaying && !_isPipActive) {
  //     _wasPlayingBeforeBackground = true;
  //   }
  //
  //   final action = _policy.actionFor(
  //     state: state,
  //     isPlaying: isPlaying,
  //     isPipActive: _isPipActive,
  //     isEnteringPip: _isEnteringPip,
  //     wasPlayingBeforeBackground: _wasPlayingBeforeBackground,
  //   );
  //
  //   switch (action) {
  //     case VideoLifecycleAction.enterPip:
  //       _handleBackgrounding();
  //     case VideoLifecycleAction.exitPip:
  //       _exitPipMode();
  //     case VideoLifecycleAction.pause:
  //       controller.pause();
  //     case VideoLifecycleAction.resume:
  //       controller.play();
  //     case VideoLifecycleAction.none:
  //       break;
  //   }
  //
  //   if (state == AppLifecycleState.resumed) {
  //     _wasPlayingBeforeBackground = false;
  //   }
  // }

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
      // PIP-DISABLED (App Review 2.5.4, Sept 2026): back to the plugin default
      // (true) so playback simply pauses on backgrounding and resumes on
      // return. It was false only so an active PiP session could be exempted
      // from that pause. Restoring PiP means setting this back to false AND
      // re-adding `audio` to UIBackgroundModes, plus a screen recording for
      // the review notes.
      //
      // Handled manually in didChangeAppLifecycleState so an active PiP
      // session is exempted from the pause-on-background behaviour.
      // handleLifecycle: false,
      handleLifecycle: true,
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
        iconsColor: AppColors.whiteColor,
        textColor: AppColors.whiteColor,
        enableFullscreen: true,
        // PIP-DISABLED (App Review 2.5.4, Sept 2026): kept explicitly false so
        // the plugin's own PiP entry in the overflow menu stays hidden — do
        // not gate this on isPictureInPictureSupported(), which still returns
        // true on iOS even though AVPictureInPictureController cannot start
        // without `audio` in UIBackgroundModes. Restoring PiP needs that key
        // re-added plus a screen recording for the review notes.
        //
        // Better Player's built-in PiP callback is not guarded and can issue
        // overlapping native PiP requests. The dedicated control below routes
        // every request through [_enterPipMode] instead.
        enablePip: false,
        enableQualities: true,
        enableSubtitles: false,
        enablePlaybackSpeed: true,
        controlsHideTime: Duration(milliseconds: 2200),
        controlBarHeight: 52,
        controlBarColor: AppPalette.mediaScrim,
        progressBarPlayedColor: AppPalette.statusInfo,
        progressBarHandleColor: AppPalette.statusInfo,
        progressBarBufferedColor: AppPalette.onMediaHint,
        progressBarBackgroundColor: AppPalette.onMediaTrack,
        overflowMenuIcon: Icons.more_vert_rounded,
        qualitiesIcon: Icons.high_quality_rounded,
        playbackSpeedIcon: Icons.speed_rounded,
        fullscreenEnableIcon: Icons.fullscreen_rounded,
        fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        playIcon: Icons.play_arrow_rounded,
        pauseIcon: Icons.pause_rounded,
        overflowModalColor: AppPalette.surfaceInverse,
        overflowModalTextColor: AppPalette.statusInfoSoft,
        overflowMenuIconsColor: AppColors.whiteColor,
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
    // PIP-DISABLED (App Review 2.5.4, Sept 2026): no PiP session to track.
    // Restoring needs `audio` back in UIBackgroundModes + a review recording.
    // if (event.betterPlayerEventType == BetterPlayerEventType.pipStart) {
    //   _isPipActive = true;
    // } else if (event.betterPlayerEventType == BetterPlayerEventType.pipStop) {
    //   _isPipActive = false;
    //   // Closing the floating window is a deliberate stop, so returning to the
    //   // app must not silently restart the video from the pre-background flag.
    //   _wasPlayingBeforeBackground = false;
    // }
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      // PIP-DISABLED (App Review 2.5.4, Sept 2026): nothing consumes the
      // support flag while the PiP control is hidden.
      // _refreshPipSupport();
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

  // PIP-DISABLED (App Review 2.5.4, Sept 2026): every native PiP call site
  // below is dormant — with `audio` commented out of UIBackgroundModes in
  // ios/Runner/Info.plist, AVPictureInPictureController refuses to start and
  // enablePictureInPicture() would only lock the controls out for the
  // _pipStartTimeout wait. Note isPictureInPictureSupported() still returns
  // true on iOS in that state, so it is not a usable gate on its own.
  // Restoring: re-add `audio` to UIBackgroundModes, submit that change on its
  // own, and attach a screen recording of the PiP control for the review notes.
  //
  // /// Returns whether PiP was actually requested, so callers driven by
  // /// backgrounding (see [_handleBackgrounding]) know whether to fall back
  // /// to a plain pause instead of leaving the video playing off-screen.
  // Future<bool> _enterPipMode() async {
  //   if (_isEnteringPip) return false;
  //   final controller = _controller;
  //   if (controller == null || _playerKey.currentContext == null) return false;
  //
  //   setState(() => _isEnteringPip = true);
  //   try {
  //     final supported = await controller.isPictureInPictureSupported();
  //     if (!mounted) return false;
  //     if (!supported) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('PiP is not supported on this device right now.'),
  //         ),
  //       );
  //       return false;
  //     }
  //     await controller.enablePictureInPicture(_playerKey);
  //     return await _confirmPipStarted(controller);
  //   } catch (error, stackTrace) {
  //     // The plugin delegates this to the platform activity. A lifecycle race
  //     // (for example, entering PiP while the player is disposing) used to
  //     // bubble up as an unhandled exception and terminate the screen/app.
  //     debugPrint('Unable to enter picture-in-picture: $error\n$stackTrace');
  //     // enablePictureInPicture() disables the controls before it asks the
  //     // platform and only restores them on a `pipStop` event that a failed
  //     // request never produces — undo it here or the player is left with a
  //     // video the user can no longer pause.
  //     controller.setControlsEnabled(true);
  //     if (!mounted) return false;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Unable to start picture-in-picture.')),
  //     );
  //     return false;
  //   } finally {
  //     if (mounted) setState(() => _isEnteringPip = false);
  //   }
  // }
  //
  // /// Waits for the platform to confirm PiP is actually on screen.
  // ///
  // /// Android posts `pipStart` from Dart the moment the request is made, so
  // /// this returns immediately there. iOS reports it from an
  // /// `AVPictureInPictureControllerDelegate` callback a moment later, and
  // /// better_player_plus implements no `failedToStartPictureInPicture...`
  // /// counterpart — so a refused request is indistinguishable from a slow one
  // /// except by waiting. Without this, a refusal on iPhone leaves the video
  // /// playing with the controls still locked out by
  // /// `enablePictureInPicture()`.
  // Future<bool> _confirmPipStarted(BetterPlayerController controller) async {
  //   if (_isPipActive) return true;
  //   const step = Duration(milliseconds: 100);
  //   for (var waited = Duration.zero;
  //       waited < _pipStartTimeout;
  //       waited += step) {
  //     await Future<void>.delayed(step);
  //     if (!mounted) return _isPipActive;
  //     if (_isPipActive) return true;
  //   }
  //   controller.setControlsEnabled(true);
  //   return false;
  // }
  //
  // /// Closes the floating window. iOS only — see
  // /// [VideoLifecyclePolicy.exitsPipOnResume].
  // Future<void> _exitPipMode() async {
  //   final controller = _controller;
  //   if (controller == null || !_isPipActive) return;
  //   try {
  //     await controller.disablePictureInPicture();
  //   } catch (error, stackTrace) {
  //     debugPrint('Unable to leave picture-in-picture: $error\n$stackTrace');
  //   }
  // }
  //
  // /// Asks the platform whether PiP is usable so the control is only offered
  // /// where it works — an iPhone before iOS 14, or an Android build without
  // /// FEATURE_PICTURE_IN_PICTURE, still gets no button.
  // Future<void> _refreshPipSupport() async {
  //   final controller = _controller;
  //   if (controller == null) return;
  //   var supported = false;
  //   try {
  //     supported = await controller.isPictureInPictureSupported();
  //   } catch (error) {
  //     debugPrint('Unable to query picture-in-picture support: $error');
  //   }
  //   if (!mounted || supported == _pipSupported) return;
  //   setState(() => _pipSupported = supported);
  // }
  //
  // // Falls back to a plain pause when auto-PiP can't be started (unsupported
  // // device, race with disposal, etc.) so the video doesn't keep playing
  // // silently off-screen with nothing showing it.
  // Future<void> _handleBackgrounding() async {
  //   final started = await _enterPipMode();
  //   if (started) return;
  //   // The confirmation wait above can outlast the trip to the background, so
  //   // the user may already be looking at the player again by the time we get
  //   // here — pausing then would yank playback out from under them.
  //   if (_lastLifecycleState == AppLifecycleState.resumed) return;
  //   _controller?.pause();
  // }

  @override
  void dispose() {
    // PIP-DISABLED (App Review 2.5.4, Sept 2026): paired with the addObserver
    // in initState. Restoring needs `audio` back in UIBackgroundModes + a
    // review screen recording.
    // WidgetsBinding.instance.removeObserver(this);
    _controller?.removeEventsListener(_onPlayerEvent);
    _observedVideoController?.removeListener(_applyAspectRatio);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.whiteColor),
      );
    }
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              // PIP-DISABLED (App Review 2.5.4, Sept 2026): the key only ever
              // gave enablePictureInPicture() a render box to shrink.
              // Restoring needs `audio` back in UIBackgroundModes + a review
              // screen recording.
              // key: _playerKey,
              color: AppColors.blackColor,
              child: Theme(
                data: Theme.of(context).copyWith(
                  brightness: Brightness.dark,
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.whiteColor,
                    onPrimary: AppColors.whiteColor,
                    secondary: AppColors.whiteColor,
                    onSecondary: AppColors.whiteColor,
                    surface: AppColors.blackColor,
                    onSurface: AppColors.whiteColor,
                  ),
                  iconTheme: const IconThemeData(color: AppColors.whiteColor),
                  primaryIconTheme: const IconThemeData(color: AppColors.whiteColor),
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: AppColors.whiteColor,
                    displayColor: AppColors.whiteColor,
                  ),
                ),
                child: BetterPlayer(controller: _controller!),
              ),
            ),
          ),
          // PIP-DISABLED (App Review 2.5.4, Sept 2026): the PiP control is
          // hidden because iOS can no longer start PiP — `audio` is commented
          // out of UIBackgroundModes in ios/Runner/Info.plist, so
          // AVPictureInPictureController refuses to start and the button was a
          // visible dead control. isPictureInPictureSupported() still reports
          // true on iOS in that state, so the `_pipSupported` gate below does
          // NOT hide it on its own.
          // To restore: re-add `audio` to UIBackgroundModes and submit that
          // change on its own with a screen recording of this control driving
          // PiP for the review notes.
          //
          // Shown once the platform has confirmed it can honour the request,
          // so a device without PiP support never gets a dead button.
          // if (_pipSupported)
          //   Positioned(
          //     top: 0,
          //     right: 0,
          //     child: SafeArea(
          //       child: Padding(
          //         // The host screen (ShowFullScreenMedia / ShowFullScreenMediaView)
          //         // now overlays its back/download row on top of the video instead
          //         // of reserving a fixed AppBar — pushed down here so PiP doesn't
          //         // sit underneath it.
          //         padding: const EdgeInsets.only(top: 58, right: 14),
          //         child: DecoratedBox(
          //           decoration: BoxDecoration(
          //             color: AppPalette.mediaScrim,
          //             borderRadius: BorderRadius.circular(22),
          //             border: Border.all(color: AppPalette.statusInfoSoft),
          //           ),
          //           child: IconButton(
          //             tooltip: 'PiP',
          //             onPressed: _isEnteringPip ? null : _enterPipMode,
          //             icon: const Icon(
          //               Icons.picture_in_picture_alt_rounded,
          //               color: Colors.white,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
