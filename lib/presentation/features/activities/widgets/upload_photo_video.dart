import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../view/activity_item.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import '../view/view_activity_screens/show_full_screen_media.dart';

enum MediaType { photos, video }

class MediaUploader extends StatefulWidget {
  const MediaUploader({
    super.key,
    this.initialPhotos,
    this.initialPhotoUrls = const [],
    this.initialVideo,
    this.initialVideoUrl,
    this.onMediaChanged,
    this.allowPhoto = true,
    this.allowVideo = true,
    this.allowPhotoAndVideoTogether = false,
    this.isRequired = false,
    this.limit = 10,
    this.label = 'Upload Photos & Video',
    this.isPictureBox = true,
    this.photoSizeLimit,
    this.readOnly = false,
    this.autoReplaceFirstPhotoWhenMaxReached = false,
  });

  final List<File>? initialPhotos;
  final List<String> initialPhotoUrls;
  final File? initialVideo;
  final String? initialVideoUrl;

  final Function(
    List<File> newPhotos,
    File? newVideo,
    List<String> remainingExistingPhotoUrls,
    String? remainingExistingVideoUrl,
  )?
  onMediaChanged;

  final bool allowPhoto;
  final bool allowVideo;

  /// When [allowPhoto] and [allowVideo] are both true, keeps photos and video
  /// at the same time instead of replacing one with the other (e.g. Incident).
  final bool allowPhotoAndVideoTogether;
  final bool isRequired;
  final int limit;
  final String label;
  final bool isPictureBox;
  final int? photoSizeLimit;
  final bool readOnly;
  final bool autoReplaceFirstPhotoWhenMaxReached;

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  bool get _keepPhotoAndVideoTogether =>
      widget.allowPhoto &&
      widget.allowVideo &&
      widget.allowPhotoAndVideoTogether;

  List<File> _newPhotos = [];
  File? _newVideoFile;
  File? _videoThumbnailFile;

  List<String> _existingPhotoUrls = [];
  String? _existingVideoUrl;

  MediaType? _currentType;
  final ImagePicker _picker = ImagePicker();

  late int maxPhotos;
  late int photoMaxSizeMB;
  static const int videoMaxSizeMB = 200;
  static const int videoMaxDurationSec = 60;

  static const List<String> _photoExt = FilePickerUtils.allowedImageExtensions;
  static const List<String> _videoExt = FilePickerUtils.allowedVideoExtensions;

  bool get _hasMedia =>
      _newPhotos.isNotEmpty ||
      _newVideoFile != null ||
      _existingPhotoUrls.isNotEmpty ||
      _existingVideoUrl != null;

  VideoPlayerController? _remoteVideoController;
  bool _remoteThumbnailReady = false;
  bool _remoteThumbnailError = false;

