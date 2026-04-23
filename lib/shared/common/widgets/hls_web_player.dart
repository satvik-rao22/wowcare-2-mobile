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
      fit: BoxFit.cover,
      handleLifecycle: true,
      autoDetectFullscreenDeviceOrientation: true,
      autoDetectFullscreenAspectRatio: true,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
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
        overflowMenuIcon: Icons.more_horiz_rounded,
        qualitiesIcon: Icons.high_quality_rounded,
        playbackSpeedIcon: Icons.speed_rounded,
        pipMenuIcon: Icons.picture_in_picture_alt_rounded,
        fullscreenEnableIcon: Icons.fullscreen_rounded,
        fullscreenDisableIcon: Icons.fullscreen_exit_rounded,
        playIcon: Icons.play_arrow_rounded,
        pauseIcon: Icons.pause_rounded,
        overflowModalColor: Color(0xFF161B22),
        overflowModalTextColor: Color(0xFFF3F6FC),
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
    _controller = c;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return BetterPlayer(controller: _controller!);
  }
}

