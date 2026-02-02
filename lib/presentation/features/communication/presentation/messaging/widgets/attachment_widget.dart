import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:path/path.dart' as p;

import '../../../../../../app/theme/colors.dart';

class ChatAttachment{
  final String path;
  final String name;
  final String type;
  final int sizeBytes;
  final String? mimeType;

  ChatAttachment({ required this.path, required this.name, required this.type, required this.sizeBytes, this.mimeType,});
  bool get isImage => type == "image";
}

class AttachmentWidget extends StatefulWidget {
  final Widget iconWidget;
  final Function(List<ChatAttachment>) onAttachmentsSelected;
  final double? size;
  const AttachmentWidget({super.key, required this.iconWidget, required this.onAttachmentsSelected, this.size = 28});

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  final ImagePicker _picker = ImagePicker();

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(!mounted) return;
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
    });
  }

  Future<void> _showAttachmentOptions() async {
    // final result = await showModalBottomSheet<String>(
    //     context: context,
    //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    //     builder: (context) {
    //       return SafeArea(
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               ListTile(
    //                 leading: const Icon(Icons.photo_library, color: AppColors.primaryColor,),
    //                 title: CustomTextWidget(text: 'Photos',),
    //                 onTap: () => Navigator.pop(context, 'photos'),
    //               ),
    //               ListTile(
    //                 leading: const Icon(Icons.camera_alt, color: AppColors.primaryColor,),
    //                 title: CustomTextWidget(text: 'Take Photo',),
    //                 onTap: () => Navigator.pop(context, 'camera'),
    //               ),
    //               ListTile(
    //                 leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryColor,),
    //                 title: CustomTextWidget(text: 'Document',),
    //                 onTap: () => Navigator.pop(context, 'document'),
    //               ),
    //             ],
    //           )
    //       );
    //     }
    // );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        title: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.fromRGBO(89, 120, 247, 0.1),
                Color.fromRGBO(156, 132, 255, 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomTextWidget(
                text: 'Add Attachment',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryColor),
              title: const CustomTextWidget(text: 'Photos (multiple allowed)'),
              subtitle: const CustomTextWidget(
                text: 'JPEG, PNG, HEIC',
                fontSize: 12,
                fontColor: Colors.grey,
              ),
              onTap: () => Navigator.pop(context, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryColor),
              title: const CustomTextWidget(text: 'Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.primaryColor),
              title: const CustomTextWidget(text: 'Document (one file)'),
              subtitle: const CustomTextWidget(
                text: 'PDF, DOC, DOCX • max 10 MB',
                fontSize: 12,
                fontColor: Colors.grey,
              ),
              onTap: () => Navigator.pop(context, 'document'),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
        actions: [
          // Container(
          //   width: double.infinity,
          //   height: 60,
          //   decoration: BoxDecoration(
          //     gradient: AppColors.buildPrimaryGradient(),
          //     borderRadius: BorderRadius.circular(16.0),
          //   ),
          //   child: TextButton(
          //     onPressed: () => Navigator.pop(context),
          //     child: const CustomTextWidget(
          //       text: 'Cancel',
          //       fontColor: Colors.white,
          //     ),
          //   ),
          // ),
          // TextButton(
          //   onPressed: () => Navigator.pop(context),
          //   child: const CustomTextWidget(
          //     text: 'Cancel',
          //     fontColor: AppColors.primaryColor,
          //   ),
          // ),
        ],
      ),
    );

    if (result == null) return;

    switch (result) {
      case 'photos':
        await _pickPhotos();
        break;
      case 'camera':
        await _pickSinglePhotoFromCamera();
        break;
      case 'document':
        await _pickSingleDocument();
        break;
    }
  }

  Future<void> _pickPhotos() async {
    final List<XFile>? files = await _picker.pickMultiImage(imageQuality: 85);
    if(files == null ||  files.isEmpty) return;
    await _processFiles(files.map((file) => File(file.path)).toList(), isPhoto: true);
  }

  Future<void> _pickSinglePhotoFromCamera() async{
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if(file == null ) return;
    await _processFiles([File(file.path)], isPhoto: true);
  }

  Future<void> _pickSingleDocument() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false
    );
    if(result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if(path == null) return;
    await _processFiles([File(path)], isPhoto: false);
  }

  Future<void> _processFiles(List<File> files, {required bool isPhoto}) async{
    List<ChatAttachment> valid = [];
    for (var file in files) {
      final size = await file.length();
      if (size > 10 * 1024 * 1024){
        if(!mounted) return;
        _showWarningMessage('Please do not exceed the 10 MB limit');
        continue;
      }
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      final ext = p.extension(file.path).toLowerCase();

      if(isPhoto && !['.jpg', '.jpeg', '.png', '.heic'].contains(ext)) continue;
      if(!isPhoto && !['.pdf', '.doc', '.docx'].contains(ext)) continue;

      valid.add(ChatAttachment(
        path: file.path,
        name: p.basename(file.path),
        type: isPhoto ? 'image' : 'document',
        sizeBytes: size,
        mimeType: mime,
      ));
    }

    if (valid.isEmpty) return;
    widget.onAttachmentsSelected(valid);

    }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showAttachmentOptions,
      child: widget.iconWidget,
    );
  }
}
