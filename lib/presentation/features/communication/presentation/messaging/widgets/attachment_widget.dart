import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:path/path.dart' as p;
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../domain/features/communication/entities/message.dart';

class AttachmentWidget extends StatefulWidget {
  final Widget iconWidget;
  final Function(List<ChatAttachment>) onAttachmentsSelected;
  final double? size;
  const AttachmentWidget({
    super.key,
    required this.iconWidget,
    required this.onAttachmentsSelected,
    this.size = 28,
  });

  @override
  State<AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<AttachmentWidget> {
  final ImagePicker _picker = ImagePicker();

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
    });
  }

  Future<void> _showAttachmentOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.cardColor,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.messagingBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomTextWidget(
                      text: AppStrings.addAttachment,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Options
              _AttachmentOption(
                icon: Icons.photo_library_rounded,
                title: AppStrings.photosMultiple,
                subtitle: AppStrings.photosSubtitle,
                onTap: () => Navigator.pop(context, 'photos'),
              ),
              _AttachmentOption(
                icon: Icons.camera_alt_rounded,
                title: AppStrings.takePhoto,
                subtitle: AppStrings.takePhotoSubtitle,
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              _AttachmentOption(
                icon: Icons.upload_file_rounded,
                title: AppStrings.documentOneFile,
                subtitle: AppStrings.documentSubtitle,
                onTap: () => Navigator.pop(context, 'document'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedImageExtensions,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .map((pf) => pf.path)
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .map((p) => File(p))
        .toList();
    if (files.isEmpty) return;
    await _processFiles(files, isPhoto: true);
  }

  Future<void> _pickSinglePhotoFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    await _processFiles([File(file.path)], isPhoto: true);
  }

  Future<void> _pickSingleDocument() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedDocumentExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;
    await _processFiles([File(path)], isPhoto: false);
  }

  Future<void> _processFiles(List<File> files, {required bool isPhoto}) async {
    List<ChatAttachment> valid = [];
    for (var file in files) {
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        if (!mounted) return;
        _showWarningMessage(AppStrings.doNotExceed10MB);
        continue;
      }
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      final ext = p.extension(file.path).toLowerCase();

      if (isPhoto &&
          !FilePickerUtils.allowedImageExtensions
              .map((e) => '.$e')
              .contains(ext)) {
        continue;
      }
      if (!isPhoto &&
          !FilePickerUtils.allowedDocumentExtensions
              .map((e) => '.$e')
              .contains(ext)) {
        continue;
      }

      valid.add(
        ChatAttachment(
          localPath: file.path,
          name: p.basename(file.path),
          type: isPhoto ? 'image' : 'document',
          sizeBytes: size,
          mimeType: mime,
          remoteUrl: '', // Will be updated after upload
        ),
      );
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

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.transparentColor,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextWidget(
                        text: title,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontColor: AppColors.messagingMenuText,
                      ),
                      const SizedBox(height: 4),
                      CustomTextWidget(
                        text: subtitle,
                        fontSize: 12,
                        fontColor: AppColors.messagingTextMeta,
                      ),
                    ],
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
