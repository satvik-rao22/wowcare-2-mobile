import 'dart:io';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/observability/media_upload_trace.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/activities/model/activity_item.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/entities/staged_media.dart';
import 'package:wowcare/domain/features/activity/entities/video_validation_result.dart';
import 'package:wowcare/presentation/features/activities/activity_media_strings.dart';
import 'package:wowcare/presentation/features/activities/utils/media_picker_error.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/activities/model/activity_route_args.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/show_full_screen_media.dart';

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

class _MediaUploaderState extends State<MediaUploader>
    with WidgetsBindingObserver {
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

  late int maxPhotos;
  late int photoMaxSizeMB;
  /// Caps the camera's own recording length. Sourced from
  /// [VideoUploadLimits] so the recorder and the validator cannot drift apart —
  /// the size cap now lives there too and is enforced by the validator, not
  /// here.
  static const int videoMaxDurationSec = VideoUploadLimits.maxDurationSeconds;

  static const List<String> _photoExt = FilePickerUtils.allowedImageExtensions;

  bool get _hasMedia =>
      _newPhotos.isNotEmpty ||
      _newVideoFile != null ||
      _existingPhotoUrls.isNotEmpty ||
      _existingVideoUrl != null;

  VideoPlayerController? _remoteVideoController;
  bool _remoteThumbnailReady = false;
  bool _remoteThumbnailError = false;

  /// True while a claim of the platform's lost-capture cache is in flight.
  /// The claim is destructive, so overlapping runs must not both call it —
  /// see the guards in [_recoverLostMedia].
  bool _lostMediaClaimInFlight = false;

  /// True from the moment a picker is launched until it returns. A recovery
  /// must not land underneath a pick the user is actively making, and — more
  /// importantly — the capture that is *currently* being taken is the one the
  /// platform may be about to cache, so claiming during it would race the very
  /// capture we are trying to protect.
  bool _pickerInFlight = false;

  @override
  void initState() {
    super.initState();
    // Observed so a capture lost to activity death is claimed on the way back
    // into the app, not only on a fresh mount. Android can recreate the host
    // activity while keeping the Flutter widget tree alive, in which case
    // initState never re-runs but a cached capture is still waiting.
    WidgetsBinding.instance.addObserver(this);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
      // After the first frame so the cubit is readable and _showWarning has a
      // Scaffold to attach to. Unawaited because recovery must never delay the
      // frame; it swallows its own errors so nothing escapes into
      // PlatformDispatcher.onError from here.
      _recoverLostMedia();
    });
  }

  /// Re-syncs existing-media props that changed after the first mount.
  ///
  /// Deep-link routes that "load by code" (e.g. the incident-approval
  /// notification route) mount the host screen with a near-empty
  /// placeholder `ActivityItem` before their own self-load (`GET
  /// /api/v2/activities/{code}`) resolves, then rebuild with the real
  /// data once it does — but [initState] only runs once, against that
  /// placeholder's empty `initialPhotoUrls`/`initialVideoUrl`. Without
  /// this, the photo the self-load fetches is silently dropped: visible
  /// on web (no such placeholder-then-refill gap there), invisible on
  /// mobile. This is exactly that gap.
  ///
  /// Only syncs while nothing local has happened yet — the moment the
  /// user picks/removes something, a later prop change (e.g. an
  /// unrelated parent rebuild) must not clobber their in-progress edit.
  @override
  void didUpdateWidget(covariant MediaUploader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final untouched =
        _newPhotos.isEmpty &&
        _newVideoFile == null &&
        listEquals(_existingPhotoUrls, oldWidget.initialPhotoUrls) &&
        _existingVideoUrl == oldWidget.initialVideoUrl;
    if (!untouched) return;

    final photosChanged = !listEquals(
      widget.initialPhotoUrls,
      oldWidget.initialPhotoUrls,
    );
    final videoUrlChanged = widget.initialVideoUrl != oldWidget.initialVideoUrl;
    if (!photosChanged && !videoUrlChanged) return;

    setState(() {
      _existingPhotoUrls = List.from(widget.initialPhotoUrls);
      _existingVideoUrl = widget.initialVideoUrl;
      if (_existingVideoUrl != null) {
        _currentType = MediaType.video;
      } else if (_existingPhotoUrls.isNotEmpty) {
        _currentType = MediaType.photos;
      }
    });
    if (videoUrlChanged &&
        widget.initialVideoUrl != null &&
        widget.initialVideo == null &&
        _newVideoFile == null) {
      _initializeRemoteVideoThumbnail(widget.initialVideoUrl!);
    }
    _notifyParent();
  }

  /// Restores a camera capture that Android completed but could not deliver.
  ///
  /// When the OS destroys the host activity while the camera app is in the
  /// foreground — routine on memory-constrained devices during a 60-second
  /// recording — the capture still lands on disk but `pickVideo`/`pickImage`
  /// never returns, so the file was silently abandoned and the user saw the app
  /// restart with nothing to show for it. The platform caches that result;
  /// this claims it on the next build of this widget.
  ///
  /// No-op whenever there is nothing pending, which is every normal run and
  /// every run on iOS — so the untouched path is bit-for-bit what it was.
  Future<void> _recoverLostMedia() async {
    if (!mounted || widget.readOnly) return;

    // GUARD 1 — re-entrancy. The claim is destructive (the platform hands each
    // cached capture back exactly once), so two overlapping runs would have one
    // of them silently swallow the result. Both entry points (initState and
    // app-resume) funnel through here, and resume can fire while the initState
    // run is still awaiting.
    if (_lostMediaClaimInFlight) return;

    // GUARD 2 — do not race a live pick. If the user is already in the picker,
    // a restore landing underneath them would either be clobbered moments later
    // or would clobber what they are about to choose. The pending capture stays
    // cached; the next resume claims it.
    if (_pickerInFlight) return;

    final ActivityEditorCubit editor;
    try {
      editor = context.read<ActivityEditorCubit>();
    } catch (_) {
      // MediaUploader is only ever hosted inside the activity form screens,
      // which all provide this cubit. Guarded anyway because recovery is an
      // additive nicety: a future host without the provider must still get the
      // exact screen it gets today, not a crash.
      return;
    }

    _lostMediaClaimInFlight = true;
    // Nothing below may escape. This runs unawaited from a post-frame callback
    // and from a lifecycle callback, so an escaping error would reach
    // PlatformDispatcher.onError and be logged as a FATAL crash — turning a
    // failed best-effort restore into a worse signal than the dropped capture
    // it was fixing. The file I/O in the restore helpers is the realistic
    // source (the recovered path can have been reclaimed since it was cached).
    try {
      MediaUploadTrace.stage(MediaUploadStage.lostMediaCheckStarted);
      final recovered = await editor.retrieveLostMedia();
      if (!mounted) return;

      // OUTCOME 1 — nothing pending. The normal result on every run, and the
      // only result off Android.
      if (recovered.isNothingToRecover) {
        MediaUploadTrace.stage(MediaUploadStage.lostMediaNoneFound);
        return;
      }

      MediaUploadTrace.platform();
      MediaUploadTrace.source(MediaCaptureSource.camera);

      // OUTCOME 2 — the platform cached a failure, not a file: the camera app
      // itself died. Nothing to restore, but it is claimed and gone, and it is
      // worth knowing this happens.
      if (recovered.hasFailedCapture) {
        MediaUploadTrace.stage(MediaUploadStage.lostMediaFailedCapture);
        return;
      }

      // OUTCOME 3 — a real file came back.
      MediaUploadTrace.stage(MediaUploadStage.lostMediaClaimed);
      if (recovered.type == RecoveredMediaType.video) {
        await _restoreLostVideo(recovered.filePaths.first);
      } else {
        await _restoreLostPhotos(recovered.filePaths);
      }
    } catch (error, stackTrace) {
      // Redacted: the recovered path is exactly what a FileSystemException
      // here would carry.
      MediaUploadTrace.failure(
        MediaUploadStage.lostMediaClaimed,
        error,
        stackTrace,
      );
    } finally {
      _lostMediaClaimInFlight = false;
    }
  }

  Future<void> _restoreLostVideo(String path) async {
    // Each bail-out below is breadcrumbed: the claim already consumed the
    // platform's cached copy, so a capture dropped here is gone for good and
    // that is worth seeing in a report — it is not the same as never having
    // had one.
    //
    // The uploader may not accept video at all (every screen but the Video
    // activity passes allowVideo: false). Dropping it here matches what would
    // have happened had the pick completed normally: no video option, no video.
    if (!widget.allowVideo) {
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'video_not_allowed',
      );
      return;
    }
    // Replacing media the user has since chosen would be a surprise — the
    // recovery is older than anything on screen now.
    if (_newVideoFile != null) {
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'slot_already_filled',
      );
      return;
    }

    var file = File(path);
    if (!await file.exists()) {
      // The cached path outlived the file — Android reclaimed the cache dir
      // between the capture and the claim.
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'file_gone',
      );
      return;
    }
    if (!mounted) return;
    // Re-checked after the await: a pick could have started while we were on
    // the filesystem.
    if (_pickerInFlight) {
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'picker_started',
      );
      return;
    }
    // Staged before validation, exactly as a fresh capture is: a recovered
    // file sits in the SAME cache the platform wrote it to, so it is just as
    // evictable mid-upload.
    final staged = await _stageForUpload(file);
    if (staged == null) {
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'staging_failed',
      );
      return;
    }
    file = staged;

    // The SAME validation a fresh capture goes through — format, size,
    // decodability, duration — not a parallel, laxer path.
    if (!await _isVideoAcceptable(file)) {
      await _discardStaged(file);
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.lostMediaDiscarded,
        'validation_rejected',
      );
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
    MediaUploadTrace.stage(MediaUploadStage.lostMediaRestored);
    await _generateVideoThumbnail();
    _notifyParent();
  }

  Future<void> _restoreLostPhotos(List<String> paths) async {
    if (!widget.allowPhoto) return;

    final remaining =
        maxPhotos - (_newPhotos.length + _existingPhotoUrls.length);
    // Deliberately NOT applying autoReplaceFirstPhotoWhenMaxReached: that
    // swap is the answer to a deliberate "pick one more" gesture, and silently
    // overwriting a photo the user can see during a restore is not the same
    // thing. A full box simply keeps what it has.
    if (remaining <= 0) return;

    final valid = <File>[];
    for (final path in paths.take(remaining)) {
      final file = File(path);
      if (!await file.exists()) continue;
      final ext = FileUtils.extension(file.path);
      if (!_photoExt.contains(ext)) continue;
      final sizeMB = (await file.length()) / (1024 * 1024);
      if (sizeMB > photoMaxSizeMB) continue;
      valid.add(file);
    }

    if (!mounted || valid.isEmpty) return;
    setState(() {
      _newPhotos.addAll(valid);
      _currentType = MediaType.photos;
    });
    _notifyParent();
  }

  /// Claims a capture lost while the app was away.
  ///
  /// Android caches a completed-but-undeliverable capture and hands it back on
  /// the next claim, so the moment we come back to the foreground is exactly
  /// when one may be waiting. [_recoverLostMedia] holds the re-entrancy and
  /// racing guards, so a resume arriving mid-claim or mid-pick is a no-op
  /// rather than a double-claim.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    _recoverLostMedia();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    MediaUploadTrace.stage(MediaUploadStage.thumbnailStarted);
    try {
      final tempDir = await FileUtils.tempDirectory();
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
      MediaUploadTrace.stage(MediaUploadStage.thumbnailDone);
    } catch (e, stackTrace) {
      // Native decode of a large/odd video is a plausible OOM site on Android,
      // and until now it left no release trace at all.
      MediaUploadTrace.stage(MediaUploadStage.thumbnailFailed);
      // Replaces AppLogger.e here: that also reached Crashlytics in release,
      // but with the raw exception, whose message carries the video's absolute
      // path. MediaUploadTrace.failure redacts it and still prints in debug.
      MediaUploadTrace.failure(MediaUploadStage.thumbnailFailed, e, stackTrace);
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

  Future<void> _pickPhotos(PickSource source) async {
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
    // Same reasoning as _pickVideo: a lost-capture claim must not run while the
    // capture that could BECOME the lost one is being taken. The photo path can
    // lose its result to activity death exactly as the video path can.
    _pickerInFlight = true;
    try {
      final picked = await FilePickerUtils.pick(
        type: PickType.image,
        source: source,
        multiple: true,
        imageQuality: 85,
        onError: (e, stackTrace) => _reportPickerFailure(
          e,
          stackTrace,
          isCamera: source == PickSource.camera,
          isVideo: false,
        ),
      );
      AppLogger.d(
        '[MediaUploader] _pickPhotos: $source returned '
        '${picked.length} file(s) mounted=$mounted',
      );
      if (!mounted) return;
      candidates = [for (final f in picked) f.file];
    } catch (e, stackTrace) {
      // This `try` previously had a `finally` and NO `catch`, so a
      // PlatformException from either picker went straight through it and out
      // of this unawaited callback — landing in PlatformDispatcher.onError and
      // being recorded as a FATAL crash.
      _reportPickerFailure(
        e,
        stackTrace,
        isCamera: source == PickSource.camera,
        isVideo: false,
      );
      return;
    } finally {
      _pickerInFlight = false;
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
      _showWarning(ActivityMediaStrings.maxPhotosAllowed(maxPhotos));
      return;
    }

    if (source == PickSource.photos && candidates.length > remaining) {
      _showWarning(ActivityMediaStrings.maxPhotosSelectable(maxPhotos));
      return;
    }

    List<File> valid = [];
    for (final f in candidates.take(remaining)) {
      final ext = FileUtils.extension(f.path);
      if (!_photoExt.contains(ext)) {
        _showWarning(ActivityMediaStrings.unsupportedImageFormat);
        continue;
      }

      final file = f;
      final double sizeMB;
      try {
        sizeMB = (await file.length()) / (1024 * 1024);
      } catch (e, stackTrace) {
        // One unreadable candidate must not take down a multi-photo pick, and
        // must not escape this unawaited callback as a fatal.
        MediaUploadTrace.failure(
          MediaUploadStage.validationRejected,
          e,
          stackTrace,
        );
        _showWarning(ActivityMediaStrings.captureUnreadable);
        continue;
      }
      if (sizeMB > photoMaxSizeMB) {
        _showWarning(
          ActivityMediaStrings.photoTooLarge(
            sizeMB.toStringAsFixed(1),
            photoMaxSizeMB,
          ),
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

  Future<void> _pickVideo(PickSource source) async {
    if (widget.readOnly) return;
    if (!widget.allowVideo) return;

    if (_hasMedia &&
        _currentType == MediaType.photos &&
        !_keepPhotoAndVideoTogether) {
      final replace = await _showReplaceConfirmation('video');
      if (!replace) return;
      if (!mounted) return;
    }

    // Breadcrumbs are written on ENTERING each stage: a process killed
    // mid-capture leaves only what was already recorded, so the last one in the
    // report names the stage that died.
    MediaUploadTrace.platform();
    MediaUploadTrace.source(
      source == PickSource.camera
          ? MediaCaptureSource.camera
          : MediaCaptureSource.gallery,
    );
    MediaUploadTrace.stage(MediaUploadStage.pickerOpened);

    // From here until the picker returns, a lost-capture claim must not run:
    // the capture being taken right now is the one Android may be about to
    // cache, so claiming mid-capture would race it. Cleared in the finally
    // below, on every exit path.
    _pickerInFlight = true;
    File? file;
    // Both pickers can throw a PlatformException (permission denied, an OEM
    // gallery handing back a broken result, the camera being unavailable).
    // Letting that escape kills the flow with no feedback at all, which reads
    // as a freeze/crash to the user - surface it as a warning instead.
    try {
      var failed = false;
      final picked = await FilePickerUtils.pickOne(
        type: PickType.video,
        source: source,
        maxVideoDuration: const Duration(seconds: videoMaxDurationSec),
        onError: (e, stackTrace) {
          failed = true;
          _reportPickerFailure(
            e,
            stackTrace,
            isCamera: source == PickSource.camera,
            isVideo: true,
          );
        },
      );
      if (failed) return;
      if (picked == null) {
        MediaUploadTrace.stage(MediaUploadStage.pickerCancelled);
      }
      if (!mounted || picked == null) return;
      file = picked.file;
      MediaUploadTrace.stage(MediaUploadStage.pickerReturned);
    } catch (e, stackTrace) {
      _reportPickerFailure(
        e,
        stackTrace,
        isCamera: source == PickSource.camera,
        isVideo: true,
      );
      return;
    } finally {
      // Always cleared, on every exit path, so a failure can never leave the
      // picker permanently blocked by the recovery guard.
      _pickerInFlight = false;
    }

    // Everything past the picker is filesystem and decoder work, and every
    // step of it can throw on a file the OS reclaimed underneath us. This
    // method is invoked as an unawaited VoidCallback, so an escape here lands
    // in PlatformDispatcher.onError and is recorded as a FATAL crash for
    // something the user could simply retry.
    try {
      // On iOS the picked video is a *copy* in the app's temp directory; if the
      // system reclaimed it (or the copy-out failed) every later step -
      // length(), AVPlayer init, thumbnailing - would fail on a missing path.
      if (!await file.exists()) {
        MediaUploadTrace.stage(MediaUploadStage.fileMissing);
        if (!mounted) return;
        _showWarning(ActivityMediaStrings.videoUnreadable);
        return;
      }
      MediaUploadTrace.stage(MediaUploadStage.fileOnDisk);
      MediaUploadTrace.fileSizeBytes(await file.length());
      if (!mounted) return;

      // Copy out of cache BEFORE validation, so everything downstream —
      // validation, thumbnail, checksum, the S3 PUT — reads a file Android
      // cannot reclaim mid-upload. Both pickers hand back a cache path.
      final staged = await _stageForUpload(file);
      if (staged == null) return;
      file = staged;

      if (!await _isVideoAcceptable(file)) {
        // Validation rejected it, so it will never be uploaded and the copy has
        // no owner. Drop it now rather than leaving it for the 7-day sweep.
        await _discardStaged(file);
        return;
      }

      if (!mounted) return;
      setState(() {
        _newVideoFile = file;
        _videoThumbnailFile = null;
        if (!_keepPhotoAndVideoTogether) {
          _newPhotos.clear();
        }
        final hasPhotos =
            _newPhotos.isNotEmpty || _existingPhotoUrls.isNotEmpty;
        _currentType = _keepPhotoAndVideoTogether && hasPhotos
            ? MediaType.photos
            : MediaType.video;
      });
      await _generateVideoThumbnail();
      _notifyParent();
    } catch (e, stackTrace) {
      // Handled, so non-fatal — and the form is left exactly as it was, with
      // the picker re-openable.
      MediaUploadTrace.failure(MediaUploadStage.fileMissing, e, stackTrace);
      if (!mounted) return;
      _showWarning(ActivityMediaStrings.videoUnreadable);
    }
  }

  /// Runs every pre-upload rule against [file] and reports the verdict.
  ///
  /// Delegates to [ActivityEditorCubit.validateVideoForUpload] rather than
  /// probing here: the decoder call is a plugin call and does not belong in a
  /// widget (Mandate 5), and routing it through the use case is what lets the
  /// rules be unit-tested without a platform channel.
  ///
  /// Returns true only if every rule passed. On rejection the caller deletes
  /// the staged copy — see [_pickVideo] and [_restoreLostVideo].
  Future<bool> _isVideoAcceptable(File file) async {
    MediaUploadTrace.stage(MediaUploadStage.validationStarted);

    final ActivityEditorCubit editor;
    try {
      editor = context.read<ActivityEditorCubit>();
    } catch (_) {
      // No editor cubit in scope: accept, matching the pre-validation
      // behaviour rather than blocking a capture outright.
      return true;
    }

    MediaUploadTrace.stage(MediaUploadStage.validationProbeStarted);
    final VideoValidationResult result;
    try {
      result = await editor.validateVideoForUpload(file.path);
    } catch (e, stackTrace) {
      // The use case is written not to throw; if it ever does, treat it as a
      // rejection rather than letting it escape this unawaited call path.
      MediaUploadTrace.stageWithDetail(
        MediaUploadStage.validationRejected,
        'validator_threw',
      );
      MediaUploadTrace.failure(
        MediaUploadStage.validationRejected,
        e,
        stackTrace,
      );
      if (mounted) _showWarning(ActivityMediaStrings.couldNotPrepareVideo);
      return false;
    }

    switch (result) {
      case VideoValidationAccepted(
        :final sizeBytes,
        :final durationMs,
        :final mimeType,
      ):
        MediaUploadTrace.fileSizeBytes(sizeBytes);
        MediaUploadTrace.durationMs(durationMs);
        MediaUploadTrace.mimeType(mimeType);
        MediaUploadTrace.stage(MediaUploadStage.validationPassed);
        return true;

      case VideoValidationRejected(
        :final reason,
        :final sizeBytes,
        :final durationMs,
      ):
        if (sizeBytes != null) MediaUploadTrace.fileSizeBytes(sizeBytes);
        if (durationMs != null) MediaUploadTrace.durationMs(durationMs);
        // One breadcrumb detail per rule, so a report names exactly which one
        // tripped rather than a generic "rejected".
        MediaUploadTrace.stageWithDetail(
          MediaUploadStage.validationRejected,
          reason.name,
        );
        if (mounted) _showWarning(_messageForRejection(reason, sizeBytes));
        return false;
    }
  }

  /// The sentence for each rule, so the user is told which one they hit.
  String _messageForRejection(VideoRejectionReason reason, int? sizeBytes) {
    switch (reason) {
      case VideoRejectionReason.fileMissing:
        return ActivityMediaStrings.videoUnreadable;
      case VideoRejectionReason.emptyFile:
        return ActivityMediaStrings.videoEmpty;
      case VideoRejectionReason.tooLarge:
        final mb = ((sizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1);
        return ActivityMediaStrings.videoTooLarge(mb);
      case VideoRejectionReason.unsupportedMimeType:
        return ActivityMediaStrings.unsupportedVideoFormat;
      case VideoRejectionReason.undecodable:
      case VideoRejectionReason.zeroDuration:
        // Both are the truncated-capture case.
        return ActivityMediaStrings.videoCorrupt;
      case VideoRejectionReason.tooLong:
        return ActivityMediaStrings.videoTooLong;
    }
  }

  /// Classifies a picker exception, shows the matching sentence and reports it
  /// at the right severity.
  ///
  /// Nothing here is ever fatal: the exception was caught, the user was told,
  /// and the picker can be reopened — `fatal` is for uncaught crashes only.
  /// Cancellation is not routed here at all (both pickers signal it with a null
  /// result, not a throw), so every call site is a real refusal or failure.
  void _reportPickerFailure(
    Object error,
    StackTrace stackTrace, {
    required bool isCamera,
    required bool isVideo,
  }) {
    final classified = MediaPickerError.from(
      error,
      isCamera: isCamera,
      isVideo: isVideo,
    );
    // The platform code is a fixed plugin vocabulary, never user text, so it is
    // safe in a breadcrumb — and it is the single most useful fact for telling
    // a permission refusal apart from a broken camera in a report.
    MediaUploadTrace.stageWithDetail(
      MediaUploadStage.pickerFailed,
      classified.code,
    );
    if (classified.shouldReport) {
      MediaUploadTrace.failure(MediaUploadStage.pickerFailed, error, stackTrace);
    }
    if (classified.message.isNotEmpty) _showWarning(classified.message);
  }

  /// Copies [file] into persistent storage, returning the copy — or null if
  /// the copy could not be made, having already told the user why.
  ///
  /// The plugin call lives behind [ActivityEditorCubit] (Mandate 5); this only
  /// decides what the user sees.
  Future<File?> _stageForUpload(File file) async {
    final ActivityEditorCubit editor;
    try {
      editor = context.read<ActivityEditorCubit>();
    } catch (_) {
      // No editor cubit in scope — keep the pre-staging behaviour (upload
      // straight from cache) rather than refusing the capture outright.
      return file;
    }
    try {
      final staged = await editor.stageMediaForUpload(file.path);
      return File(staged.path);
    } on MediaStagingException catch (e) {
      if (!mounted) return null;
      // A clean, actionable sentence — never the OS error or the path.
      _showWarning(
        e.failure == MediaStagingFailure.outOfSpace
            ? ActivityMediaStrings.storageFullPreparingVideo
            : ActivityMediaStrings.couldNotPrepareVideo,
      );
      return null;
    } catch (_) {
      // The repository contract narrows every failure to MediaStagingException;
      // this is belt-and-braces so an unexpected throw degrades to a message
      // rather than an unhandled async error reported as a fatal crash.
      if (!mounted) return null;
      _showWarning(ActivityMediaStrings.couldNotPrepareVideo);
      return null;
    }
  }

  /// Deletes a staged copy that will never be uploaded. Best-effort.
  Future<void> _discardStaged(File file) async {
    try {
      if (!mounted) return;
      await context.read<ActivityEditorCubit>().discardStagedMedia(file.path);
    } catch (_) {}
  }

  void _clearVideo() {
    // Explicit user cancellation: the staged copy exists only to survive an
    // upload that is now never going to happen.
    final discarded = _newVideoFile;
    setState(() {
      _newVideoFile = null;
      _videoThumbnailFile = null;
      _existingVideoUrl = null;
    });
    if (discarded != null) _discardStaged(discarded);
  }

  Future<bool> _showReplaceConfirmation(String newType) async {
    try {
      return await _showReplaceConfirmationDialog(newType);
    } catch (_) {
      // A dialog that cannot be shown (host route already popping) must read as
      // "user declined", not crash the picker that asked.
      return false;
    }
  }

  Future<bool> _showReplaceConfirmationDialog(String newType) async {
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
    // Explicit user cancellation — see _clearVideo.
    final discarded = _newVideoFile;
    setState(() {
      _newVideoFile = null;
      _videoThumbnailFile = null;
      _existingVideoUrl = null;
      if (!_hasMedia) _currentType = null;
    });
    if (discarded != null) _discardStaged(discarded);
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
                  () => _pickPhotos(PickSource.camera),
                ),
                _option(
                  dialogContext,
                  Icons.image,
                  'Photo Gallery',
                  () => _pickPhotos(PickSource.photos),
                ),
              ],
              if (widget.allowVideo) ...[
                _option(
                  dialogContext,
                  Icons.videocam,
                  'Record Video',
                  () => _pickVideo(PickSource.camera),
                ),
                _option(
                  dialogContext,
                  Icons.video_library,
                  'Video Gallery',
                  () => _pickVideo(PickSource.photos),
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
                        ? 'Take/Upload Video'
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
