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
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        enableFullscreen: true,
        enablePip: true,
        enableQualities: true,
      ),
    );

    final source = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: isHls
          ? BetterPlayerVideoFormat.hls
          : BetterPlayerVideoFormat.other,
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

