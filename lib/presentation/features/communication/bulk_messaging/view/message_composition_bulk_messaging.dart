import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/cubit/bulk_messaging_composition_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/rich_text_toolbar.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/html_aware_text_controller.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../shared/common/widgets/selected_student_tile.dart';
import '../../../../../app/di/di.dart';

class MessageCompositionBulkMessaging extends StatefulWidget {
  const MessageCompositionBulkMessaging({
    super.key,
    required this.selectedRecipients,
    required this.isStaff,
    this.conversationType = 'ROOM_CHAT',
  });
  final List<Map<String, dynamic>> selectedRecipients;
  final bool isStaff;
  final String conversationType;

  @override
  State<MessageCompositionBulkMessaging> createState() =>
      _MessageCompositionBulkMessagingState();
}

class _MessageCompositionBulkMessagingState
    extends State<MessageCompositionBulkMessaging> {
  late final BulkMessagingCompositionCubit _compositionCubit;
  late final FocusNode _focusNode;
  late final HtmlAwareTextController _controller;

  static const int maxChars = 2000;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final valid = <File>[];
    var anyTooLarge = false;
    for (final xfile in picked) {
      final file = File(xfile.path);
      if (await file.length() > 10 * 1024 * 1024) {
        anyTooLarge = true;
        continue;
      }
      valid.add(file);
    }

    if (!mounted) return;
    if (anyTooLarge) {
      _showWarningMessage(
        valid.isEmpty
            ? 'File too large (max 10 MB)'
            : 'Some files were skipped (max 10 MB each)',
      );
    }
    if (valid.isEmpty) return;
    _compositionCubit.addAttachments(valid, isImage: true);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FilePickerUtils.allowedDocumentExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final valid = <File>[];
    var anyTooLarge = false;
    for (final platformFile in result.files) {
      final path = platformFile.path;
      if (path == null) continue;
      final file = File(path);
      if (await file.length() > 10 * 1024 * 1024) {
        anyTooLarge = true;
        continue;
      }
      valid.add(file);
    }

    if (!mounted) return;
    if (anyTooLarge) {
      _showWarningMessage(
        valid.isEmpty
            ? 'File too large (max 10 MB)'
            : 'Some files were skipped (max 10 MB each)',
      );
    }
    if (valid.isEmpty) return;
    _compositionCubit.addAttachments(valid, isImage: false);
  }

  void _removeAttachment(int index) {
    _compositionCubit.removeAttachmentAt(index);
  }

  void _removeRecipient(String name) {
    _compositionCubit.removeRecipientByName(name);
    if (_compositionCubit.state.selectedRecipientNames.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onTextChanged() {
    if (!_compositionCubit.isClosed) {
      _compositionCubit.updateMessageText(_controller.text);
    }
  }

  @override
  void initState() {
    super.initState();
    _compositionCubit = BulkMessagingCompositionCubit(
      initialRecipients: widget.selectedRecipients,
      isStaff: widget.isStaff,
      conversationType: widget.conversationType,
      createOrOpenConversationUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      attachmentUploader: serviceLocator(),
      storageService: serviceLocator(),
      cacheMessageUseCase: serviceLocator(),
      discardCachedMessageUseCase: serviceLocator(),
      cacheDraftMessageUseCase: serviceLocator(),
    );
    _focusNode = FocusNode();
    _controller = HtmlAwareTextController();

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _compositionCubit.close();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return BlocProvider.value(
      value: _compositionCubit,
      child: BlocBuilder<BulkMessagingCompositionCubit, BulkMessagingCompositionState>(
        builder: (context, compositionState) {
          return Scaffold(
            backgroundColor: AppColors.white,
            resizeToAvoidBottomInset: true,
            appBar: const CustomAppBar(hasBackButton: true),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: BlocListener<BulkMessagingCompositionCubit, BulkMessagingCompositionState>(
                listener: (context, state) {
                  if (!context.mounted) return;
                  if (state.isBulkStarted) {
                    // Navigate back immediately — bulk job runs in background.
                    final nav = Navigator.of(context);
                    if (nav.canPop()) nav.pop(); // pop composition → selection
                    if (nav.canPop()) nav.pop(); // pop selection → MessagingTab
                    CoreUtils.showTopSnackBar(
                      context: context,
                      isSuccess: true,
                      message:
                          'Bulk message is being processed in the background.',
                    );
                  } else if (state.errorMessage != null) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: state.errorMessage!,
                      isWarning: true,
                    );
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.buildScaffoldGradient(),
                        ),
                        child: Image.asset(
                          MediaRes.wowcareMobileBg,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              children: [
                                SizedBox(height: responsive.verticalSpacing),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.horizontalSpacing,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CustomTextWidget(
                                      text: 'Create Message',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: responsive.isTablet ? 32.0 : 20.0,
                                ),
                                Container(
                                  width: responsive.containerWidth,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: responsive.horizontalSpacing,
                                  ),
                                  padding: EdgeInsets.all(
                                    responsive.isTablet ? 32.0 : 16.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(
                                        responsive.isTablet ? 30.0 : 20.0,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      GridView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.all(10),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount:
                                                  responsive.isTablet ? 3 : 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio:
                                                  responsive.isTablet
                                                  ? 3.8
                                                  : 3.0,
                                            ),
                                        itemCount: compositionState
                                            .selectedRecipientNames
                                            .length,
                                        itemBuilder: (context, index) {
                                          final String name = compositionState
                                              .selectedRecipientNames[index];
                                          final avatar =
                                              index <
                                                  compositionState
                                                      .selectedRecipients
                                                      .length
                                              ? compositionState
                                                        .selectedRecipients[index]['avatar']
                                                    as String?
                                              : null;

                                          return SelectedStudentTile(
                                            name: name,
                                            avatarUrl: avatar,
                                            onTap: () => _removeRecipient(name),
                                          );
                                        },
                                      ),
                                      SizedBox(
                                        height: responsive.verticalSpacing,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.primaryColor
                                                .withValues(alpha: 0.4),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: AppColors.white,
                                        ),
                                        child: Column(
                                          children: [
                                            // Same persistent formatting
                                            // toolbar as the 1:1 chat
                                            // composer (ChatInputBar) —
                                            // wraps the selection/cursor in
                                            // the same <b>/<i>/<u>/<s> tags
                                            // MessageContentProcessor.enrich
                                            // renders on the recipient side,
                                            // unlike the previous
                                            // RichFieldController.updateStyle
                                            // calls, which only restyled the
                                            // field visually and never
                                            // touched the plain text this
                                            // screen actually sends.
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(11),
                                                  ),
                                              child: RichTextToolbar(
                                                controller: _controller,
                                              ),
                                            ),
                                            TextField(
                                              controller: _controller,
                                              focusNode: _focusNode,
                                              maxLines: null,
                                              minLines: 5,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              // Copy/Cut/Paste/Select All that
                                              // work against the plain text
                                              // (tags stripped), matching the
                                              // 1:1 chat composer.
                                              contextMenuBuilder:
                                                  (
                                                    context,
                                                    editableTextState,
                                                  ) =>
                                                      HtmlAwareTextSelectionControls.buildContextMenu(
                                                        context,
                                                        editableTextState,
                                                        _controller,
                                                      ),
                                              maxLength: maxChars,
                                              decoration: const InputDecoration(
                                                hintText: 'Type a message…',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.all(
                                                  16,
                                                ),
                                                counterText: '',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${compositionState.charCount} / $maxChars',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                compositionState.charCount >
                                                    maxChars
                                                ? AppColors.red
                                                : AppColors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.photo_library,
                                            ),
                                            onPressed: _pickImage,
                                            tooltip: 'Add Photo',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.attach_file),
                                            onPressed: _pickFile,
                                            tooltip: 'Attach File',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (compositionState
                                          .attachments
                                          .isNotEmpty) ...[
                                        const Text(
                                          'Attachments',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: List.generate(
                                            compositionState.attachments.length,
                                            (index) {
                                              final att = compositionState
                                                  .attachments[index];
                                              return _buildAttachmentPreview(
                                                att,
                                                index,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                    ),
                  ],
                ),
              ),
            ), // GestureDetector
            bottomNavigationBar: _buildBottomBar(
              context,
              responsive,
              compositionState,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ResponsiveHelper responsive,
    BulkMessagingCompositionState compositionState,
  ) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: AppColors.transparent,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.buildPrimaryGradient().createShader(
                          bounds,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  if (compositionState.canSend) {
                    _compositionCubit.sendMessages(context);
                  } else if (!compositionState.isLoading) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Please enter your message',
                      isWarning: true,
                    );
                  }
                },
                style: TextButton.styleFrom(
                  overlayColor: AppColors.transparent,
                ),
                child: Text(
                  'Send',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(SelectedAttachment att, int index) {
    const double previewSize = 100;

    return Stack(
      children: [
        Container(
          width: previewSize,
          height: previewSize,
          decoration: BoxDecoration(
            //border: Border.all(color: AppColors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Thumbnail(
              mimeType:
                  lookupMimeType(att.file.path) ?? 'application/octet-stream',
              dataResolver: () async {
                return await att.file.readAsBytes();
              },
              widgetSize: previewSize,
              decoration: WidgetDecoration(
                backgroundColor: AppColors.white,
                iconColor: AppColors.primaryColor,
                textColor: AppColors.primaryColor,
                wrapperBgColor: AppColors.transparent,
                //wrapperSize: 84,
              ),
              errorBuilder: (context, error) => Container(
                color: AppColors.grey[200],
                child: Center(
                  child: Icon(
                    att.isImage ? Icons.image : Icons.picture_as_pdf,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            // child: Image.file(
            //   att.file,
            //   fit: BoxFit.cover,
            //   errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
            // ),
          ),
          //     : Center(
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       const Icon(Icons.picture_as_pdf, size: 40, color: AppColors.red),
          //       const SizedBox(height: 4),
          //       Padding(
          //         padding: const EdgeInsets.symmetric(horizontal: 4),
          //         child: Text(
          //           path.basename(att.file.path),
          //           style: const TextStyle(fontSize: 11),
          //           textAlign: TextAlign.center,
          //           maxLines: 2,
          //           overflow: TextOverflow.ellipsis,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ),

        // Remove button
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeAttachment(index),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.red,
              child: const Icon(Icons.close, size: 14, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