  @override
  void initState() {
    super.initState();
    AppLogger.d('[MediaUploader] initState — hashCode=$hashCode');
    maxPhotos = widget.limit;
    photoMaxSizeMB = widget.photoSizeLimit ?? 10;

    _existingPhotoUrls = List.from(widget.initialPhotoUrls);
    _existingVideoUrl = widget.initialVideoUrl;

    if (widget.initialVideo != null) {
      _newVideoFile = widget.initialVideo;
      _generateVideoThumbnail();
    }
    if (widget.initialPhotos != null) {
      _newPhotos = widget.initialPhotos!;
    }

    if (_existingVideoUrl != null || _newVideoFile != null) {
      _currentType = MediaType.video;
    } else if (_existingPhotoUrls.isNotEmpty || _newPhotos.isNotEmpty) {
      _currentType = MediaType.photos;
    }
    if (widget.initialVideoUrl != null &&
        widget.initialVideo == null &&
        _newVideoFile == null) {
      _initializeRemoteVideoThumbnail(widget.initialVideoUrl!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void dispose() {
    AppLogger.d(
      '[MediaUploader] dispose — hashCode=$hashCode '
      '(if this fires while the file picker is open, the host activity is '
      'being recreated)',
    );
    _remoteVideoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeRemoteVideoThumbnail(String videoUrl) async {
    try {
      _remoteVideoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );
      await _remoteVideoController!.initialize();
      _remoteVideoController!.setVolume(0);
      _remoteVideoController!.seekTo(Duration.zero);

      if (mounted) {
        setState(() {
          _remoteThumbnailReady = true;
          _remoteThumbnailError = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to load remote video thumbnail', e);
      _remoteVideoController?.dispose();
      _remoteVideoController = null;
      if (mounted) {
        setState(() {
          _remoteThumbnailError = true;
        });
      }
    }
  }

  Future<void> _generateVideoThumbnail() async {
    if (_newVideoFile == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _newVideoFile!.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 90,
      );

      if (thumbnailPath != null && mounted) {
        setState(() {
          _videoThumbnailFile = File(thumbnailPath);
        });
      }
    } catch (e) {
      AppLogger.e('Thumbnail generation failed', e);
    }
  }

  void _notifyParent() {
    widget.onMediaChanged?.call(
      _newPhotos,
      _newVideoFile,
      _existingPhotoUrls,
      _existingVideoUrl,
    );
  }

  void _showWarning(String message) {
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isWarning: true,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _pickPhotos(ImageSource source) async {
    AppLogger.d(
      '[MediaUploader] _pickPhotos: start source=$source '
      'hashCode=$hashCode mounted=$mounted',
    );
    if (widget.readOnly) return;
    if (_currentType == MediaType.video && !_keepPhotoAndVideoTogether) {
      final replace = await _showReplaceConfirmation('photos');
      if (!replace) return;
      _clearVideo();
    }

    final totalCurrentPhotos = _newPhotos.length + _existingPhotoUrls.length;
    final remaining = maxPhotos - totalCurrentPhotos;

    List<File> candidates = [];
    if (source == ImageSource.camera) {
      final XFile? camera = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      AppLogger.d(
        '[MediaUploader] _pickPhotos: camera returned '
        '${camera == null ? 'null' : 'image'} mounted=$mounted',
      );
      if (camera == null) return;
      if (!mounted) return;
      candidates = [File(camera.path)];
    } else {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;
      candidates = result.files
          .map((f) => f.path)
          .whereType<String>()
          .where((p) => p.trim().isNotEmpty)
          .map((p) => File(p))
          .toList();
    }

    if (candidates.isEmpty) return;

    if (remaining <= 0 && widget.autoReplaceFirstPhotoWhenMaxReached) {
      final replacement = candidates.first;
      setState(() {
        // Replace the first photo in the current list (keep others).
        // Prefer replacing a newly selected photo; otherwise replace the first existing URL.
        if (_newPhotos.isNotEmpty) {
          _newPhotos[0] = replacement;
        } else if (_existingPhotoUrls.isNotEmpty) {
          _existingPhotoUrls.removeAt(0);
          _newPhotos.insert(0, replacement);
        } else {
          _newPhotos.add(replacement);
        }
        _currentType = MediaType.photos;
      });
      _notifyParent();
      return;
    }

    if (remaining <= 0) {
      _showWarning('Maximum $maxPhotos photos allowed.');
      return;
    }

    if (source == ImageSource.gallery && candidates.length > remaining) {
      _showWarning('You can only select up to $maxPhotos photos.');
      return;
    }

    List<File> valid = [];
    for (final f in candidates.take(remaining)) {
      final ext = f.path.split('.').last.toLowerCase();
      if (!_photoExt.contains(ext)) {
        _showWarning('Unsupported image format.');
        continue;
      }

      final file = f;
      final sizeMB = (await file.length()) / (1024 * 1024);
      if (sizeMB > photoMaxSizeMB) {
        _showWarning(
          'Photo too large (${sizeMB.toStringAsFixed(1)} MB). Max: $photoMaxSizeMB MB',
        );
        continue;
      }
      valid.add(file);
    }

    if (!mounted) return;
    if (valid.isNotEmpty) {
      setState(() {
        _newPhotos.addAll(valid);
        _currentType = MediaType.photos;
      });
      _notifyParent();
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (widget.readOnly) return;
    if (!widget.allowVideo) return;

    if (_hasMedia &&
        _currentType == MediaType.photos &&
        !_keepPhotoAndVideoTogether) {
      final replace = await _showReplaceConfirmation('video');
      if (!replace) return;
      if (!mounted) return;
    }

    File? file;
    // Both pickers can throw a PlatformException (permission denied, an OEM
    // gallery handing back a broken result, the camera being unavailable).
    // Letting that escape kills the flow with no feedback at all, which reads
    // as a freeze/crash to the user - surface it as a warning instead.
    try {
      if (source == ImageSource.camera) {
        final XFile? picked = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: videoMaxDurationSec),
        );
        if (!mounted || picked == null) return;
        file = File(picked.path);
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );
        if (!mounted) return;
        if (result == null || result.files.isEmpty) return;
        final path = result.files.single.path;
        if (path == null || path.trim().isEmpty) return;
        file = File(path);
      }
    } catch (e) {
      AppLogger.e('[MediaUploader] _pickVideo: picker failed', e);
      _showWarning(
        source == ImageSource.camera
            ? 'Could not open the camera. Please try again.'
            : 'Could not open that video. Please try again.',
      );
      return;
    }

    // On iOS the picked video is a *copy* in the app's temp directory; if the
    // system reclaimed it (or the copy-out failed) every later step - length(),
    // AVPlayer init, thumbnailing - would fail on a missing path.
    if (!await file.exists()) {
      if (!mounted) return;
      _showWarning('Could not read the selected video. Please try again.');
      return;
    }
    if (!mounted) return;

    final ext = file.path.split('.').last.toLowerCase();
    if (!_videoExt.contains(ext)) {
      _showWarning('Unsupported video format.');
      return;
    }

    final sizeMB = (await file.length()) / (1024 * 1024);
    if (sizeMB > videoMaxSizeMB) {
      _showWarning('Video too large (${sizeMB.toStringAsFixed(1)} MB).');
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        _showWarning(
          'This video format is not supported on this device. Please use standard MP4 (H.264).',
        );
      }
      return;
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    final durationSec = controller.value.duration.inSeconds;
    await controller.dispose();

    if (durationSec > videoMaxDurationSec) {
      _showWarning('Video must be ≤60 seconds.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _newVideoFile = file;
      _videoThumbnailFile = null;
      if (!_keepPhotoAndVideoTogether) {
        _newPhotos.clear();
      }
      final hasPhotos = _newPhotos.isNotEmpty || _existingPhotoUrls.isNotEmpty;
      _currentType = _keepPhotoAndVideoTogether && hasPhotos
          ? MediaType.photos
          : MediaType.video;
    });
    await _generateVideoThumbnail();
    _notifyParent();
  }

  void _clearVideo() {
    setState(() {
      _newVideoFile = null;
      _videoThumbnailFile = null;
      _existingVideoUrl = null;
    });
  }

  Future<bool> _showReplaceConfirmation(String newType) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Replace media?'),
            content: Text('Adding a $newType will remove the current media.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Replace',
                  style: AppTextStyles.activityDestructiveActionText,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _removeExistingPhoto(String url) {
    setState(() => _existingPhotoUrls.remove(url));
    if (!_hasMedia) _currentType = null;
    _notifyParent();
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotos.removeAt(index));
    if (!_hasMedia) _currentType = null;
    _notifyParent();
  }

  void _removeVideo() {
    setState(() {
      _newVideoFile = null;
      _videoThumbnailFile = null;
      _existingVideoUrl = null;
      if (!_hasMedia) _currentType = null;
    });
    _notifyParent();
  }

  void _openVideoFullscreen() {
    final url = _existingVideoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      context.push<void>(
        ShowFullScreenMedia.routeName,
        extra: ShowFullScreenMediaArgs(
          activity: ActivityItem(
            time: '',
            date: '',
            name: '',
            studentList: const [],
            createdBy: '',
            videoUrl: url,
          ),
        ),
      );
      return;
    }
    final file = _newVideoFile;
    if (file != null) {
      context.push<void>(
        FullscreenLocalVideoPlayerPage.routeName,
        extra: FullscreenLocalVideoArgs(videoFile: file),
      );
    }
  }

  void _showPickerDialog() {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Media Source',
                textAlign: TextAlign.center,
                style: AppTextStyles.activityPickerDialogTitle,
              ),
              const SizedBox(height: 20),
              if (widget.allowPhoto) ...[
                _option(
                  dialogContext,
                  Icons.photo_camera,
                  'Take Photo',
                  () => _pickPhotos(ImageSource.camera),
                ),
                _option(
                  dialogContext,
                  Icons.image,
                  'Photo Gallery',
                  () => _pickPhotos(ImageSource.gallery),
                ),
              ],
              if (widget.allowVideo) ...[
                _option(
                  dialogContext,
                  Icons.videocam,
                  'Record Video',
                  () => _pickVideo(ImageSource.camera),
                ),
                _option(
                  dialogContext,
                  Icons.video_library,
                  'Video Gallery',
                  () => _pickVideo(ImageSource.gallery),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext dialogContext,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Dismiss using the dialog's own route context, NOT the State's
            // `context` getter. If the host activity was recreated mid-flow (see
            // the FFmpegKit memory-reclaim note in _pickPhotos), this State is
            // unmounted/defunct and reading `State.context` throws
            // "This widget has been unmounted". The dialog route context stays
            // valid for as long as the dialog is on screen.
            Navigator.pop(dialogContext);
            if (!mounted) return;
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Gradient-colored icon.
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppColors.buildPrimaryGradient().createShader(bounds),
                    child: Icon(icon, size: 26, color: AppColors.cardColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.activityPickerOptionLabel,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryColor.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final bool hasLocalVideo = _newVideoFile != null;
    final bool hasLocalThumbnail = _videoThumbnailFile != null;
    final bool hasRemoteVideoOnly = _existingVideoUrl != null && !hasLocalVideo;
    final bool showRemoteThumbnail =
        hasRemoteVideoOnly && _remoteThumbnailReady && !_remoteThumbnailError;

    return _previewItem(
      onTap: _openVideoFullscreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasLocalVideo && hasLocalThumbnail)
            Image.file(_videoThumbnailFile!, fit: BoxFit.cover)
          else if (showRemoteThumbnail)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _remoteVideoController!.value.size.width,
                height: _remoteVideoController!.value.size.height,
                child: VideoPlayer(_remoteVideoController!),
              ),
            )
          else if (hasRemoteVideoOnly &&
              !_remoteThumbnailReady &&
              !_remoteThumbnailError)
            Container(
              color: AppColors.activityVideoPlaceholderBg,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.cardColor),
              ),
            )
          else
            Container(
              color: AppColors.activityVideoPlaceholderBg,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: AppColors.activityMediaPlaceholderIconColor,
                ),
              ),
            ),

          Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 60,
              color: AppColors.cardColor.withValues(alpha: 0.9),
              shadows: const [
                Shadow(
                  blurRadius: 10,
                  color: AppColors.activityIconBackdropColor,
                ),
              ],
            ),
          ),
        ],
      ),
      onRemove: _removeVideo,
      canRemove: !widget.readOnly,
    );
  }

  Widget _buildPhotoPreviewNetwork(String url) {
    return _previewItem(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(),
        errorBuilder: (_, __, ___) =>
            Container(color: AppColors.activityMediaLoadingPlaceholderBg),
      ),
      onRemove: () => _removeExistingPhoto(url),
      // Open the shared full-screen viewer so a saved (network) photo gets the
      // SAME experience as the feed list: full-screen zoom viewport + a
      // download button. (Local, not-yet-uploaded files keep the lightweight
      // dialog since there is nothing to download.)
      onTap: () => context.push(
        ShowFullScreenMedia.routeName,
        extra: ShowFullScreenMediaArgs(photoUrl: url),
      ),
      canRemove: !widget.readOnly,
    );
  }

  Widget _buildPhotoPreviewFile(File file, int index) {
    return _previewItem(
      child: Image.file(file, fit: BoxFit.cover),
      onRemove: () => _removeNewPhoto(index),
      onTap: () => _showImageFullscreen(
        Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image,
              color: AppColors.activityMediaPlaceholderIconColor,
              size: 60,
            ),
          ),
        ),
      ),
      canRemove: !widget.readOnly,
    );
  }

  void _showImageFullscreen(Widget imageWidget) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.blackColor,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(child: imageWidget),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: AppColors.cardColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewItem({
    required Widget child,
    required VoidCallback onRemove,
    VoidCallback? onTap,
    bool canRemove = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 120,
                height: 120,
                color: AppColors.activityMediaLoadingPlaceholderBg,
                child: child,
              ),
            ),
          ),
          if (canRemove)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.activityIconBackdropColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.cardColor,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllPreviews() {
    final showVideoPreview = _keepPhotoAndVideoTogether
        ? (_newVideoFile != null || _existingVideoUrl != null)
        : _currentType == MediaType.video;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showVideoPreview) _buildVideoPreview(),
          ..._existingPhotoUrls.map((url) => _buildPhotoPreviewNetwork(url)),
          ..._newPhotos.asMap().entries.map(
            (e) => _buildPhotoPreviewFile(e.value, e.key),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final showUploadControl = !(widget.readOnly && _hasMedia);
    final canOpenPicker = !widget.readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isPictureBox && showUploadControl)
          GestureDetector(
            onTap: canOpenPicker ? _showPickerDialog : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.activityBorderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Image.asset(MediaRes.uploadPhotoVideoImage),
                  const SizedBox(height: 16),
                  Text(
                    widget.allowVideo
                        ? 'Take/Upload Photo or Video'
                        : 'Take/Upload Photo',
                    style: AppTextStyles.activityUploadBoxHint,
                  ),
                ],
              ),
            ),
          )
        else if (showUploadControl)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: widget.label,
                  style: AppTextStyles.activityMediaLabelText(
                    fontSize: responsive.labelFontSize,
                  ),
                  children: widget.isRequired
                      ? [
                          const TextSpan(
                            text: ' *',
                            style: AppTextStyles.activityRequiredMarker,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: canOpenPicker ? _showPickerDialog : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.inputBorderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Media',
                        style: AppTextStyles.activityResponsiveBodyText(
                          fontSize: responsive.labelFontSize,
                        ),
                      ),
                      const Icon(
                        Icons.file_upload_outlined,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        if (widget.isRequired && !_hasMedia && !widget.readOnly)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please upload at least one media *',
              style: AppTextStyles.activityValidationErrorText,
            ),
          ),

        const SizedBox(height: 16),

        if (_hasMedia) _buildAllPreviews(),

        const SizedBox(height: 12),
      ],
    );
  }
}

