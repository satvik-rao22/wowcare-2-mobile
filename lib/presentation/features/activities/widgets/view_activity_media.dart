import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../view/activity_daily_tab.dart';

class ActivityMediaViewer extends StatefulWidget {
  final ActivityItem activity;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final String? label;

  const ActivityMediaViewer({
    super.key,
    this.label,
    required this.activity,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<ActivityMediaViewer> createState() => _ActivityMediaViewerState();
}

class _ActivityMediaViewerState extends State<ActivityMediaViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _videoInitFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity.videoUrl != null && widget.activity.videoUrl!.isNotEmpty) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    _videoInitFailed = false;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.activity.videoUrl!));
    _controller!.addListener(() {
      if(_controller!.value.position >= _controller!.value.duration){
        if(mounted){
          setState(() {
            _isPlaying = false;
          });
        }
        //_controller?.seekTo(Duration.zero);
      }
    });
    try {
      await _controller!.initialize();
      _controller!.setVolume(1.0); // Sound on
      _controller!.setLooping(false);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Video failed to initialize: $e");
      _controller?.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() {
        _videoInitFailed = true;
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Video preview is not supported on this device. Please open in full screen or use standard MP4 (H.264).',
        isWarning: true,
      );
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized || _controller == null) return;

    setState(() {
      if (_isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final hasVideo = widget.activity.videoUrl != null && widget.activity.videoUrl!.isNotEmpty;
    final hasPhoto = widget.activity.photoUrl != null && widget.activity.photoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(widget.label != null)
          Text(
            widget.label!,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize:  13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Manrope',
            ),
          ),
        if(widget.label != null)
          SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),

        ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height ?? 200,
            color: Colors.black12.withOpacity(0.15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video or Photo
                if (hasVideo && _isInitialized)
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                else if (hasVideo)
                  _videoInitFailed
                      ? _buildVideoUnsupportedPlaceholder()
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                else if (hasPhoto)
                    Image.network(
                      widget.activity.photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorBuilder: (context, error, _) => _buildErrorPlaceholder(),
                    )
                  else
                    _buildErrorPlaceholder(),

                // Tap to play/pause + big play icon overlay
                if (hasVideo)
                  InkWell(
                    onTap: _togglePlayPause,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),


                if (hasVideo && _isInitialized && _isPlaying)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black12.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.broken_image, size: 60, color: Colors.white70),
      ),
    );
  }

  Widget _buildVideoUnsupportedPlaceholder() {
    return Container(
      color: Colors.black12.withOpacity(0.25),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 42, color: Colors.white70),
            SizedBox(height: 8),
            Text(
              'Video preview unavailable',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}