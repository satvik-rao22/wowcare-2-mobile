import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';
import 'dart:io';

class ShowFullScreenMedia extends StatefulWidget {
  final ActivityItem activity;
  const ShowFullScreenMedia({super.key, required this.activity});

  @override
  State<ShowFullScreenMedia> createState() => _ShowFullScreenMediaState();
}

class _ShowFullScreenMediaState extends State<ShowFullScreenMedia> {
  bool _isDownloading = false;

  Future<void> _downloadCurrentMedia({
    required String? videoUrl,
    required String? photoUrl,
  }) async {
    if (_isDownloading) return;
    final raw = (videoUrl ?? photoUrl ?? '').trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media is still processing. Please try again.')),
      );
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    setState(() => _isDownloading = true);
    try {
      final ext = path.extension(uri.path).trim().toLowerCase();
      final safeExt = ext.isNotEmpty ? ext : (videoUrl != null ? '.mp4' : '.jpg');
      final fileName =
          'wowcare_${videoUrl != null ? 'video' : 'photo'}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
      final dio = Dio();
      String savedPath = '';
      if (Platform.isAndroid) {
        try {
          final publicDownloads = Directory('/storage/emulated/0/Download');
          if (!await publicDownloads.exists()) {
            await publicDownloads.create(recursive: true);
          }
          final savePath = path.join(publicDownloads.path, fileName);
          await dio.download(raw, savePath);
          savedPath = publicDownloads.path;
        } catch (_) {
          final fallback = await getApplicationDocumentsDirectory();
          final savePath = path.join(fallback.path, fileName);
          await dio.download(raw, savePath);
          savedPath = fallback.path;
        }
      } else {
        final docs = await getApplicationDocumentsDirectory();
        final savePath = path.join(docs.path, fileName);
        await dio.download(raw, savePath);
        savedPath = docs.path;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $savedPath')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download media.')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }
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
      backgroundColor: Colors.black,
      //backgroundColor: widget.activity.color,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
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
        actions: [
          IconButton(
            tooltip: 'Download',
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white, size: 24),
            onPressed: () => _downloadCurrentMedia(
              videoUrl: videoUrl,
              photoUrl: photoUrl,
            ),
          ),
        ],
        // title: Text(
        //   widget.activity.name,
        //   style: const TextStyle(color: Colors.white),
        // ),

      ),
      body: hasVideo
          ? HlsWebPlayer(videoUrl: videoUrl!)
          : Center(
              child: hasPhoto
                  ? InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(20),
                      //minScale: 0.5,
                      //maxScale: 4,
                      child: Image.network(
                        photoUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) => progress == null
                            ? child
                            : const CircularProgressIndicator(color: Colors.white),
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.error, color: Colors.white, size: 60),
                      ),
                    )
                  : const Icon(Icons.broken_image, color: Colors.white, size: 100),
            ),
    );

  }
}
