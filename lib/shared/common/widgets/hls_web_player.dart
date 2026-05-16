import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class HlsWebPlayer extends StatefulWidget {
  const HlsWebPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<HlsWebPlayer> createState() => _HlsWebPlayerState();
}

class _HlsWebPlayerState extends State<HlsWebPlayer> {
  BetterPlayerController? _controller;
  final GlobalKey _playerKey = GlobalKey();
  static const List<String> _limitedTrackNames = <String>[
    'Auto',
    '360p',
    '720p',
  ];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant HlsWebPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _initPlayer();
    }
  }

  void _initPlayer() {
    final url = widget.videoUrl.trim();
    final lower = url.toLowerCase();
    final isHls = lower.contains('.m3u8');

    final config = BetterPlayerConfiguration(
      autoPlay: true,
      fit: BoxFit.contain,
      handleLifecycle: true,
      autoDetectFullscreenDeviceOrientation: true,
      autoDetectFullscreenAspectRatio: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
        playerTheme: BetterPlayerTheme.material,
        iconsColor: Colors.white,
        textColor: Colors.white,
        enableFullscreen: true,
        enablePip: true,
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
        pipMenuIcon: Icons.picture_in_picture_alt_rounded,
        fullscreenEnableIcon: Icons.fullscreen_rounded,
        fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        playIcon: Icons.play_arrow_rounded,
        pauseIcon: Icons.pause_rounded,
        overflowModalColor: Color(0xFF111827),
        overflowModalTextColor: Color(0xFFEAF2FF),
        overflowMenuIconsColor: Colors.white,
        overflowMenuCustomItems: <BetterPlayerOverflowMenuItem>[
          BetterPlayerOverflowMenuItem(
            Icons.picture_in_picture_alt_rounded,
            'Picture in Picture',
            _enterPipMode,
          ),
        ],
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
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      final controller = _controller;
      if (controller == null) return;
      // Keep content visible and avoid crop for tall portrait videos.
      controller.setOverriddenFit(BoxFit.contain);
    }
  }

  Future<void> _enterPipMode() async {
    final controller = _controller;
    if (controller == null) return;
    final supported = await controller.isPictureInPictureSupported();
    if (!mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PiP is not supported on this device right now.'),
        ),
      );
      return;
    }
    await controller.enablePictureInPicture(_playerKey);
  }

  @override
  void dispose() {
    _controller?.removeEventsListener(_onPlayerEvent);
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
            top: 14,
            right: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB010141A),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x6635B6FF)),
              ),
              child: IconButton(
                tooltip: 'PiP',
                onPressed: _enterPipMode,
                icon: const Icon(
                  Icons.picture_in_picture_alt_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
