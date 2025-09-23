import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(entries.length * 2 - 1, (i) {
            if (i.isOdd) return const SizedBox(height: 16);
            final idx = i ~/ 2;
            final e = entries[idx];
            return _DateRow(label: e.key, text: e.value);
          }),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
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
          child: Text(
            text,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}


