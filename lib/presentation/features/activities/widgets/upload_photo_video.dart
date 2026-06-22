// // // widgets/single_media_uploader.dart
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// //
// // import '../../../../app/theme/colors.dart';
// // import '../../../../app/theme/media_res.dart';
// //
// // enum MediaType { photo, video }
// //
// // class UploadPhotoVideo extends StatefulWidget {
// //   const UploadPhotoVideo({
// //     super.key,
// //     this.initialFile,
// //     this.onMediaChanged,
// //     this.canTakeVideo = false,
// //     this.canUploadVideo = false
// //   });
// //
// //   final File? initialFile;
// //   final ValueChanged<File?>? onMediaChanged;
// //   final bool canTakeVideo;
// //   final bool canUploadVideo;
// //
// //   @override
// //   State<UploadPhotoVideo> createState() => _UploadPhotoVideoState();
// // }
// //
// // class _UploadPhotoVideoState extends State<UploadPhotoVideo> {
// //   File? _mediaFile;
// //   MediaType? _mediaType;
// //   final ImagePicker _picker = ImagePicker();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     if (widget.initialFile != null) {
// //       _mediaFile = widget.initialFile;
// //       _mediaType = _mediaFile!.path.toLowerCase().endsWith('.mp4') ||
// //           _mediaFile!.path.toLowerCase().endsWith('.mov')
// //           ? MediaType.video
// //           : MediaType.photo;
// //     }
// //   }
// //
// //   Future<void> _pickMedia({
// //     required ImageSource source,
// //     required MediaType type,
// //   }) async {
// //     XFile? pickedFile;
// //
// //     if (type == MediaType.photo) {
// //       pickedFile = await _picker.pickImage(
// //         source: source,
// //         imageQuality: 85,
// //       );
// //     } else {
// //       pickedFile = await _picker.pickVideo(
// //         source: source,
// //         maxDuration: const Duration(minutes: 2),
// //       );
// //     }
// //
// //     if (pickedFile != null && mounted) {
// //       setState(() {
// //         _mediaFile = File(pickedFile!.path);
// //         _mediaType = type;
// //       });
// //       widget.onMediaChanged?.call(_mediaFile);
// //     }
// //   }
// //
// //   void _removeMedia() {
// //     setState(() {
// //       _mediaFile = null;
// //       _mediaType = null;
// //     });
// //     widget.onMediaChanged?.call(null);
// //   }
// //
// //   void _showMediaPickerDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext dialogContext) {
// //         return AlertDialog(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           title: const Text(
// //             'Select Media Source',
// //             textAlign: TextAlign.center,
// //             style: TextStyle(
// //               fontFamily: 'Manrope',
// //               fontSize: 24,
// //               fontWeight: FontWeight.w600,
// //               color: Color(0xff573353),
// //             ),
// //           ),
// //           content: Padding(
// //             padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               mainAxisAlignment: MainAxisAlignment.start,
// //               children: [
// //                 // Row(
// //                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 //   children: [
// //                 //     _buildDialogOption(
// //                 //       icon: Icons.photo_camera,
// //                 //       label: 'Camera\nPhoto',
// //                 //       onTap: () {
// //                 //         Navigator.pop(dialogContext);
// //                 //         _pickMedia(source: ImageSource.camera, type: MediaType.photo);
// //                 //       },
// //                 //     ),
// //                 //     _buildDialogOption(
// //                 //       icon: Icons.videocam,
// //                 //       label: 'Camera\nVideo',
// //                 //       onTap: () {
// //                 //         Navigator.pop(dialogContext);
// //                 //         _pickMedia(source: ImageSource.camera, type: MediaType.video);
// //                 //       },
// //                 //     ),
// //                 //   ],
// //                 // ),
// //                 const SizedBox(height: 10,),
// //                 _buildDialogOption(icon: Icons.photo_camera, label: 'Take Photo', onTap: () {
// //                   Navigator.pop(dialogContext);
// //                   _pickMedia(source: ImageSource.camera, type: MediaType.photo);
// //                 },),
// //                 const SizedBox(height: 10),
// //                 _buildDialogOption(
// //                   icon: Icons.image,
// //                   label: 'Photo Gallery',
// //                   onTap: () {
// //                     Navigator.pop(dialogContext);
// //                     _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
// //                   },
// //                 ),
// //                 const SizedBox(height: 10,),
// //                 _buildDialogOption(
// //                   icon: Icons.videocam,
// //                   label: 'Record Video',
// //                   onTap: () {
// //                     Navigator.pop(dialogContext);
// //                     _pickMedia(source: ImageSource.camera, type: MediaType.video);
// //                   },
// //                 ),
// //                 const SizedBox(height: 10,),
// //                 _buildDialogOption(
// //                   icon: Icons.video_library,
// //                   label: 'Video Gallery',
// //                   onTap: () {
// //                     Navigator.pop(dialogContext);
// //                     _pickMedia(source: ImageSource.gallery, type: MediaType.video);
// //                   },
// //                 ),
// //
// //
// //                 // Row(
// //                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                 //   children: [
// //                 //     _buildDialogOption(
// //                 //       icon: Icons.image,
// //                 //       label: 'Gallery\nPhoto',
// //                 //       onTap: () {
// //                 //         Navigator.pop(dialogContext);
// //                 //         _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
// //                 //       },
// //                 //     ),
// //                 //     _buildDialogOption(
// //                 //       icon: Icons.video_library,
// //                 //       label: 'Gallery\nVideo',
// //                 //       onTap: () {
// //                 //         Navigator.pop(dialogContext);
// //                 //         _pickMedia(source: ImageSource.gallery, type: MediaType.video);
// //                 //       },
// //                 //     ),
// //                 //   ],
// //                 // ),
// //                 // const SizedBox(height: 16),
// //               ],
// //             ),
// //           ),
// //           // actions: [
// //           //   TextButton(
// //           //     onPressed: () => Navigator.pop(dialogContext),
// //           //     child: const Text(
// //           //       'Cancel',
// //           //       style: TextStyle(color: Color(0xff573353)),
// //           //     ),
// //           //   ),
// //           // ],
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _buildDialogOption({
// //     required IconData icon,
// //     required String label,
// //     required VoidCallback onTap,
// //   }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Row(
// //         //mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             icon,
// //             size: 35,
// //             color: const Color(0xff573353),
// //           ),
// //           const SizedBox(width: 10),
// //           Text(
// //             label,
// //             textAlign: TextAlign.center,
// //             style: const TextStyle(
// //               fontSize: 16,
// //               fontWeight: FontWeight.w400,
// //               color: Color(0xff573353),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: GestureDetector(
// //         onTap: _mediaFile == null ? _showMediaPickerDialog : null,
// //         child: Container(
// //           width: double.infinity,
// //           height: 290,
// //           //margin: const EdgeInsets.symmetric(horizontal: 20),
// //           decoration: BoxDecoration(
// //             color: const Color(0x1AB1AFE9),
// //             //color: const Color(0xff573353).withValues(alpha:0.05),
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: _mediaFile == null
// //               ? Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //               Image.asset(MediaRes.uploadPhotoVideoImage),
// //               const SizedBox(height: 16),
// //               const Text(
// //                 'Take/Upload',
// //                 style: TextStyle(
// //                   fontSize: 14,
// //                   color: AppColors.primaryColor,
// //                   fontWeight: FontWeight.w400,
// //                 ),
// //               ),
// //                           ],
// //                         )
// //               : Stack(
// //             fit: StackFit.expand,
// //             children: [
// //               ClipRRect(
// //                 borderRadius: BorderRadius.circular(18),
// //                 child: _mediaType == MediaType.video
// //                     ? Stack(
// //                   fit: StackFit.expand,
// //                   children: [
// //                     Image.file(
// //                       _mediaFile!,
// //                       fit: BoxFit.cover,
// //                       errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
// //                     ),
// //                     const Center(
// //                       child: Icon(
// //                         Icons.play_circle_fill,
// //                         size: 80,
// //                         color: Colors.white,
// //                         shadows: [Shadow(blurRadius: 10, color: Colors.black)],
// //                       ),
// //                     ),
// //                   ],
// //                 )
// //                     : Image.file(
// //                   _mediaFile!,
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //               Positioned(
// //                 top: 8,
// //                 right: 8,
// //                 child: GestureDetector(
// //                   onTap: _removeMedia,
// //                   child: Container(
// //                     padding: const EdgeInsets.all(6),
// //                     decoration: const BoxDecoration(
// //                       color: Colors.black54,
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: const Icon(
// //                       Icons.close,
// //                       color: Colors.white,
// //                       size: 20,
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// // the above is for only one file upload
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// import '../../../../app/theme/colors.dart';
// import '../../../../app/theme/media_res.dart';
// import '../../../../shared/utils/responsive_helper.dart';
//
// enum MediaType { photos, video }
//
// class MediaUploader extends StatefulWidget {
//   const MediaUploader({
//     super.key,
//     this.initialPhotos,
//     this.initialVideo,
//     this.onMediaChanged,
//     this.allowPhoto = true,
//     this.allowVideo = true,
//     this.isRequired = false,
//     this.limit = 10,
//     this.label = 'Upload Photos',
//     this.isPictureBox = true,
//     this.photoSizeLimit
//   });
//
//   final List<File>? initialPhotos;
//   final File? initialVideo;
//   final Function(List<File> photos, File? video)? onMediaChanged;
//   final bool allowVideo;
//   final bool allowPhoto;
//   final bool isRequired;
//   final int limit;
//   final String label;
//   final bool isPictureBox;
//   final int? photoSizeLimit;
//
//   @override
//   State<MediaUploader> createState() => _MediaUploaderState();
// }
//
// class _MediaUploaderState extends State<MediaUploader> {
//   List<File> _photos = [];
//   File? _videoFile;
//   File? _videoThumbnailFile;
//   MediaType? _currentType;
//   final ImagePicker _picker = ImagePicker();
//
//   // Limits
//   late int maxPhotos ;
//   late int photoMaxSizeMB;
//   static const int videoMaxSizeMB = 100;
//   static const int videoMaxDurationSec = 60;
//
//   static const List<String> _photoExt = ['jpg', 'jpeg', 'png', 'heic', 'heif'];
//   static const List<String> _videoExt = ['mp4', 'mov', 'webm'];
//
//   bool get _hasMedia => _photos.isNotEmpty || _videoFile != null;
//
//   @override
//   void initState() {
//     super.initState();
//     maxPhotos = widget.limit;
//     photoMaxSizeMB = widget.photoSizeLimit ?? 10;
//     if (widget.initialVideo != null) {
//       _videoFile = widget.initialVideo;
//       _currentType = MediaType.video;
//       _generateVideoThumbnail();
//     } else if (widget.initialPhotos != null && widget.initialPhotos!.isNotEmpty) {
//       _photos = widget.initialPhotos!;
//       _currentType = MediaType.photos;
//     }
//
//     WidgetsBinding.instance.addPostFrameCallback((_){
//       if(mounted){
//         _notifyParent();
//       }
//     });
//     //_notifyParent();
//   }
//
//   Future<void> _generateVideoThumbnail() async {
//     if (_videoFile == null) return;
//
//     final tempDir = await getTemporaryDirectory();
//
//     try {
//       final thumbnailPath = await VideoThumbnail.thumbnailFile(
//         video: _videoFile!.path,
//         thumbnailPath: tempDir.path, // ← Critical: specify folder
//         imageFormat: ImageFormat.JPEG,
//         maxWidth: 512,
//         quality: 90,
//       );
//
//       debugPrint('Thumbnail generated at: $thumbnailPath');
//
//       if (thumbnailPath != null && mounted) {
//         setState(() {
//           _videoThumbnailFile = File(thumbnailPath);
//         });
//       }
//     } catch (e) {
//       debugPrint('Thumbnail generation failed: $e');
//     }
//   }
//
//   // Future<void> _generateVideoThumbnail() async {
//   //   if (_videoFile == null) return;
//   //
//   //   try {
//   //     final thumbnailPath = await VideoThumbnail.thumbnailFile(
//   //       video: _videoFile!.path,
//   //       imageFormat: ImageFormat.JPEG,
//   //       maxWidth: 512,
//   //       quality: 85,
//   //     );
//   //
//   //     if (thumbnailPath != null && mounted) {
//   //       setState(() {
//   //         _videoThumbnailFile = File(thumbnailPath);
//   //       });
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Thumbnail generation failed: $e');
//   //     // Fallback: keep null, we'll show placeholder
//   //   }
//   // }
//
//   // Future<void> _pickPhotos(ImageSource source) async {
//   //   if (_currentType == MediaType.video) {
//   //     final replace = await _showReplaceConfirmation('photos');
//   //     if (!replace) return;
//   //   }
//   //
//   //   final remaining = maxPhotos - _photos.length;
//   //   if (remaining <= 0) {
//   //     _showError('Maximum 10 photos allowed.');
//   //     return;
//   //   }
//   //
//   //   final XFile? cameraPick = source == ImageSource.camera
//   //       ? await _picker.pickImage(source: source, imageQuality: 80)
//   //       : null;
//   //
//   //   final List<XFile> picked = cameraPick != null
//   //       ? [cameraPick]
//   //       : await _picker.pickMultiImage(imageQuality: 80);
//   //
//   //   if (picked.isEmpty) return;
//   //
//   //   List<File> validFiles = [];
//   //   for (var xfile in picked.take(remaining)) {
//   //     final ext = xfile.path.split('.').last.toLowerCase();
//   //     if (!_photoExt.contains(ext)) {
//   //       _showError('Only JPG, PNG, HEIC allowed.');
//   //       continue;
//   //     }
//   //
//   //     final file = File(xfile.path);
//   //     final sizeMB = (await file.length()) ~/ (1024 * 1024);
//   //     if (sizeMB > photoMaxSizeMB) {
//   //       _showError('Photo exceeds 10 MB.');
//   //       continue;
//   //     }
//   //
//   //     validFiles.add(file);
//   //   }
//   //
//   //   if (validFiles.isNotEmpty) {
//   //     setState(() {
//   //       _photos.addAll(validFiles);
//   //       _videoFile = null;
//   //       _currentType = MediaType.photos;
//   //     });
//   //     _notifyParent();
//   //   }
//   // }
//
//   void _showWarningMessage(String message) {
//     ScaffoldMessenger.of(context).removeCurrentSnackBar();
//     final snackBar = SnackBar(
//       content: Row(
//         children: [
//           const Icon(Icons.warning, color: Colors.orange),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               message,
//               style: const TextStyle(
//                 color: Colors.orange,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//       backgroundColor: Colors.orange.shade50,
//       duration: const Duration(seconds: 2),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//         side: BorderSide(color: Colors.orange.shade100),
//       ),
//     );
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }
//
//   Future<void> _pickPhotos(ImageSource source) async {
//     if (_currentType == MediaType.video) {
//       final replace = await _showReplaceConfirmation('photos');
//       if (!replace) return;
//     }
//
//     final remaining = maxPhotos - _photos.length;
//     if (remaining <= 0) {
//       _showWarningMessage('Maximum ${maxPhotos} photos allowed.');
//       return;
//     }
//
//     final XFile? cameraPick = source == ImageSource.camera
//         ? await _picker.pickImage(source: source, imageQuality: 80)
//         : null;
//
//     final List<XFile> picked = cameraPick != null
//         ? [cameraPick]
//         : await _picker.pickMultiImage(imageQuality: 80);
//
//     if (picked.isEmpty) return;
//
//     List<File> validFiles = [];
//     for (var xfile in picked.take(remaining)) {
//       final ext = xfile.path.split('.').last.toLowerCase();
//       if (!_photoExt.contains(ext)) {
//         _showWarningMessage('Only JPG, PNG, HEIC allowed.');
//         continue;
//       }
//
//       final file = File(xfile.path);
//
//       final fileSizeBytes = await file.length();
//       final sizeMB = fileSizeBytes / (1024 * 1024);
//       if (sizeMB > photoMaxSizeMB) {
//         _showWarningMessage('Photo exceeds 10 MB (${sizeMB.toStringAsFixed(1)} MB).');
//         continue;
//       }
//
//
//       validFiles.add(file);
//     }
//
//     if (validFiles.isNotEmpty) {
//       setState(() {
//         _photos.addAll(validFiles);
//         _videoFile = null;
//         _videoThumbnailFile = null;
//         _currentType = MediaType.photos;
//       });
//       _notifyParent();
//     }
//   }
//
//   Future<void> _pickVideo(ImageSource source) async {
//     if (!widget.allowVideo) return;
//
//     if (_photos.isNotEmpty) {
//       final replace = await _showReplaceConfirmation('video');
//       if (!replace) return;
//     }
//
//     final XFile? picked = await _picker.pickVideo(
//       source: source,
//       maxDuration: const Duration(seconds: videoMaxDurationSec),
//     );
//
//     if (picked == null) return;
//     AppLogger.d('${picked.path}');
//
//     final ext = picked.path.split('.').last.toLowerCase();
//     if (ext == 'gif') {
//       _showWarningMessage('GIF files are not allowed. Please select a video (MP4, MOV, or WEBM).'); // not working
//       return;
//     }
//     if (!_videoExt.contains(ext)) {
//       _showWarningMessage('Only MP4, MOV, WEBM allowed.');
//       return;
//     }
//
//     final file = File(picked.path);
//     final fileSizeBytes = await file.length();
//     final sizeMB = fileSizeBytes / (1024 * 1024);
//
//     if (sizeMB > videoMaxSizeMB) {
//       _showWarningMessage('Video exceeds 100 MB (${sizeMB.toStringAsFixed(1)} MB).');
//       return;
//     }
//     // this part makes the the app unable to upload video on linux, but that is not our target device so should be ok
//     VideoPlayerController controller = VideoPlayerController.file(file);
//     await controller.initialize();
//     final duration = controller.value.duration;
//     await controller.dispose(); // Clean up immediately
//
//     if (duration.inSeconds > videoMaxDurationSec) {
//       _showWarningMessage('Video must be 60 seconds or shorter (selected: ${duration.inSeconds}s).');
//       return;
//     }
//
//     setState(() {
//       _videoFile = file;
//       _videoThumbnailFile = null;
//       _photos.clear();
//       _currentType = MediaType.video;
//     });
//     await _generateVideoThumbnail();
//     _notifyParent();
//   }
//
//   Future<bool> _showReplaceConfirmation(String newType) async {
//     return await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Replace current media?'),
//         content: Text('Adding a $newType will remove the existing one.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Replace', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     ) ??
//         false;
//   }
//
//   void _removePhoto(int index) {
//     setState(() => _photos.removeAt(index));
//     if (_photos.isEmpty && _videoFile == null) _currentType = null;
//     _notifyParent();
//   }
//
//   void _removeVideo() {
//     setState(() {
//       _videoFile = null;
//       _videoThumbnailFile = null;
//       if (_photos.isEmpty) _currentType = null;
//     });
//     _notifyParent();
//   }
//
//   void _notifyParent() {
//     widget.onMediaChanged?.call(_photos, _videoFile);
//   }
//
//
//   void _showPickerDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           'Select Media Source',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontFamily: 'Manrope',
//             fontSize: 24,
//             fontWeight: FontWeight.w600,
//             color: Color(0xff573353),
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (widget.allowPhoto) ...[
//               const SizedBox(height: 12),
//               _option(Icons.photo_camera, 'Take Photo', () => _pickPhotos(ImageSource.camera)),
//               const SizedBox(height: 12),
//               _option(Icons.image, 'Photo Gallery', () => _pickPhotos(ImageSource.gallery)),
//             ],
//             if (widget.allowVideo) ...[
//               const SizedBox(height: 12),
//               _option(Icons.videocam, 'Record Video', () => _pickVideo(ImageSource.camera)),
//               const SizedBox(height: 12),
//               _option(Icons.video_library, 'Video Gallery', () => _pickVideo(ImageSource.gallery)),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _option(IconData icon, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.pop(context);
//         onTap();
//       },
//       child: Row(
//         children: [
//           Icon(icon, size: 35, color: const Color(0xff573353)),
//           const SizedBox(width: 12),
//           Text(label, style: const TextStyle(fontSize: 16, color: Color(0xff573353))),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final responsive = ResponsiveHelper(context);
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Main Upload Area
//         if (widget.isPictureBox) IntrinsicHeight(
//           child: GestureDetector(
//             onTap: _showPickerDialog,
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: const Color(0x1AB1AFE9),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Image.asset(MediaRes.uploadPhotoVideoImage),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Take/Upload',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: AppColors.primaryColor,
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                   SizedBox(height: 10,)
//                 ],
//               ),
//             ),
//           ),
//         ),
//         if(!widget.isPictureBox)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               RichText(
//                 text: TextSpan(
//                 style: TextStyle(
//                   fontSize: responsive.labelFontSize,
//                   fontFamily: "Manrope",
//                   fontWeight: FontWeight.w400,
//                   color: const Color(0xff573353),
//                 ),
//                 children: [
//                   TextSpan(text: widget.label),
//                   if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
//                 ],
//                 ),
//               ),
//               SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
//               GestureDetector(
//                 onTap: _showPickerDialog,
//                 child: Container(
//                   constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(color: const Color(0x66573353)),
//                     borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: responsive.isTablet ? 16.0 : 12.0,
//                       vertical: responsive.isTablet ? 16.0 : 12.0,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Select Photos',
//                           style: TextStyle(
//                             fontSize: responsive.labelFontSize,
//                             fontFamily: "Manrope",
//                             fontWeight: FontWeight.w400,
//                             color: const Color(0xff573353),
//                           ),
//                         ),
//                         Opacity(
//                           opacity: 0.6,
//                           child: Icon(
//                             Icons.file_upload_outlined,
//                             color: AppColors.primaryColor,
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//         // Required Warning
//         if (widget.isRequired && !_hasMedia)
//           Padding(
//             padding: const EdgeInsets.only(top: 8, left: 4),
//             child: RichText(
//               text: TextSpan(
//                 style: const TextStyle(
//                   color: AppColors.primaryColor,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w400,
//                   fontFamily: 'Manrope',
//                 ),
//                 children:  [
//                   if(widget.allowPhoto && !widget.allowVideo)TextSpan(text: 'Please upload at least one photo'),
//                   if(!widget.allowPhoto && widget.allowVideo)TextSpan(text: 'Please upload at least one video'),
//                   if(widget.allowPhoto && widget.allowVideo)TextSpan(text: 'Please upload at least one photo or a video'),
//                   const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
//                 ],
//               ),
//             ),
//           ),
//
//         const SizedBox(height: 16),
//
//         // Horizontal Scrollable Preview
//         if (_hasMedia)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if(widget.allowPhoto && widget.limit!=1) ...[
//                 Text(
//                   _currentType == MediaType.video
//                       ? 'New selection replaces current video'
//                       : '${_photos.length} Photo${_photos.length > 1 ? 's' : ''} selected',
//                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xff573353)),
//                 ),
//                 const SizedBox(height: 12),
//               ],
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     if (_currentType == MediaType.video)
//                       _buildPreviewItem(_videoThumbnailFile, isVideo: true), // Placeholder for video
//                     ..._photos.asMap().entries.map((entry) {
//                       return _buildPreviewItem(entry.value, index: entry.key);
//                     }),
//                     const SizedBox(width: 8),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//         const SizedBox(height: 12),
//
//         // Add More Button
//         // if (_hasMedia)
//         //   Align(
//         //     alignment: Alignment.centerRight,
//         //     child: ElevatedButton.icon(
//         //       onPressed: (_currentType == MediaType.photos && _photos.length >= maxPhotos) ||
//         //           _currentType == MediaType.video
//         //           ? null
//         //           : _showPickerDialog,
//         //       icon: const Icon(Icons.add, size: 18),
//         //       label: const Text('Add More'),
//         //       style: ElevatedButton.styleFrom(
//         //         backgroundColor: const Color(0xff573353),
//         //         foregroundColor: Colors.white,
//         //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         //       ),
//         //     ),
//         //   ),
//       ],
//     );
//   }
//
//   Widget _buildPreviewItem(File? file, {int? index, bool isVideo = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 12),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               width: 120,
//               height: 120,
//               color: Colors.grey[300],
//               child: file != null
//                   ? Image.file(file, fit: BoxFit.cover)
//                   : const Center(
//                 child: Icon(
//                   Icons.play_circle_fill,
//                   size: 60,
//                   color: Colors.white70,
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             top: 4,
//             right: 4,
//             child: GestureDetector(
//               onTap: () {
//                 if (isVideo) {
//                   _removeVideo();
//                 } else if (index != null) {
//                   _removePhoto(index);
//                 }
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Colors.black54,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.close, color: Colors.white, size: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
// }

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../view/activity_item.dart';
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
    debugPrint('[MediaUploader] initState — hashCode=$hashCode');
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
    debugPrint(
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
      debugPrint('Failed to load remote video thumbnail: $e');
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

    final tempDir = await getTemporaryDirectory();
    try {
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
      debugPrint('Thumbnail failed: $e');
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
    debugPrint(
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
      debugPrint(
        '[MediaUploader] _pickPhotos: camera returned '
        '${camera == null ? 'null' : 'image'} mounted=$mounted',
      );
      if (camera == null) return;
      if (!mounted) return;
      candidates = [File(camera.path)];
    } else {
      // Use the SAF document picker (FilePicker) for the gallery so every
      // allowed image format stays selectable — including GIF (animation
      // preserved) and HEIC/HEIF. image_picker's pickMultiImage re-encodes
      // through imageQuality, which flattens GIFs and transcodes HEIC to JPEG,
      // so we keep FilePicker here and rely on allowedExtensions for filtering.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _photoExt,
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
    }

    File? file;
    if (source == ImageSource.camera) {
      final XFile? picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: videoMaxDurationSec),
      );
      if (!mounted || picked == null) return;
      file = File(picked.path);
    } else {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _videoExt,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null || path.trim().isEmpty) return;
      file = File(path);
    }

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
                  style: TextStyle(color: Colors.red),
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
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ShowFullScreenMedia(
            activity: ActivityItem(
              time: '',
              date: '',
              name: '',
              studentList: const [],
              createdBy: '',
              videoUrl: url,
            ),
          ),
        ),
      );
      return;
    }
    final file = _newVideoFile;
    if (file != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => FullscreenLocalVideoPlayerPage(videoFile: file),
        ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
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
                    child: Icon(icon, size: 26, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
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
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 60,
                  color: Colors.white70,
                ),
              ),
            ),

          Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 60,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: const [Shadow(blurRadius: 10, color: Colors.black54)],
            ),
          ),

          // if (hasRemoteVideoOnly)
          //   const Positioned(
          //     bottom: 8,
          //     left: 8,
          //     child: Padding(
          //       padding: EdgeInsets.all(8),
          //       child: Text(
          //         'Video',
          //         style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          //       ),
          //     ),
          //   ),
        ],
      ),
      onRemove: _removeVideo,
      canRemove: !widget.readOnly,
    );
  }

  // Widget _buildVideoPreview() {
  //   final hasThumbnail = _videoThumbnailFile != null;
  //
  //   return _previewItem(
  //     child: hasThumbnail
  //         ? Image.file(_videoThumbnailFile!, fit: BoxFit.cover)
  //         : const Center(child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white70)),
  //     isVideo: true,
  //     onRemove: _removeVideo,
  //   );
  // }

  Widget _buildPhotoPreviewNetwork(String url) {
    return _previewItem(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(),
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
      ),
      onRemove: () => _removeExistingPhoto(url),
      onTap: () => _showImageFullscreen(
        Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white70, size: 60),
          ),
        ),
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
            child: Icon(Icons.broken_image, color: Colors.white70, size: 60),
          ),
        ),
      ),
      canRemove: !widget.readOnly,
    );
  }

  void _showImageFullscreen(Widget imageWidget) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
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
                color: Colors.grey[300],
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
                color: const Color(0x1AB1AFE9),
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
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
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
                  style: TextStyle(
                    fontSize: responsive.labelFontSize,
                    color: const Color(0xff573353),
                  ),
                  children: widget.isRequired
                      ? [
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red),
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
                    border: Border.all(color: const Color(0x66573353)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Media',
                        style: TextStyle(fontSize: responsive.labelFontSize),
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
              style: TextStyle(color: Colors.red, fontSize: 13),
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
  const FullscreenLocalVideoPlayerPage({super.key, required this.videoFile});

  final File videoFile;

  @override
  State<FullscreenLocalVideoPlayerPage> createState() =>
      _FullscreenLocalVideoPlayerPageState();
}

class _FullscreenLocalVideoPlayerPageState
    extends State<FullscreenLocalVideoPlayerPage> {
  VideoPlayerController? _controller;

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

  @override
  void dispose() {
    _controller?.removeListener(_onCtrlUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: !ready
            ? const CircularProgressIndicator(color: Colors.white)
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
                          color: Colors.white70,
                          size: 72,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
