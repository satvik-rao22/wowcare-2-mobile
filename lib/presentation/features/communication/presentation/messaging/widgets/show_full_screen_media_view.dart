import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';

class ShowFullScreenMediaView extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? videoUrl;
  final String? title;
  final String? heroTag;

  const ShowFullScreenMediaView({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.videoUrl,
    this.title,
    this.heroTag,
  }) : assert(
    (imageUrl != null || imageFile != null || videoUrl != null),
    'Provide at least one media source',
  );

  @override
  State<ShowFullScreenMediaView> createState() => _ShowFullScreenMediaViewState();
}

class _ShowFullScreenMediaViewState extends State<ShowFullScreenMediaView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool get hasImage => widget.imageUrl != null || widget.imageFile != null;
  bool get hasVideo => widget.videoUrl != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildMediaWidget() {
    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return const Icon(
        Icons.broken_image,
        color: Colors.white54,
        size: 100,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
      ),
      body: hasVideo
          ? HlsWebPlayer(videoUrl: widget.videoUrl!)
          : Center(
              child: hasImage
                  ? FadeTransition(
                      opacity: _fadeAnimation,
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.8,
                        maxScale: 4.0,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: Hero(
                          tag: widget.heroTag ?? 'media-hero',
                          transitionOnUserGestures: true,
                          child: _buildMediaWidget(),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
            ),
    );
  }
}
