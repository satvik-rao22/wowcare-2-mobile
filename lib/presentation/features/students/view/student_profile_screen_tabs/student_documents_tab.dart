import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class StudentDocumentsTab extends StatefulWidget {
  const StudentDocumentsTab({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;

  @override
  State<StudentDocumentsTab> createState() => _StudentDocumentsTabState();
}

class _StudentDocumentsTabState extends State<StudentDocumentsTab> {
  bool _showExpired = false;

  // Sample data - replace with actual data source
  // Using date format that matches staff version (yyyy-MM-dd for parsing)
  final List<Map<String, String>> _documents = [
    {
      'documentName': 'Project_Proposal_ABC_Corp_2025',
      'documentType': 'Registration Forms',
      'expiryDate': '2025-11-29',
    },
    {
      'documentName': 'Annual_Report_2025_Financial_Performance',
      'documentType': 'Registration Forms',
      'expiryDate': '2025-11-29',
    },
    {
      'documentName': 'Machine_Learning_Paper_Results_2025',
      'documentType': 'Registration Forms',
      'expiryDate': '2025-11-29',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        // TODO: Add refresh logic to reload documents
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: CustomToggle(
                  label: 'Show Expired Documents',
                  isToggled: _showExpired,
                  onToggle: (v) {
                    setState(() => _showExpired = v);
                    // TODO: Add filter logic
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_documents.isEmpty)
                Text(
                  _showExpired ? 'No expired documents found' : 'No documents found',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 16,
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _documents.length,
                  itemBuilder: (context, i) {
                    final doc = _documents[i];
                    final expiryDate = DateFormat('yyyy-MM-dd').parse(doc['expiryDate']!);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          doc['documentName']!,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: const SizedBox.shrink(),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        collapsedShape: RoundedRectangleBorder(
                          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Divider(color: AppColors.primaryColor.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          _DocRow(label: 'Document Type', text: doc['documentType']!),
                          const SizedBox(height: 16),
                          _DocRow(
                            label: 'Expiry Date',
                            text: DateFormat('MMM dd, yyyy').format(expiryDate),
                          ),
                          const SizedBox(height: 16),
                          _DocRow(label: 'Document', text: doc['documentName']!, trailingIcon: Icons.insert_drive_file_outlined),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.text, this.trailingIcon});
  final String label;
  final String text;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              letterSpacing: 14 * (-3 / 100),
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (trailingIcon == null)
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
          )
        else
          SvgPicture.asset(
            MediaRes.documents_drawer_Icon,
            height: 20,
            // colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
          ),
      ],
    );
  }
}
