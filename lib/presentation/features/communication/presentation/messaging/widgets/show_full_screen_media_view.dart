import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';

class ShowFullScreenMediaView extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? videoUrl;
  final String? title;

  const ShowFullScreenMediaView({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.videoUrl,
    this.title,
  }) : assert(
         (imageUrl != null || imageFile != null || videoUrl != null),
         'Provide at least one media source',
       );

  @override
  State<ShowFullScreenMediaView> createState() =>
      _ShowFullScreenMediaViewState();
}

class _ShowFullScreenMediaViewState extends State<ShowFullScreenMediaView> {
  bool get hasImage => widget.imageUrl != null || widget.imageFile != null;
  bool get hasVideo => widget.videoUrl != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: widget.title != null
            ? Text(widget.title!, style: const TextStyle(color: Colors.white))
            : null,
      ),
      body: hasVideo
          ? HlsWebPlayer(videoUrl: widget.videoUrl!)
          : Center(
              child: hasImage
                  ? InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: widget.imageUrl != null
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const CircularProgressIndicator(
                                      color: Colors.white,
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 100,
                                  ),
                            )
                          : Image.file(
                              widget.imageFile!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 100,
                                  ),
                            ),
                    )
                  : const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
            ),
    );
  }
}
