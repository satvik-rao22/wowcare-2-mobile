import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class StaffImportantDatesTab extends StatelessWidget {
  const StaffImportantDatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dates = {
      'Joining Date': 'Jan 12, 2022',
      'Last Status Update': 'Sep 05, 2024',
      'Contract Expiry': 'Dec 31, 2025',
      'Verification Due': 'Nov 15, 2024',
    };

    final entries = dates.entries.toList();
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: CustomRefreshIndicator(
        onRefresh: () async {
          // TODO: Add refresh logic to reload important dates
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Important Dates',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.edit,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(entries.length * 2 - 1, (i) {
              if (i.isOdd) return const SizedBox(height: 16);
              final idx = i ~/ 2;
              final e = entries[idx];
              final lowerLabel = e.key.toLowerCase();
              final isCda = lowerLabel.contains('cda');
              final isBackgroundRecord = lowerLabel.contains('background') && lowerLabel.contains('record');
              return _DateRow(
                label: e.key,
                text: e.value,
                showInfo: isCda && !isBackgroundRecord,
                infoText: 'CDA - Child Development Associate',
              );
            }),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text, this.showInfo = false, this.infoText});
  final String label;
  final String text;
  final bool showInfo;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final displayText = (text.trim().isEmpty || text.trim().toLowerCase() == 'no cda') ? '-' : text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showInfo) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final overlay = Overlay.of(context);
                    final renderBox = context.findRenderObject() as RenderBox?;
                    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
                    final size = renderBox?.size ?? const Size(0, 0);

                    final entry = OverlayEntry(
                      builder: (ctx) => Positioned(
                        left: offset.dx - 8,
                        top: offset.dy - 44,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              infoText ?? 'CDA - Child Development Associate',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Manrope'),
                            ),
                          ),
                        ),
                      ),
                    );

                    overlay?.insert(entry);
                    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
                  },
                  child: const Icon(Icons.info_outline, size: 24, color: AppColors.primaryColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


