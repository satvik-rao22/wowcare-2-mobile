import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../../app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import '../../../../core/util/app_time.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/activities/view_model/school_cloud_image_uploader_cubit.dart';

/// Maximum number of images that can be uploaded to the school cloud gallery
/// in a single "Image Uploader" run.
const int kSchoolCloudUploadMaxImages = 10;

/// Opens the school "Image Uploader" dialog: pick up to
/// [kSchoolCloudUploadMaxImages] images and upload each of them to the
/// school's cloud gallery via [ImageUploadService.createSchoolCloudUploadSession]
/// followed by the generic presign -> S3 PUT -> complete flow.
Future<void> showSchoolCloudImageUploaderDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider<SchoolCloudImageUploaderCubit>(
      create: (_) => serviceLocator<SchoolCloudImageUploaderCubit>(),
      child: const SchoolCloudImageUploaderDialog(),
    ),
  );
}

class SchoolCloudImageUploaderDialog extends StatefulWidget {
  const SchoolCloudImageUploaderDialog({super.key});

  @override
  State<SchoolCloudImageUploaderDialog> createState() =>
      _SchoolCloudImageUploaderDialogState();
}

class _SchoolCloudImageUploaderDialogState
    extends State<SchoolCloudImageUploaderDialog> {
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  int _overallUploadPercent = 0;

  bool get _atCapacity => _selectedImages.length >= kSchoolCloudUploadMaxImages;

  Future<void> _chooseMedia() async {
    if (_atCapacity) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'You can upload up to $kSchoolCloudUploadMaxImages images at a time.',
        isWarning: true,
      );
      return;
    }

    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    if (!mounted) return;

    final existingPaths = _selectedImages.map((f) => f.path).toSet();
    final remainingSlots = kSchoolCloudUploadMaxImages - _selectedImages.length;
    final newFiles = picked
        .map((x) => File(x.path))
        .where((f) => !existingPaths.contains(f.path))
        .toList();
    final accepted = newFiles.take(remainingSlots).toList();

    setState(() => _selectedImages.addAll(accepted));

    if (newFiles.length > accepted.length) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Only the first $kSchoolCloudUploadMaxImages images were kept — that\'s the max per upload.',
        isWarning: true,
      );
    }
  }

  void _removeSelectedImage(File file) =>
      setState(() => _selectedImages.remove(file));

  Future<void> _upload() async {
    if (_selectedImages.isEmpty || _isUploading) return;

    final files = List<File>.from(_selectedImages);
    final total = files.length;
    final failedFiles = <File>[];

    setState(() {
      _isUploading = true;
      _overallUploadPercent = 0;
    });
    try {
      final cubit = context.read<SchoolCloudImageUploaderCubit>();
      final schoolCode = await cubit.getSchoolCode();
      if (schoolCode.isEmpty) {
        throw Exception(
          'Missing school context. Please re-login and try again.',
        );
      }

      for (var i = 0; i < total; i++) {
        final image = files[i];
        try {
          final uploadSession = await cubit.createSchoolCloudUploadSession(
            schoolCode: schoolCode,
          );

          final fileName = image.uri.pathSegments.isNotEmpty
              ? image.uri.pathSegments.last
              : 'image-${AppTime.nowUtc().millisecondsSinceEpoch}.jpg';
          final contentType = lookupMimeType(image.path) ?? 'image/jpeg';
          final contentLengthBytes = await image.length();

          final presign = await cubit.createAssetPresign(
            sessionCode: uploadSession.sessionCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
            fileName: fileName,
            contentType: contentType,
            contentLengthBytes: contentLengthBytes,
            mediaType: 'IMAGE',
            ownerType: 'SCHOOL',
            ownerCode: schoolCode,
          );

          await cubit.uploadFileToPresignedUrl(
            file: image,
            presignedPutUrl: presign.presignedPutUrl,
            requiredHeaders: presign.requiredHeaders,
            fallbackContentType: contentType,
            onProgress: (_, __, percent) {
              if (!mounted) return;
              final overallFraction = (i + (percent / 100)) / total;
              setState(() {
                _overallUploadPercent = (overallFraction * 100)
                    .clamp(0, 100)
                    .round();
              });
            },
          );

          await cubit.completeAssetUpload(
            sessionCode: uploadSession.sessionCode,
            assetCode: presign.assetCode,
            documentApiBasePath: uploadSession.documentApiBasePath,
          );
        } catch (_) {
          failedFiles.add(image);
        }
        if (mounted) {
          setState(() {
            _overallUploadPercent = (((i + 1) / total) * 100).round();
          });
        }
      }

      if (!mounted) return;

      final succeededCount = total - failedFiles.length;
      if (failedFiles.isEmpty) {
        Navigator.of(context).pop();
        CoreUtils.showTopSnackBar(
          context: context,
          message: succeededCount == 1
              ? 'Image uploaded to cloud successfully.'
              : '$succeededCount images uploaded to cloud successfully.',
          isSuccess: true,
        );
      } else {
        // Keep only the failed files selected so the user can retry them.
        setState(() {
          _selectedImages
            ..clear()
            ..addAll(failedFiles);
        });
        CoreUtils.showTopSnackBar(
          context: context,
          message: succeededCount > 0
              ? '$succeededCount of $total images uploaded. ${failedFiles.length} failed — please retry.'
              : 'Failed to upload ${failedFiles.length == 1 ? 'image' : 'images'}. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Failed to upload images: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _overallUploadPercent = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _selectedImages.isNotEmpty;
    return Dialog(
      backgroundColor: AppColors.cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Image Uploader',
                      style: AppTextStyles.activityDialogTitle,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: AppColors.primaryColor.withValues(
                        alpha: _isUploading ? 0.3 : 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primaryColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
                child: const Text(
                  'Upload',
                  style: AppTextStyles.activityUploadSectionLabel,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            _GradientChooseMediaButton(
                              enabled: !(_isUploading || _atCapacity),
                              onPressed: _chooseMedia,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Only image files are supported (max $kSchoolCloudUploadMaxImages)',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.activityUploaderHintText,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Selected Images (${_selectedImages.length})',
                        style: AppTextStyles.activitySelectedImagesLabel,
                      ),
                      const SizedBox(height: 10),
                      if (hasImages)
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: _selectedImages
                              .map(
                                (file) => _SelectedImageThumbnail(
                                  file: file,
                                  onRemove: _isUploading
                                      ? null
                                      : () => _removeSelectedImage(file),
                                ),
                              )
                              .toList(),
                        ),
                      if (_isUploading) ...[
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_overallUploadPercent / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 6,
                            backgroundColor: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.themeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Uploading… $_overallUploadPercent%',
                          style: AppTextStyles.activityUploadProgressText,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${_selectedImages.length} file${_selectedImages.length == 1 ? '' : 's'} selected',
                style: AppTextStyles.activitySelectedFilesCaption,
              ),
              const SizedBox(height: 12),
              CustomButtonLayout(
                isForm: false,
                isLoading: _isUploading,
                cancelButtonLabel: 'Cancel',
                confirmButtonLabel: 'Upload',
                onPressedCancel: _isUploading
                    ? null
                    : () => Navigator.of(context).pop(),
                onPressedConfirm: (hasImages && !_isUploading) ? _upload : null,
                disabledConfirmTooltip: hasImages
                    ? null
                    : 'Choose at least one image to upload',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Choose Media" trigger, styled with the app's primary gradient — the same
/// gradient/border-radius treatment as [CustomConfirmButton] — for visual
/// consistency with the app's other primary actions.
class _GradientChooseMediaButton extends StatelessWidget {
  const _GradientChooseMediaButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: enabled ? AppColors.buildPrimaryGradient() : null,
        color: enabled ? null : AppColors.activityDisabledButtonBg,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Choose Media',
              style: AppTextStyles.activityGradientButtonLabel(
                enabled: enabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedImageThumbnail extends StatelessWidget {
  const _SelectedImageThumbnail({required this.file, required this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(file, width: 72, height: 72, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.errorColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.cardColor,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
