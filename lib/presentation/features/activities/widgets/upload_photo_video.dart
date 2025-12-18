// // widgets/single_media_uploader.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../../../../app/theme/colors.dart';
// import '../../../../app/theme/media_res.dart';
//
// enum MediaType { photo, video }
//
// class UploadPhotoVideo extends StatefulWidget {
//   const UploadPhotoVideo({
//     super.key,
//     this.initialFile,
//     this.onMediaChanged,
//     this.canTakeVideo = false,
//     this.canUploadVideo = false
//   });
//
//   final File? initialFile;
//   final ValueChanged<File?>? onMediaChanged;
//   final bool canTakeVideo;
//   final bool canUploadVideo;
//
//   @override
//   State<UploadPhotoVideo> createState() => _UploadPhotoVideoState();
// }
//
// class _UploadPhotoVideoState extends State<UploadPhotoVideo> {
//   File? _mediaFile;
//   MediaType? _mediaType;
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.initialFile != null) {
//       _mediaFile = widget.initialFile;
//       _mediaType = _mediaFile!.path.toLowerCase().endsWith('.mp4') ||
//           _mediaFile!.path.toLowerCase().endsWith('.mov')
//           ? MediaType.video
//           : MediaType.photo;
//     }
//   }
//
//   Future<void> _pickMedia({
//     required ImageSource source,
//     required MediaType type,
//   }) async {
//     XFile? pickedFile;
//
//     if (type == MediaType.photo) {
//       pickedFile = await _picker.pickImage(
//         source: source,
//         imageQuality: 85,
//       );
//     } else {
//       pickedFile = await _picker.pickVideo(
//         source: source,
//         maxDuration: const Duration(minutes: 2),
//       );
//     }
//
//     if (pickedFile != null && mounted) {
//       setState(() {
//         _mediaFile = File(pickedFile!.path);
//         _mediaType = type;
//       });
//       widget.onMediaChanged?.call(_mediaFile);
//     }
//   }
//
//   void _removeMedia() {
//     setState(() {
//       _mediaFile = null;
//       _mediaType = null;
//     });
//     widget.onMediaChanged?.call(null);
//   }
//
//   void _showMediaPickerDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: const Text(
//             'Select Media Source',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: 'Manrope',
//               fontSize: 24,
//               fontWeight: FontWeight.w600,
//               color: Color(0xff573353),
//             ),
//           ),
//           content: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 // Row(
//                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 //   children: [
//                 //     _buildDialogOption(
//                 //       icon: Icons.photo_camera,
//                 //       label: 'Camera\nPhoto',
//                 //       onTap: () {
//                 //         Navigator.pop(dialogContext);
//                 //         _pickMedia(source: ImageSource.camera, type: MediaType.photo);
//                 //       },
//                 //     ),
//                 //     _buildDialogOption(
//                 //       icon: Icons.videocam,
//                 //       label: 'Camera\nVideo',
//                 //       onTap: () {
//                 //         Navigator.pop(dialogContext);
//                 //         _pickMedia(source: ImageSource.camera, type: MediaType.video);
//                 //       },
//                 //     ),
//                 //   ],
//                 // ),
//                 const SizedBox(height: 10,),
//                 _buildDialogOption(icon: Icons.photo_camera, label: 'Take Photo', onTap: () {
//                   Navigator.pop(dialogContext);
//                   _pickMedia(source: ImageSource.camera, type: MediaType.photo);
//                 },),
//                 const SizedBox(height: 10),
//                 _buildDialogOption(
//                   icon: Icons.image,
//                   label: 'Photo Gallery',
//                   onTap: () {
//                     Navigator.pop(dialogContext);
//                     _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
//                   },
//                 ),
//                 const SizedBox(height: 10,),
//                 _buildDialogOption(
//                   icon: Icons.videocam,
//                   label: 'Record Video',
//                   onTap: () {
//                     Navigator.pop(dialogContext);
//                     _pickMedia(source: ImageSource.camera, type: MediaType.video);
//                   },
//                 ),
//                 const SizedBox(height: 10,),
//                 _buildDialogOption(
//                   icon: Icons.video_library,
//                   label: 'Video Gallery',
//                   onTap: () {
//                     Navigator.pop(dialogContext);
//                     _pickMedia(source: ImageSource.gallery, type: MediaType.video);
//                   },
//                 ),
//
//
//                 // Row(
//                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 //   children: [
//                 //     _buildDialogOption(
//                 //       icon: Icons.image,
//                 //       label: 'Gallery\nPhoto',
//                 //       onTap: () {
//                 //         Navigator.pop(dialogContext);
//                 //         _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
//                 //       },
//                 //     ),
//                 //     _buildDialogOption(
//                 //       icon: Icons.video_library,
//                 //       label: 'Gallery\nVideo',
//                 //       onTap: () {
//                 //         Navigator.pop(dialogContext);
//                 //         _pickMedia(source: ImageSource.gallery, type: MediaType.video);
//                 //       },
//                 //     ),
//                 //   ],
//                 // ),
//                 // const SizedBox(height: 16),
//               ],
//             ),
//           ),
//           // actions: [
//           //   TextButton(
//           //     onPressed: () => Navigator.pop(dialogContext),
//           //     child: const Text(
//           //       'Cancel',
//           //       style: TextStyle(color: Color(0xff573353)),
//           //     ),
//           //   ),
//           // ],
//         );
//       },
//     );
//   }
//
//   Widget _buildDialogOption({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Row(
//         //mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             size: 35,
//             color: const Color(0xff573353),
//           ),
//           const SizedBox(width: 10),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w400,
//               color: Color(0xff573353),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: GestureDetector(
//         onTap: _mediaFile == null ? _showMediaPickerDialog : null,
//         child: Container(
//           width: double.infinity,
//           height: 290,
//           //margin: const EdgeInsets.symmetric(horizontal: 20),
//           decoration: BoxDecoration(
//             color: const Color(0x1AB1AFE9),
//             //color: const Color(0xff573353).withOpacity(0.05),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: _mediaFile == null
//               ? Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//               Image.asset(MediaRes.uploadPhotoVideoImage),
//               const SizedBox(height: 16),
//               const Text(
//                 'Take/Upload',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//                           ],
//                         )
//               : Stack(
//             fit: StackFit.expand,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(18),
//                 child: _mediaType == MediaType.video
//                     ? Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     Image.file(
//                       _mediaFile!,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
//                     ),
//                     const Center(
//                       child: Icon(
//                         Icons.play_circle_fill,
//                         size: 80,
//                         color: Colors.white,
//                         shadows: [Shadow(blurRadius: 10, color: Colors.black)],
//                       ),
//                     ),
//                   ],
//                 )
//                     : Image.file(
//                   _mediaFile!,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: GestureDetector(
//                   onTap: _removeMedia,
//                   child: Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: const BoxDecoration(
//                       color: Colors.black54,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.close,
//                       color: Colors.white,
//                       size: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// the above is for only one file upload
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';

enum MediaType { photos, video }

class MediaUploader extends StatefulWidget {
  const MediaUploader({
    super.key,
    this.initialPhotos,
    this.initialVideo,
    this.onMediaChanged,
    this.allowPhoto = true,
    this.allowVideo = true,
    this.isRequired = false,
    this.limit = 10
  });

  final List<File>? initialPhotos;
  final File? initialVideo;
  final Function(List<File> photos, File? video)? onMediaChanged;
  final bool allowVideo;
  final bool allowPhoto;
  final bool isRequired;
  final int limit;

  @override
  State<MediaUploader> createState() => _MediaUploaderState();
}

class _MediaUploaderState extends State<MediaUploader> {
  List<File> _photos = [];
  File? _videoFile;
  File? _videoThumbnailFile;
  MediaType? _currentType;
  final ImagePicker _picker = ImagePicker();

  // Limits
  late int maxPhotos ;
  static const int photoMaxSizeMB = 10;
  static const int videoMaxSizeMB = 100;
  static const int videoMaxDurationSec = 60;

  static const List<String> _photoExt = ['jpg', 'jpeg', 'png', 'heic', 'heif'];
  static const List<String> _videoExt = ['mp4', 'mov', 'webm'];

  bool get _hasMedia => _photos.isNotEmpty || _videoFile != null;

  @override
  void initState() {
    super.initState();
    maxPhotos = widget.limit;
    if (widget.initialVideo != null) {
      _videoFile = widget.initialVideo;
      _currentType = MediaType.video;
      _generateVideoThumbnail();
    } else if (widget.initialPhotos != null && widget.initialPhotos!.isNotEmpty) {
      _photos = widget.initialPhotos!;
      _currentType = MediaType.photos;
    }
    _notifyParent();
  }

  Future<void> _generateVideoThumbnail() async {
    if (_videoFile == null) return;

    final tempDir = await getTemporaryDirectory();

    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _videoFile!.path,
        thumbnailPath: tempDir.path, // ← Critical: specify folder
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 90,
      );

      debugPrint('Thumbnail generated at: $thumbnailPath');

      if (thumbnailPath != null && mounted) {
        setState(() {
          _videoThumbnailFile = File(thumbnailPath);
        });
      }
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
    }
  }

  // Future<void> _generateVideoThumbnail() async {
  //   if (_videoFile == null) return;
  //
  //   try {
  //     final thumbnailPath = await VideoThumbnail.thumbnailFile(
  //       video: _videoFile!.path,
  //       imageFormat: ImageFormat.JPEG,
  //       maxWidth: 512,
  //       quality: 85,
  //     );
  //
  //     if (thumbnailPath != null && mounted) {
  //       setState(() {
  //         _videoThumbnailFile = File(thumbnailPath);
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Thumbnail generation failed: $e');
  //     // Fallback: keep null, we'll show placeholder
  //   }
  // }

  // Future<void> _pickPhotos(ImageSource source) async {
  //   if (_currentType == MediaType.video) {
  //     final replace = await _showReplaceConfirmation('photos');
  //     if (!replace) return;
  //   }
  //
  //   final remaining = maxPhotos - _photos.length;
  //   if (remaining <= 0) {
  //     _showError('Maximum 10 photos allowed.');
  //     return;
  //   }
  //
  //   final XFile? cameraPick = source == ImageSource.camera
  //       ? await _picker.pickImage(source: source, imageQuality: 80)
  //       : null;
  //
  //   final List<XFile> picked = cameraPick != null
  //       ? [cameraPick]
  //       : await _picker.pickMultiImage(imageQuality: 80);
  //
  //   if (picked.isEmpty) return;
  //
  //   List<File> validFiles = [];
  //   for (var xfile in picked.take(remaining)) {
  //     final ext = xfile.path.split('.').last.toLowerCase();
  //     if (!_photoExt.contains(ext)) {
  //       _showError('Only JPG, PNG, HEIC allowed.');
  //       continue;
  //     }
  //
  //     final file = File(xfile.path);
  //     final sizeMB = (await file.length()) ~/ (1024 * 1024);
  //     if (sizeMB > photoMaxSizeMB) {
  //       _showError('Photo exceeds 10 MB.');
  //       continue;
  //     }
  //
  //     validFiles.add(file);
  //   }
  //
  //   if (validFiles.isNotEmpty) {
  //     setState(() {
  //       _photos.addAll(validFiles);
  //       _videoFile = null;
  //       _currentType = MediaType.photos;
  //     });
  //     _notifyParent();
  //   }
  // }

  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade50,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade100),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _pickPhotos(ImageSource source) async {
    if (_currentType == MediaType.video) {
      final replace = await _showReplaceConfirmation('photos');
      if (!replace) return;
    }

    final remaining = maxPhotos - _photos.length;
    if (remaining <= 0) {
      _showWarningMessage('Maximum ${maxPhotos} photos allowed.');
      return;
    }

    final XFile? cameraPick = source == ImageSource.camera
        ? await _picker.pickImage(source: source, imageQuality: 80)
        : null;

    final List<XFile> picked = cameraPick != null
        ? [cameraPick]
        : await _picker.pickMultiImage(imageQuality: 80);

    if (picked.isEmpty) return;

    List<File> validFiles = [];
    for (var xfile in picked.take(remaining)) {
      final ext = xfile.path.split('.').last.toLowerCase();
      if (!_photoExt.contains(ext)) {
        _showWarningMessage('Only JPG, PNG, HEIC allowed.');
        continue;
      }

      final file = File(xfile.path);

      final fileSizeBytes = await file.length();
      final sizeMB = fileSizeBytes / (1024 * 1024);
      if (sizeMB > photoMaxSizeMB) {
        _showWarningMessage('Photo exceeds 10 MB (${sizeMB.toStringAsFixed(1)} MB).');
        continue;
      }


      validFiles.add(file);
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        _photos.addAll(validFiles);
        _videoFile = null;
        _videoThumbnailFile = null;
        _currentType = MediaType.photos;
      });
      _notifyParent();
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (!widget.allowVideo) return;

    if (_photos.isNotEmpty) {
      final replace = await _showReplaceConfirmation('video');
      if (!replace) return;
    }

    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: videoMaxDurationSec),
    );

    if (picked == null) return;
    print('${picked.path}');

    final ext = picked.path.split('.').last.toLowerCase();
    if (ext == 'gif') {
      _showWarningMessage('GIF files are not allowed. Please select a video (MP4, MOV, or WEBM).'); // not working
      return;
    }
    if (!_videoExt.contains(ext)) {
      _showWarningMessage('Only MP4, MOV, WEBM allowed.');
      return;
    }

    final file = File(picked.path);
    final fileSizeBytes = await file.length();
    final sizeMB = fileSizeBytes / (1024 * 1024);

    if (sizeMB > videoMaxSizeMB) {
      _showWarningMessage('Video exceeds 100 MB (${sizeMB.toStringAsFixed(1)} MB).');
      return;
    }

    VideoPlayerController controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose(); // Clean up immediately

    if (duration.inSeconds > videoMaxDurationSec) {
      _showWarningMessage('Video must be 60 seconds or shorter (selected: ${duration.inSeconds}s).');
      return;
    }

    setState(() {
      _videoFile = file;
      _videoThumbnailFile = null;
      _photos.clear();
      _currentType = MediaType.video;
    });
    await _generateVideoThumbnail();
    _notifyParent();
  }

  Future<bool> _showReplaceConfirmation(String newType) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace current media?'),
        content: Text('Adding a $newType will remove the existing one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Replace', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
    if (_photos.isEmpty && _videoFile == null) _currentType = null;
    _notifyParent();
  }

  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _videoThumbnailFile = null;
      if (_photos.isEmpty) _currentType = null;
    });
    _notifyParent();
  }

  void _notifyParent() {
    widget.onMediaChanged?.call(_photos, _videoFile);
  }


  void _showPickerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Media',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xff573353),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.allowPhoto) ...[
              const SizedBox(height: 12),
              _option(Icons.photo_camera, 'Take Photo', () => _pickPhotos(ImageSource.camera)),
              const SizedBox(height: 12),
              _option(Icons.image, 'Photo Gallery', () => _pickPhotos(ImageSource.gallery)),
            ],
            if (widget.allowVideo) ...[
              const SizedBox(height: 12),
              _option(Icons.videocam, 'Record Video', () => _pickVideo(ImageSource.camera)),
              const SizedBox(height: 12),
              _option(Icons.video_library, 'Video Gallery', () => _pickVideo(ImageSource.gallery)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Row(
        children: [
          Icon(icon, size: 35, color: const Color(0xff573353)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xff573353))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Upload Area
        IntrinsicHeight(
          child: GestureDetector(
            onTap: _showPickerDialog,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0x1AB1AFE9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(MediaRes.uploadPhotoVideoImage),
                  const SizedBox(height: 16),
                  const Text(
                    'Take/Upload',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 10,)
                ],
              ),
            ),
          ),
        ),

        // Required Warning
        if (widget.isRequired && !_hasMedia)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Manrope',
                ),
                children:  [
                  const TextSpan(text: 'Please upload at least one photo or a video'),
                  const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Horizontal Scrollable Preview
        if (_hasMedia)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentType == MediaType.video
                    ? '1 Video selected'
                    : '${_photos.length} Photo${_photos.length > 1 ? 's' : ''} selected',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff573353)),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_currentType == MediaType.video)
                      _buildPreviewItem(_videoThumbnailFile, isVideo: true), // Placeholder for video
                    ..._photos.asMap().entries.map((entry) {
                      return _buildPreviewItem(entry.value, index: entry.key);
                    }),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),

        // Add More Button
        // if (_hasMedia)
        //   Align(
        //     alignment: Alignment.centerRight,
        //     child: ElevatedButton.icon(
        //       onPressed: (_currentType == MediaType.photos && _photos.length >= maxPhotos) ||
        //           _currentType == MediaType.video
        //           ? null
        //           : _showPickerDialog,
        //       icon: const Icon(Icons.add, size: 18),
        //       label: const Text('Add More'),
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: const Color(0xff573353),
        //         foregroundColor: Colors.white,
        //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildPreviewItem(File? file, {int? index, bool isVideo = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 120,
              height: 120,
              color: Colors.grey[300],
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                if (isVideo) {
                  _removeVideo();
                } else if (index != null) {
                  _removePhoto(index);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }


}