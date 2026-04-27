import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class HlsWebPlayer extends StatefulWidget {
  const HlsWebPlayer({
    super.key,
    required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<HlsWebPlayer> createState() => _HlsWebPlayerState();
}

class _HlsWebPlayerState extends State<HlsWebPlayer> {
  BetterPlayerController? _controller;
  final GlobalKey _playerKey = GlobalKey();
  static const List<String> _youtubeLikeTrackNames = <String>[
    'Auto',
    '144p',
    '240p',
    '360p',
    '480p',
    '720p',
    '1080p',
    '1440p',
    '2160p',
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
        enableFullscreen: true,
        enablePip: true,
        enableQualities: true,
        enableSubtitles: false,
        enablePlaybackSpeed: true,
        controlsHideTime: Duration(milliseconds: 1600),
        controlBarHeight: 52,
        controlBarColor: Color(0xCC0F1115),
        progressBarPlayedColor: Color(0xFF4F8CFF),
        progressBarHandleColor: Color(0xFF6FA2FF),
        progressBarBufferedColor: Color(0x99FFFFFF),
        progressBarBackgroundColor: Color(0x40FFFFFF),
        overflowMenuIcon: Icons.more_vert_rounded,
        qualitiesIcon: Icons.high_quality_rounded,
        playbackSpeedIcon: Icons.speed_rounded,
        pipMenuIcon: Icons.picture_in_picture_alt_rounded,
        fullscreenEnableIcon: Icons.fullscreen_rounded,
        fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        playIcon: Icons.play_arrow_rounded,
        pauseIcon: Icons.pause_rounded,
        overflowModalColor: Color(0xFF111827),
        overflowModalTextColor: Color(0xFFF3F6FC),
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
        ),
      ],
    );

    final source = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: isHls
          ? BetterPlayerVideoFormat.hls
          : BetterPlayerVideoFormat.other,
      asmsTrackNames: isHls ? _youtubeLikeTrackNames : null,
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
      // Force full-screen occupancy. This avoids tiny center rendering when
      // stream metadata reports unstable dimensions/aspect values.
      controller.setOverriddenFit(BoxFit.cover);
    }
  }

  Future<void> _enterPipMode() async {
    final controller = _controller;
    if (controller == null) return;
    final supported = await controller.isPictureInPictureSupported();
    if (!mounted) return;
    if (!supported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PiP is not supported on this device right now.')),
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
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              key: _playerKey,
              color: Colors.black,
              child: BetterPlayer(controller: _controller!),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xA6111827),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: IconButton(
                tooltip: 'PiP',
                onPressed: _enterPipMode,
                icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

