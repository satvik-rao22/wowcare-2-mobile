import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class StaffDatesTab extends StatelessWidget {
  const StaffDatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.themeColor),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(16),
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Important Dates',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 50),
              const _DateRow(label: 'Hire Date', text: 'Jan 12, 2022'),
              const SizedBox(height: 16),
              const _DateRow(label: 'CDA Examination Date', text: 'Aug 15, 2024'),
              const SizedBox(height: 16),
              const _DateRow(label: 'First Aid / CPR Expiration Date', text: 'Nov 20, 2025'),
              const SizedBox(height: 16),
              const _DateRow(label: 'Background Record Check Expiration Date', text: 'Oct 01, 2026'),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Physical Checkup',
                    style: TextStyle(
                      color: AppColors.primaryColor.withOpacity(0.5),
                      letterSpacing: 14 * (-3 / 100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Completed card
                  _PhysicalCard(
                    statusLabel: 'Completed',
                    statusColor: const Color.fromRGBO(56, 200, 32, 1),
                    statusBg: const Color.fromRGBO(56, 200, 32, 0.1),
                    date: 'Jun 10, 2024',
                  ),
                  // Due/Overdue card
                  _PhysicalCard(
                    statusLabel: 'Due',
                    statusColor: const Color.fromRGBO(234, 186, 0, 1),
                    statusBg: const Color.fromRGBO(234, 186, 0, 0.1),
                    date: 'Jun 10, 2025',
                  ),
                ],
              ),
            ],
          ),
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
          width: 180,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              letterSpacing: 14 * (-3 / 100),
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhysicalCard extends StatelessWidget {
  const _PhysicalCard({
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.date,
  });

  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkup Date',
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  letterSpacing: 14 * (-3 / 100),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


