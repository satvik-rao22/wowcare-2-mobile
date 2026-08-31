import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/return_code.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/shared/common/widgets/hls_web_player.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class ShowFullScreenMediaView extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? videoUrl;

  /// A local video file (e.g. a pending composer attachment not yet uploaded),
  /// played in-app with a Chewie player. Prefer [videoUrl] for remote/HLS video.
  final File? videoFile;
  final String? title;
  final String? heroTag;

  const ShowFullScreenMediaView({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.videoUrl,
    this.videoFile,
    this.title,
    this.heroTag,
  }) : assert(
         (imageUrl != null ||
             imageFile != null ||
             videoUrl != null ||
             videoFile != null),
         'Provide at least one media source',
       );

  @override
  State<ShowFullScreenMediaView> createState() =>
      _ShowFullScreenMediaViewState();
}

class _ShowFullScreenMediaViewState extends State<ShowFullScreenMediaView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // A caller can pass an empty string (not null) for imageUrl/videoUrl when
  // its own remote-URL resolution hasn't completed yet but a local file is
  // already available — treating `!= null` as "usable" then picks the
  // Image.network('')/HLS-empty-url branch below and fails, even though the
  // local file would have rendered fine. Require non-empty, not just non-null.
  bool get _hasUsableImageUrl => (widget.imageUrl?.isNotEmpty ?? false);
  bool get _hasUsableVideoUrl => (widget.videoUrl?.isNotEmpty ?? false);
  bool get hasImage => _hasUsableImageUrl || widget.imageFile != null;
  bool get hasVideo => _hasUsableVideoUrl || widget.videoFile != null;

  bool _isDownloading = false;

  Future<Uint8List>? _imageBytesFuture;

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
    if (hasImage) {
      _imageBytesFuture = _resolveImageBytes();
    }
  }

  // The chat bubble thumbnail (`displaySource`) prefers the local file over
  // the remote URL whenever both are set — e.g. right after sending, before
  // the CDN has propagated or when the "remote" URL needs signed/auth access
  // a bare http.get can't satisfy. This mirrors that preference so a message
  // that renders fine as a thumbnail never fails full-screen for the exact
  // same attachment: try the local file first, only fetch the network URL
  // if there's no usable local file or reading it fails.
  Future<Uint8List> _resolveImageBytes() async {
    final file = widget.imageFile;
    if (file != null) {
      try {
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            try {
              final codec = await ui.instantiateImageCodec(bytes);
              codec.dispose();
              return bytes;
            } catch (_) {
              // Local file isn't a decodable image; fall through to the URL.
            }
          }
        }
      } catch (_) {
        // Local file unreadable/missing; fall through to the URL.
      }
    }
    // The message bubble's own thumbnail loads the same URL via a retrying
    // byte-fetch (see MessageBubble._fetchImageBytesWithRetry) — a single
    // transient hiccup (CDN not fully propagated yet, brief network blip)
    // makes the thumbnail retry through it invisibly, while a bare
    // Image.network here failed outright on the very first attempt. Mirror
    // that resilience so "the preview loaded fine" never disagrees with
    // "full screen failed to load" for the exact same URL.
    if (_hasUsableImageUrl) {
      return _fetchImageBytesWithRetry(widget.imageUrl!);
    }
    return Uint8List(0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Download to gallery ─────────────────────────────────────────────────
  // Same mechanism as the Activities feature's ShowFullScreenMedia: `gal`
  // saves a local file to the device gallery; a remote URL is first
  // materialized to a temp file via Dio (or, for HLS video, transcoded to
  // mp4 via ffmpeg_kit). An already-local source (a pending composer
  // attachment) is saved directly, no network/transcode step needed.

  bool _isHlsUrl(String url) => url.trim().toLowerCase().contains('.m3u8');

  Future<String> _materializeVideoToTempFile(
    String url,
    String fileName,
  ) async {
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

    await Dio().download(url, outPath);
    return outPath;
  }

  Future<String> _materializePhotoToTempFile(
    String url,
    String fileName,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final outPath = path.join(tempDir.path, fileName);
    await Dio().download(url, outPath);
    return outPath;
  }

  Future<void> _downloadCurrentMedia() async {
    if (_isDownloading) return;
    if (!hasImage && !hasVideo) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media is still processing. Please try again.'),
        ),
      );
      return;
    }

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
            content: Text(
              'Photos permission is required to save media to your gallery.',
            ),
          ),
        );
        return;
      }

      final stamp = AppTime.nowUtc().millisecondsSinceEpoch;
      if (hasVideo) {
        String filePath;
        var isTemp = false;
        if (_hasUsableVideoUrl) {
          final videoUrl = widget.videoUrl!;
          final tempName = _isHlsUrl(videoUrl)
              ? 'wowcare_video_$stamp.mp4'
              : 'wowcare_video_$stamp${path.extension(Uri.parse(videoUrl).path).isNotEmpty ? path.extension(Uri.parse(videoUrl).path) : '.mp4'}';
          filePath = await _materializeVideoToTempFile(videoUrl, tempName);
          isTemp = true;
        } else {
          filePath = widget.videoFile!.path;
        }
        await Gal.putVideo(filePath);
        if (isTemp) {
          try {
            await File(filePath).delete();
          } catch (_) {}
        }
      } else {
        String filePath;
        var isTemp = false;
        if (_hasUsableImageUrl) {
          final imageUrl = widget.imageUrl!;
          final ext = path
              .extension(Uri.parse(imageUrl).path)
              .trim()
              .toLowerCase();
          final safeExt = ext.isNotEmpty ? ext : '.jpg';
          filePath = await _materializePhotoToTempFile(
            imageUrl,
            'wowcare_photo_$stamp$safeExt',
          );
          isTemp = true;
        } else {
          filePath = widget.imageFile!.path;
        }
        await Gal.putImage(filePath);
        if (isTemp) {
          try {
            await File(filePath).delete();
          } catch (_) {}
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your photo gallery.')),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.type.message)));
    } catch (e) {
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

  Future<Uint8List> _fetchImageBytesWithRetry(String url) async {
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await http.get(Uri.parse(url));
        // A 200 response isn't proof the body is actually a decodable image
        // — a still-propagating CDN edge, an auth/redirect landing page, or
        // a body cut short mid-transfer all come back as 200 with non-image
        // bytes. Handing those straight to Image.memory is what threw
        // "Invalid image data" here (and, since MemoryImage decodes async,
        // past errorBuilder's ability to just quietly show the fallback —
        // it's also reported to the image resource service's error stream).
        // Verify the bytes actually decode before accepting this attempt as
        // a success; anything that doesn't decode is treated exactly like a
        // network failure and retried.
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final bytes = response.bodyBytes;
          try {
            final codec = await ui.instantiateImageCodec(bytes);
            codec.dispose();
            return bytes;
          } catch (_) {
            // Falls through to retry below.
          }
        }
      } catch (_) {}
      if (i < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 600 * (i + 1)));
      }
    }
    return Uint8List(0);
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.white54, size: 80),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (!hasImage) {
      return const Icon(Icons.broken_image, color: Colors.white54, size: 100);
    }
    return FutureBuilder<Uint8List>(
      future: _imageBytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: PrimaryCircularLoader(
                size: 28,
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return _brokenImagePlaceholder();
        }
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _brokenImagePlaceholder(),
        );
      },
    );
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
        actions: [
          if (hasImage || hasVideo)
            IconButton(
              tooltip: 'Download',
              icon: _isDownloading
                  ? const PrimaryCircularLoader(
                      size: 18,
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
              onPressed: _downloadCurrentMedia,
            ),
        ],
      ),
      body: hasVideo
          ? (_hasUsableVideoUrl
                ? HlsWebPlayer(videoUrl: widget.videoUrl!)
                : _LocalVideoPlayer(file: widget.videoFile!))
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

/// In-app player for a LOCAL video file (e.g. a pending composer attachment).
/// Uses video_player + Chewie; owns and disposes its controllers.
class _LocalVideoPlayer extends StatefulWidget {
  const _LocalVideoPlayer({required this.file});

  final File file;

  @override
  State<_LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<_LocalVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.file(widget.file);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          allowFullScreen: false,
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.white,
            handleColor: Colors.white,
            bufferedColor: Colors.white54,
            backgroundColor: Colors.white24,
          ),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _initError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white54, size: 80),
      );
    }
    if (_chewieController == null) {
      return const Center(
        child: PrimaryCircularLoader(
          size: 28,
          strokeWidth: 2,
          color: Colors.white70,
        ),
      );
    }
    return Center(child: Chewie(controller: _chewieController!));
  }
}
