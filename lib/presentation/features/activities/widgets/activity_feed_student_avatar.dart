import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/fonts.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

/// Bottom sheet listing students on an activity card (tap initials stack).
Future<void> showActivityStudentListSheet(
  BuildContext context,
  List<String> studentNames,
) async {
  final names = studentNames
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (names.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 4, 12),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Student',
                          style: TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Color(0xff573353)),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: names.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = names[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            DocumentImageWidget(
                              fileUuid: '',
                              name: n,
                              size: 40,
                              fontSize: 14,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                n,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff573353),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Overlapping student circles (initials) for activity feed cards.
Widget activityFeedStudentAvatarStack(
  List<String> students, {
  VoidCallback? onOpenStudentList,
}) {
  if (students.isEmpty) {
    return const SizedBox(height: 32);
  }
  const size = 28.0;
  final overlap = students.length >= 2 ? 16.0 : 20.0;
  const maxShow = 4;
  final stack = SizedBox(
    height: 32,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < students.length && i < maxShow; i++)
          Positioned(
            left: i * overlap,
            child: DocumentImageWidget(
              fileUuid: '',
              name: students[i],
              size: size,
              fontSize: 10,
            ),
          ),
        if (students.length > maxShow)
          Positioned(
            left: maxShow * overlap,
            child: Tooltip(
              message: students.skip(maxShow).join(', '),
              child: DocumentImageWidget(
                fileUuid: '',
                name: '+${students.length - maxShow}',
                size: size,
                fontSize: 10,
              ),
            ),
          ),
      ],
    ),
  );
  if (onOpenStudentList == null) return stack;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onOpenStudentList,
      borderRadius: BorderRadius.circular(24),
      child: stack,
    ),
  );
}
