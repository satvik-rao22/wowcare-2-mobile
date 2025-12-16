// widgets/single_media_uploader.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';

enum MediaType { photo, video }

class UploadPhotoVideo extends StatefulWidget {
  const UploadPhotoVideo({
    super.key,
    this.initialFile,
    this.onMediaChanged,
    this.canTakeVideo = false,
    this.canUploadVideo = false
  });

  final File? initialFile;
  final ValueChanged<File?>? onMediaChanged;
  final bool canTakeVideo;
  final bool canUploadVideo;

  @override
  State<UploadPhotoVideo> createState() => _UploadPhotoVideoState();
}

class _UploadPhotoVideoState extends State<UploadPhotoVideo> {
  File? _mediaFile;
  MediaType? _mediaType;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _mediaFile = widget.initialFile;
      _mediaType = _mediaFile!.path.toLowerCase().endsWith('.mp4') ||
          _mediaFile!.path.toLowerCase().endsWith('.mov')
          ? MediaType.video
          : MediaType.photo;
    }
  }

  Future<void> _pickMedia({
    required ImageSource source,
    required MediaType type,
  }) async {
    XFile? pickedFile;

    if (type == MediaType.photo) {
      pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
    } else {
      pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
    }

    if (pickedFile != null && mounted) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
        _mediaType = type;
      });
      widget.onMediaChanged?.call(_mediaFile);
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaFile = null;
      _mediaType = null;
    });
    widget.onMediaChanged?.call(null);
  }

  void _showMediaPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Media Source',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff573353),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     _buildDialogOption(
                //       icon: Icons.photo_camera,
                //       label: 'Camera\nPhoto',
                //       onTap: () {
                //         Navigator.pop(dialogContext);
                //         _pickMedia(source: ImageSource.camera, type: MediaType.photo);
                //       },
                //     ),
                //     _buildDialogOption(
                //       icon: Icons.videocam,
                //       label: 'Camera\nVideo',
                //       onTap: () {
                //         Navigator.pop(dialogContext);
                //         _pickMedia(source: ImageSource.camera, type: MediaType.video);
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(height: 10,),
                _buildDialogOption(icon: Icons.photo_camera, label: 'Take Photo', onTap: () {
                  Navigator.pop(dialogContext);
                  _pickMedia(source: ImageSource.camera, type: MediaType.photo);
                },),
                const SizedBox(height: 10),
                _buildDialogOption(
                  icon: Icons.image,
                  label: 'Photo Gallery',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
                  },
                ),
                const SizedBox(height: 10,),
                _buildDialogOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _pickMedia(source: ImageSource.camera, type: MediaType.video);
                  },
                ),
                const SizedBox(height: 10,),
                _buildDialogOption(
                  icon: Icons.video_library,
                  label: 'Video Gallery',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _pickMedia(source: ImageSource.gallery, type: MediaType.video);
                  },
                ),


                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     _buildDialogOption(
                //       icon: Icons.image,
                //       label: 'Gallery\nPhoto',
                //       onTap: () {
                //         Navigator.pop(dialogContext);
                //         _pickMedia(source: ImageSource.gallery, type: MediaType.photo);
                //       },
                //     ),
                //     _buildDialogOption(
                //       icon: Icons.video_library,
                //       label: 'Gallery\nVideo',
                //       onTap: () {
                //         Navigator.pop(dialogContext);
                //         _pickMedia(source: ImageSource.gallery, type: MediaType.video);
                //       },
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),
              ],
            ),
          ),
          // actions: [
          //   TextButton(
          //     onPressed: () => Navigator.pop(dialogContext),
          //     child: const Text(
          //       'Cancel',
          //       style: TextStyle(color: Color(0xff573353)),
          //     ),
          //   ),
          // ],
        );
      },
    );
  }

  Widget _buildDialogOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 35,
            color: const Color(0xff573353),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _mediaFile == null ? _showMediaPickerDialog : null,
        child: Container(
          width: double.infinity,
          height: 290,
          //margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0x1AB1AFE9),
            //color: const Color(0xff573353).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _mediaFile == null
              ? Column(
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
                          ],
                        )
              : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _mediaType == MediaType.video
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _mediaFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 80,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                  ],
                )
                    : Image.file(
                  _mediaFile!,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeMedia,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}