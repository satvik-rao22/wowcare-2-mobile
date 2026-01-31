import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class StaffDatesTab extends StatelessWidget {
  const StaffDatesTab({super.key, required this.staffCode});

  final String staffCode;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        // TODO: Add refresh logic to reload important dates
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditImportantDatesScreen(
                            staffCode: staffCode,
                            initialHireDate: null, // You can pass actual dates here
                            initialCdaExaminationDate: null,
                            initialFirstAidCprExpirationDate: null,
                            initialBackgroundRecordCheckExpirationDate: null,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _DateRow(label: 'Hire Date', text: 'Nov 09,2022'),
              const SizedBox(height: 16),
              const _DateRow(
                label: 'CDA Examination Date',
                text: 'No CDA Examination Date',
                showInfo: true,
              ),
              const SizedBox(height: 16),
              const _DateRow(
                label: 'First Aid / CPR Expiration Date',
                text: 'First Aid / CPR Expiration Date',
              ),
              const SizedBox(height: 16),
              const _DateRow(
                label: 'Background Record Check Expiration Date',
                text: 'Background Record Check Expiration Date',
                showInfo: false,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Physical Checkup',
                    style: TextStyle(
                      color: AppColors.primaryColor.withOpacity(0.5),
                      fontSize: 16,
                      letterSpacing: 14 * (-3 / 100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Completed card
                  _PhysicalCard(
                    statusLabel: 'Completed',
                    statusColor: const Color.fromRGBO(56, 200, 32, 1),
                    statusBg: const Color.fromRGBO(56, 200, 32, 0.1),
                    date: 'Dec 09 ,2023',
                  ),
                  // Due/Overdue card
                  _PhysicalCard(
                    statusLabel: 'Due',
                    statusColor: const Color.fromRGBO(234, 186, 0, 1),
                    statusBg: const Color.fromRGBO(234, 186, 0, 0.1),
                    date: 'Dec 09 ,2023',
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text, this.showInfo = false});
  final String label;
  final String text;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  fontSize: 16,
                  letterSpacing: 14 * (-3 / 100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Child Development Associate',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: true,
                waitDuration: Duration(milliseconds: 50),
                showDuration: Duration(seconds: 2),
                verticalOffset: 6,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (() {
            final t = text.trim();
            final tl = t.toLowerCase();
            if (t.isEmpty) return '-';
            if (tl.contains('no cda')) return '-';
            if (tl.contains('first aid') || tl.contains('cpr')) return '-';
            if (tl.contains('background record')) return '-';
            return text;
          })(),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
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


