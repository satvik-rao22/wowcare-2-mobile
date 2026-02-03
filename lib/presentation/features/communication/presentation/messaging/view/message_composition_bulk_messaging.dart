
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:rich_field_controller/rich_field_controller.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../core/util/core_utils.dart';
import '../../../../../../shared/common/widgets/selected_student_tile.dart';

class MessageCompositionBulkMessaging extends StatefulWidget {
  const MessageCompositionBulkMessaging({
    super.key,
    required this.selectedRecipients,
  });
  final List<Map<String, dynamic>> selectedRecipients;

  @override
  State<MessageCompositionBulkMessaging> createState() =>
      _MessageCompositionBulkMessagingState();
}

class _MessageCompositionBulkMessagingState
    extends State<MessageCompositionBulkMessaging> {
  late final List<Map<String,dynamic>> _selectedRecipientsData;
  late final List<String> _selectedRecipientsName;
  final List<SelectedAttachment> _attachments = [];
  late final FocusNode _focusNode ;
  late final RichFieldController _controller ;
  int get _charCount => _controller.text.length;



  static const int maxChars = 2000;
  bool get _canSend => _charCount > 0 || _attachments.isNotEmpty;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    if (await file.length() > 10 * 1024 * 1024) {
      if (!mounted) return;
      _showWarningMessage('File too large (max 10 MB)');
      return;
    }

    setState(() {
      _attachments.add(SelectedAttachment.file(file, isImage: true));
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
    );

    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.single;
    final file = File(platformFile.path!);

    if (await file.length() > 10 * 1024 * 1024) {
      if (!mounted) return;
      _showWarningMessage('File too large (max 10 MB)');
      return;
    }

    setState(() {
      _attachments.add(SelectedAttachment.file(file, isImage: false));
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _removeRecipient(String name) {
    setState(() {
      _selectedRecipientsName.remove(name);

      // If no recipients left, go back to previous screen
      if (_selectedRecipientsName.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = RichFieldController(focusNode: _focusNode);

    _controller.addListener(() => setState(() {}));
    _selectedRecipientsData = List.from(widget.selectedRecipients);
    _selectedRecipientsName = _selectedRecipientsData.map((recipient) => recipient['name'] as String).toList();
    }

  @override
  void dispose(){
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }



  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
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
                  child: Column(
                    children: [
                      SizedBox(height: responsive.verticalSpacing),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CustomTextWidget(text: 'Create Message'),
                        ),
                      ),
                      SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                      Container(
                        width: responsive.containerWidth,
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        padding: EdgeInsets.all(
                          responsive.isTablet ? 32.0 : 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(10),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: responsive.isTablet ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: responsive.isTablet ? 3.8 : 3.0,
                              ),
                              itemCount: _selectedRecipientsName.length,
                              itemBuilder: (context, index) {
                                final String name = _selectedRecipientsName[index];

                                return SelectedStudentTile(
                                  name: name,
                                  onTap: () => _removeRecipient(name),
                                );
                              },
                            ),
                            SizedBox(height: responsive.verticalSpacing,),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryColor.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.format_bold, size: 20),
                                          onPressed: () {
                                            _controller.updateStyle(TextStyle(fontWeight: FontWeight.bold));
                                          },
                                          tooltip: 'Bold',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.format_italic, size: 20),
                                          onPressed: () {
                                            _controller.updateStyle(TextStyle(fontStyle: FontStyle.italic));
                                          },
                                          tooltip: 'Italic',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.format_underlined, size: 20),
                                          onPressed: () {
                                            _controller.updateStyle(TextStyle(decoration: TextDecoration.underline));
                                          },
                                          tooltip: 'Underline',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.format_strikethrough, size: 20),
                                          onPressed: () {
                                            _controller.updateStyle(TextStyle(decoration: TextDecoration.lineThrough));
                                          },
                                          tooltip: 'Strikethrough',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.launch, size: 20),
                                          onPressed: () {
                                            _controller.updateStyle(
                                              const TextStyle(
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline, decorationColor: Colors.blue
                                              ),
                                            );
                                          },
                                          tooltip: 'Format as Link',
                                        ),
                                        const Spacer(),

                                      ],
                                    ),
                                  ),


                                  TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    maxLines: null,
                                    minLines: 5,
                                    maxLength: maxChars,
                                    decoration: const InputDecoration(
                                      hintText:
                                      'Hello Parents, children had a good day today!',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16),
                                      counterText: '',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$_charCount / $maxChars',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _charCount > maxChars
                                      ? Colors.red
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            Row(
                               mainAxisSize: MainAxisSize.max,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.photo_library),
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
                            const SizedBox(height: 10,),
                            if (_attachments.isNotEmpty) ...[
                              const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: List.generate(_attachments.length, (index) {
                                  final att = _attachments[index];
                                  return _buildAttachmentPreview(att, index);
                                }),
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
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
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
                          color: Colors.white,
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
                  if(_canSend){
                    Navigator.of(context).popUntil((route) {
                      return route.settings.name == MessagingScreen.routeName;
                    });
                  } else {
                    CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Please enter your message',
                        isWarning: true
                    );
                    return;
                  }
                },
                style: TextButton.styleFrom(overlayColor: Colors.transparent),
                child: Text(
                  'Send',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: att.isImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              att.file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
            ),
          )
              : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    path.basename(att.file.path),
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _removeAttachment(index),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

}

// Helper class
class SelectedAttachment {
  final File file;
  final bool isImage;

  SelectedAttachment.file(this.file, {required this.isImage});
}


