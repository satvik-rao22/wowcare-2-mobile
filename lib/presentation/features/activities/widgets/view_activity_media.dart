import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import '../../../../core/utils/core_utils.dart';
import '../../../../core/utils/logger_service.dart';
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
    if (widget.activity.videoUrl != null &&
        widget.activity.videoUrl!.isNotEmpty) {
      _initializeVideo();
    }
  }

  void _initializeVideo() async {
    _videoInitFailed = false;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.activity.videoUrl!),
    );
    _controller!.addListener(() {
      if (_controller!.value.position >= _controller!.value.duration) {
        if (mounted) {
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
      AppLogger.e('Video failed to initialize', e);
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
    final hasVideo =
        widget.activity.videoUrl != null &&
        widget.activity.videoUrl!.isNotEmpty;
    final hasPhoto =
        widget.activity.photoUrl != null &&
        widget.activity.photoUrl!.isNotEmpty;
    final hasProcessingMedia = _hasProcessingAttachment(
      widget.activity.snapshotAttachments,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(widget.label!, style: AppTextStyles.activityFieldLabel),
        if (widget.label != null)
          SizedBox(height: responsive.isTablet ? 8.0 : 6.0),

        ClipRRect(
          borderRadius: widget.borderRadius,
          child: Container(
            width: widget.width,
            height: widget.height ?? 200,
            color: AppColors.activityMediaPlaceholderBg.withValues(alpha: 0.15),
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
                          child: CircularProgressIndicator(
                            color: AppColors.cardColor,
                          ),
                        )
                else if (hasPhoto)
                  Image.network(
                    widget.activity.photoUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.cardColor,
                            ),
                          ),
                    errorBuilder: (context, error, _) =>
                        _buildErrorPlaceholder(),
                  )
                else
                  hasProcessingMedia
                      ? _buildProcessingPlaceholder()
                      : _buildErrorPlaceholder(),

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
                            color: AppColors.activityIconBackdropColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: AppColors.cardColor,
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
                        playedColor: AppColors.cardColor,
                        backgroundColor:
                            AppColors.activityVideoProgressTrackColor,
                        bufferedColor:
                            AppColors.activityVideoProgressBufferedColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
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
      color: AppColors.activityMediaPlaceholderBg.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 60,
          color: AppColors.activityMediaPlaceholderIconColor,
        ),
      ),
    );
  }

  Widget _buildVideoUnsupportedPlaceholder() {
    return Container(
      color: AppColors.activityMediaPlaceholderBg.withValues(alpha: 0.25),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 42,
              color: AppColors.activityMediaPlaceholderIconColor,
            ),
            SizedBox(height: 8),
            Text(
              'Video preview unavailable',
              style: AppTextStyles.activityMediaUnavailableText,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasProcessingAttachment(List<Map<String, dynamic>>? attachments) {
    if (attachments == null || attachments.isEmpty) return false;
    for (final row in attachments) {
      final status = (row['status'] ?? '').toString().trim().toUpperCase();
      final isProcessing =
          status == 'PROCESSING' || status == 'UPLOADED' || status == 'PENDING';
      if (!isProcessing) continue;
      // Already servable (processed variants live) → not actually processing.
      if (!attachmentRowHasUsableMedia(row)) return true;
    }
    return false;
  }

  Widget _buildProcessingPlaceholder() {
    return Container(
      color: AppColors.activityProcessingBg,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.activityProcessingAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Video processing...',
              style: AppTextStyles.activityProcessingCaption,
            ),
          ],
        ),
      ),
    );
  }
}
