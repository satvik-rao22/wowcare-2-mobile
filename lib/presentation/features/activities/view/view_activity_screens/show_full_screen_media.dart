import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';

class ShowFullScreenMedia extends StatefulWidget {
  final ActivityItem activity;
  const ShowFullScreenMedia({super.key, required this.activity});

  @override
  State<ShowFullScreenMedia> createState() => _ShowFullScreenMediaState();
}

class _ShowFullScreenMediaState extends State<ShowFullScreenMedia> {
  @override
  void initState() {
    super.initState();
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
            ? HlsWebPlayer(videoUrl: videoUrl!)
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
