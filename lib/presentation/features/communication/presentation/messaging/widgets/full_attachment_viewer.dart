import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import '../../../../../../domain/features/communication/entities/message.dart';

class FullAttachmentViewer extends StatelessWidget {
  final List<ChatAttachment> attachments;

  const FullAttachmentViewer({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const CustomTextWidget(text: 'Attachments')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final att = attachments[index];
          final source = att.displaySource;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (att.isImage && source != null)
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        att.remoteUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (source != null)
                    Container(
                      height: 160,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 80,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 8),
                            CustomTextWidget(
                              text: 'PDF Preview',
                              fontSize: 16,
                              fontColor: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      color: Colors.white,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextWidget(
                          text: att.name,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        const SizedBox(height: 6),
                        // Row(
                        //   children: [
                        //     Container(
                        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //       decoration: BoxDecoration(
                        //         color: AppColors.themeColor,
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       child: CustomTextWidget(
                        //         text: att.type.toUpperCase(),
                        //         fontSize: 13,
                        //         fontColor: Colors.white,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        // if (att.remoteUrl != null)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 8),
                        //     child: CustomTextWidget(
                        //       text: 'Uploaded • Remote',
                        //       fontSize: 12,
                        //     ),
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
