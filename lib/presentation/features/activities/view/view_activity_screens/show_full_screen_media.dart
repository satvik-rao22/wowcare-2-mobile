import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/return_code.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/presentation/features/activities/view/activity_daily_tab.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';

class ShowFullScreenMedia extends StatefulWidget {
  /// Source activity. Optional so the same viewer can be opened with a raw
  /// [photoUrl] / [videoUrl] (e.g. from the activity-detail screen) and still
  /// get the identical zoom viewport + download button as the feed list.
  final ActivityItem? activity;
  final String? photoUrl;
  final String? videoUrl;
  const ShowFullScreenMedia({
    super.key,
    this.activity,
    this.photoUrl,
    this.videoUrl,
  });

  @override
  State<ShowFullScreenMedia> createState() => _ShowFullScreenMediaState();
}

class _ShowFullScreenMediaState extends State<ShowFullScreenMedia> {
  bool _isDownloading = false;

  bool _isHlsUrl(String url) {
    final lower = url.trim().toLowerCase();
    return lower.contains('.m3u8');
  }

  Future<String> _materializeVideoToTempFile(String url, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final outPath = path.join(tempDir.path, fileName);

    if (_isHlsUrl(url)) {
      Future<bool> runCopy(List<String> args) async {
        final session = await FFmpegKit.executeWithArguments(args);
        final code = await session.getReturnCode();
        return ReturnCode.isSuccess(code);
      }

      final baseArgs = <String>[
        '-y',
        '-protocol_whitelist',
        'file,http,https,tcp,tls,crypto',
        '-i',
        url,
        '-c',
        'copy',
      ];

      final withBsf = [...baseArgs, '-bsf:a', 'aac_adtstoasc', outPath];
      if (await runCopy(withBsf)) return outPath;

      final plainCopy = [...baseArgs, outPath];
      if (await runCopy(plainCopy)) return outPath;

      final session = await FFmpegKit.executeWithArguments(plainCopy);
      final out = await session.getOutput();
      throw Exception(out ?? 'Could not convert stream to a video file.');
    }

    final dio = Dio();
    await dio.download(url, outPath);
    return outPath;
  }

  Future<String> _materializePhotoToTempFile(String url, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final outPath = path.join(tempDir.path, fileName);
    await Dio().download(url, outPath);
    return outPath;
  }

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
    if (Uri.tryParse(raw) == null) return;

    setState(() => _isDownloading = true);
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }
      if (!await Gal.hasAccess(toAlbum: true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos permission is required to save media to your gallery.'),
          ),
        );
        return;
      }

      final isVideo = videoUrl != null && videoUrl.trim().isNotEmpty;
      final ext = path.extension(Uri.parse(raw).path).trim().toLowerCase();
      final safeExt = ext.isNotEmpty ? ext : (isVideo ? '.mp4' : '.jpg');
      final stamp = AppTime.nowUtc().millisecondsSinceEpoch;
      final baseName = 'wowcare_${isVideo ? 'video' : 'photo'}_$stamp$safeExt';
      final tempVideoName =
          isVideo && _isHlsUrl(raw) ? 'wowcare_video_$stamp.mp4' : baseName;

      if (isVideo) {
        final filePath = await _materializeVideoToTempFile(raw, tempVideoName);
        await Gal.putVideo(filePath);
        try {
          await File(filePath).delete();
        } catch (_) {}
      } else {
        final filePath = await _materializePhotoToTempFile(raw, baseName);
        await Gal.putImage(filePath);
        try {
          await File(filePath).delete();
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your photo gallery.')),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.type.message)),
      );
    } catch (e) {
      // Do not log the raw exception: a Dio/HTTP error stringifies the request
      // URI, which here is a pre-signed media URL. Log only the error type.
      debugPrint('Failed to download media (${e.runtimeType})');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download media. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? videoUrl = widget.videoUrl ?? widget.activity?.videoUrl;
    final String? photoUrl = widget.photoUrl ?? widget.activity?.photoUrl;
    final bool hasVideo = videoUrl?.isNotEmpty == true;
    final bool hasPhoto = photoUrl?.isNotEmpty == true;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
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
      ),
      body: hasVideo
          ? HlsWebPlayer(videoUrl: videoUrl!)
          : hasPhoto
              // Let the InteractiveViewer fill the whole screen (image centered
              // inside) so the pan/zoom area is the full viewport — not a small
              // box the size of the image.
              ? InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      photoUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, progress) => progress == null
                          ? child
                          : const Center(
                              child:
                                  CircularProgressIndicator(color: Colors.white),
                            ),
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 100),
                ),
    );
  }
}
