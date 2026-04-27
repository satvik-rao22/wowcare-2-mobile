import 'package:flutter/material.dart';
import '../../../../../../shared/common/widgets/custom_text_widget.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';

class MessagingHeader extends StatelessWidget {
  final Map<String, dynamic> staffInfo;

  const MessagingHeader({super.key, required this.staffInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                DocumentImageWidget(
                  fileUuid: staffInfo['avatar'],
                  name: staffInfo['name'],
                  size: 45,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: staffInfo['isSigned']
                          ? const Color.fromRGBO(0, 177, 21, 1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: staffInfo['isSigned']
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: CustomTextWidget(
                text: staffInfo['name'],
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