/// Full-screen playback for a locally picked video file (preview tap).
class FullscreenLocalVideoPlayerPage extends StatefulWidget {
  static const String routeName = '/activity-fullscreen-local-video';

  const FullscreenLocalVideoPlayerPage({super.key, required this.videoFile});

  final File videoFile;

  @override
  State<FullscreenLocalVideoPlayerPage> createState() =>
      _FullscreenLocalVideoPlayerPageState();
}

class _FullscreenLocalVideoPlayerPageState
    extends State<FullscreenLocalVideoPlayerPage> {
  VideoPlayerController? _controller;

  // Only offered for landscape-shot clips: a portrait video already fills a
  // portrait screen, so rotating it would just turn it on its side.
  bool _isRotated = false;

  void _onCtrlUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.videoFile);
    _controller = c;
    c.initialize().then(
      (_) {
        if (!mounted) return;
        c.addListener(_onCtrlUpdate);
        setState(() {});
      },
      onError: (_, __) {
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Could not open this video.',
          isWarning: true,
        );
        Navigator.of(context).maybePop();
      },
    );
  }

  void _toggleRotated() {
    final rotated = !_isRotated;
    setState(() => _isRotated = rotated);
    if (rotated) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _restoreOrientationAndChrome();
    }
  }

  // Matches the app-wide default from setPreferredOrientations() in
  // device_configuration.dart — leaving a landscape-only lock behind after
  // this page pops would break rotation for the rest of the app.
  void _restoreOrientationAndChrome() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onCtrlUpdate);
    _controller?.dispose();
    if (_isRotated) _restoreOrientationAndChrome();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final isLandscapeVideo = ready && c.value.aspectRatio >= 1.0;

    return PopScope(
      canPop: !_isRotated,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRotated) _toggleRotated();
      },
      child: Scaffold(
        backgroundColor: AppColors.blackColor,
        extendBodyBehindAppBar: true,
        appBar: _isRotated
            ? null
            : AppBar(
                backgroundColor: AppColors.transparentColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.cardColor,
                    size: 28,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
        body: Stack(
          children: [
            Center(
              child: !ready
                  ? const CircularProgressIndicator(color: AppColors.cardColor)
                  : GestureDetector(
                      onTap: () {
                        if (c.value.isPlaying) {
                          c.pause();
                        } else {
                          c.play();
                        }
                      },
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(c),
                            AnimatedOpacity(
                              opacity: c.value.isPlaying ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.play_circle_fill,
                                color:
                                    AppColors.activityMediaPlaceholderIconColor,
                                size: 72,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (isLandscapeVideo)
              Positioned(
                top: 14,
                right: 14,
                child: SafeArea(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.activityIconBackdropColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: _isRotated
                          ? 'Exit fullscreen'
                          : 'Rotate to fullscreen',
                      icon: Icon(
                        _isRotated
                            ? Icons.close_fullscreen_rounded
                            : Icons.screen_rotation_alt_rounded,
                        color: AppColors.cardColor,
                        size: 20,
                      ),
                      onPressed: _toggleRotated,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
