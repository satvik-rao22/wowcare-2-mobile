import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

enum _DocKind { image, video, pdf, office }

/// In-app viewer for a document/media link resolved from the Staff/Student
/// Documents tab. Renders natively for images/videos/PDFs; falls back to
/// Google's document viewer (via WebView) for office formats (docx, xlsx,
/// pptx, txt, etc.) so users can preview before deciding to download.
/// Typed `extra` for the document-viewer route (§1.5 — no untyped maps).
class DocumentViewerArgs {
  const DocumentViewerArgs({
    required this.url,
    required this.documentName,
    required this.mimeType,
  });

  final String url;
  final String documentName;
  final String mimeType;
}

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.documentName,
    required this.mimeType,
  });

  static const String routeName = '/document-viewer';

  final String url;
  final String documentName;
  final String mimeType;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late final _DocKind _kind;
  VideoPlayerController? _videoController;
  String? _localPdfPath;
  bool _isPreparing = true;
  String? _prepareError;
  bool _isBusy = false;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
    _kind = _resolveKind();
    _prepare();
  }

  _DocKind _resolveKind() {
    final mime = widget.mimeType.trim().toLowerCase();
    if (mime.startsWith('image/') || FileUtils.isImage(widget.url)) {
      return _DocKind.image;
    }
    if (mime.startsWith('video/') || FileUtils.isVideo(widget.url)) {
      return _DocKind.video;
    }
    if (mime == 'application/pdf' || FileUtils.extension(widget.url) == 'pdf') {
      return _DocKind.pdf;
    }
    return _DocKind.office;
  }

  Future<void> _prepare() async {
    AppLogger.d(
      '[DocumentViewerScreen] preparing kind=$_kind '
      'mimeType=${widget.mimeType} url=${widget.url}',
    );
    try {
      switch (_kind) {
        case _DocKind.image:
        case _DocKind.office:
          break;
        case _DocKind.video:
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.url),
          );
          await controller.initialize();
          controller.setLooping(false);
          if (!mounted) {
            controller.dispose();
            return;
          }
          _videoController = controller;
          break;
        case _DocKind.pdf:
          final path = await FileUtils.tempFilePath(
            'doc_preview_${AppTime.nowUtc().millisecondsSinceEpoch}.pdf',
          );
          await Dio().download(widget.url, path);
          if (!mounted) return;
          _localPdfPath = path;
          break;
      }
      if (!mounted) return;
      setState(() => _isPreparing = false);
    } catch (e, st) {
      AppLogger.e(
        '[DocumentViewerScreen] prepare failed kind=$_kind url=${widget.url}',
        e,
        st,
      );
      if (!mounted) return;
      setState(() {
        _prepareError = 'Unable to preview this document.';
        _isPreparing = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    final path = _localPdfPath;
    if (path != null) {
      File(path).delete().catchError((_) => File(path));
    }
    super.dispose();
  }

  Future<void> _openExternally() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final outPath = await FileUtils.tempPathForDownload(
        widget.url,
        name: widget.documentName,
        fallbackExtension: 'bin',
      );

      await Dio().download(widget.url, outPath);
      final result = await OpenFilex.open(outPath);
      if (result.type != ResultType.done && mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: result.message,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Could not open document',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.documentName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.buildPrimaryGradient()),
        ),
        actions: [
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open externally',
              onPressed: _openExternally,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isPreparing) {
      return const Center(child: PrimaryCircularLoader());
    }
    if (_prepareError != null) {
      return _buildFallback(_prepareError!);
    }

    switch (_kind) {
      case _DocKind.image:
        return PhotoView(
          imageProvider: NetworkImage(widget.url),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) =>
              const Center(child: PrimaryCircularLoader()),
          errorBuilder: (context, error, stackTrace) {
            AppLogger.e(
              '[DocumentViewerScreen] image load failed url=${widget.url}',
              error,
              stackTrace is StackTrace ? stackTrace : null,
            );
            return _buildFallback('Unable to load image.');
          },
        );
      case _DocKind.video:
        final controller = _videoController;
        if (controller == null || !controller.value.isInitialized) {
          return _buildFallback('Unable to play video.');
        }
        return _InlineVideoPlayer(controller: controller);
      case _DocKind.pdf:
        final path = _localPdfPath;
        if (path == null) {
          return _buildFallback('Unable to load PDF.');
        }
        return PDFView(
          filePath: path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onError: (error) {
            AppLogger.e(
              '[DocumentViewerScreen] PDF render failed path=$path',
              error,
            );
            if (mounted) {
              setState(() => _prepareError = 'Unable to load PDF.');
            }
          },
        );
      case _DocKind.office:
        if (_webViewFailed) {
          return _buildFallback('Preview not supported for this file type.');
        }
        final viewerUrl =
            'https://docs.google.com/viewer?embedded=true&url=${Uri.encodeComponent(widget.url)}';
        return Container(
          color: Colors.white,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
            onReceivedError: (controller, request, error) {
              if (mounted) setState(() => _webViewFailed = true);
            },
            onReceivedHttpError: (controller, request, response) {
              if ((response.statusCode ?? 0) >= 400 && mounted) {
                setState(() => _webViewFailed = true);
              }
            },
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
            ),
          ),
        );
    }
  }

  Widget _buildFallback(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openExternally,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Externally'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late final ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = ChewieController(
      videoPlayerController: widget.controller,
      autoPlay: false,
      looping: false,
      aspectRatio: widget.controller.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primaryColor,
        handleColor: AppColors.primaryColor,
        bufferedColor: Colors.white38,
        backgroundColor: Colors.white24,
      ),
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: widget.controller.value.aspectRatio,
        child: Chewie(controller: _chewieController),
      ),
    );
  }
}