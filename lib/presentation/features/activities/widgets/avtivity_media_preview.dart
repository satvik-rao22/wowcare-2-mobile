import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/show_full_screen_media.dart';

import '../../../../app/theme/media_res.dart';

class ActivityMediaPreview extends StatefulWidget {
  final ActivityItem activity;
  const ActivityMediaPreview({super.key, required this.activity});


  @override
  State<ActivityMediaPreview> createState() => _ActivityMediaPreviewState();
}

class _ActivityMediaPreviewState extends State<ActivityMediaPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  static final Map<String, dynamic> activityIcons = {
    'Nap': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };

  @override
  void initState(){
    super.initState();
    final videoUrl = widget.activity.videoUrl;
    if(videoUrl != null && videoUrl.isNotEmpty){
      _loadThumbnail();
    }
  }
  void _loadThumbnail() async{
    final videoUrl = widget.activity.videoUrl;
    if(videoUrl == null || videoUrl.isEmpty) return;
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try{
      await _controller!.initialize();
      _controller!.setVolume(0);
      if (mounted){
        setState(() {
          _isInitialized = true;
        });
      }
    } catch(e){
      debugPrint('Error in loading thumbnail : $e');
    }
  }

  @override
  void dispose(){
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? videoUrl = widget.activity.videoUrl;
    final String? photoUrl = widget.activity.photoUrl;
    final bool hasVideo = videoUrl?.isNotEmpty == true;
    final bool hasPhoto = photoUrl?.isNotEmpty == true;
    return InkWell(
      onTap: () {
        if ( photoUrl?.isNotEmpty == true || videoUrl?.isNotEmpty == true) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShowFullScreenMedia(activity: widget.activity),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo && _isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller?.value.size.width,
                height: _controller?.value.size.height,
                child: VideoPlayer(_controller!),
              ),

            )
          else if (hasVideo)
            Container(
              color: widget.activity.color.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,),
              ),

            )
          else if (hasPhoto)
            Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress)=> progress == null ? child : Container(color: widget.activity.color.withOpacity(0.3)),
              errorBuilder: (c, e, s)=> _buildIconFallback(),

            )
          else
            _buildIconFallback(),

          if (hasVideo)
            const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size : 50,
              ),
            )
        ],
      ),
    );
  }

  Widget _buildIconFallback(){
    return Container(
      width: 122,
      height: 76,
      color: widget.activity.color
          .withOpacity(0.25),
      child: Center(
        child: Image.asset(
          activityIcons[widget.activity
              .name],
          //'assets/icons/activity-nap-icon.png',
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
