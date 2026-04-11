import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/core/util/core_utils.dart';

class ShowFullScreenMedia extends StatefulWidget {
  final ActivityItem activity;
  const ShowFullScreenMedia({super.key, required this.activity});

  @override
  State<ShowFullScreenMedia> createState() => _ShowFullScreenMediaState();
}

class _ShowFullScreenMediaState extends State<ShowFullScreenMedia> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoInitFailed = false;

  void _initializeVideo() async {
    final videoUrl = widget.activity.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _videoPlayerController?.initialize();
    } catch (e) {
      debugPrint('Failed to initialize full-screen video: $e');
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      if (!mounted) return;
      setState(() {
        _videoInitFailed = true;
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Unable to play this video on this device. Please use standard MP4 (H.264).',
        isWarning: true,
      );
      return;
    }

    if (!mounted) return;

    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black12,
          //color: widget.activity.color,
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        },
    );
    setState(() {});
  }

  @override
  void initState(){
    super.initState();
    final videoUrl = widget.activity.videoUrl;
    if(videoUrl != null && videoUrl.isNotEmpty){
      _initializeVideo();
    }
  }

  @override
  void dispose(){
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    final String? videoUrl = widget.activity.videoUrl;
    final String? photoUrl = widget.activity.photoUrl;
    final bool hasVideo = videoUrl?.isNotEmpty == true;
    final bool hasPhoto = photoUrl?.isNotEmpty == true;
    return Scaffold(
      backgroundColor: Colors.black12,
      //backgroundColor: widget.activity.color,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // title: Text(
        //   widget.activity.name,
        //   style: const TextStyle(color: Colors.white),
        // ),

      ),
      body: Center(
        child: hasVideo
            ? (_videoInitFailed
                ? const Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.white70,
                    size: 84,
                  )
                : (_chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const CircularProgressIndicator(color: Colors.white)))
            : (hasPhoto
            ? InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          //minScale: 0.5,
          //maxScale: 4,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (c, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(color: Colors.white),
            errorBuilder: (c, e, s) =>
            const Icon(Icons.error, color: Colors.white, size: 60),
          ),
        )
            : const Icon(Icons.broken_image, color: Colors.white, size: 100)),
      ),
    );

  }
}
