import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class StaffDocumentsTab extends StatefulWidget {
  const StaffDocumentsTab({super.key});

  @override
  State<StaffDocumentsTab> createState() => _StaffDocumentsTabState();
}

class _StaffDocumentsTabState extends State<StaffDocumentsTab> {
  bool _showExpired = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final docs = <_Doc>[
      _Doc('Offer_Letter.pdf', 'PDF', now.add(const Duration(days: 120))),
      _Doc('ID_Card.png', 'Image', now.subtract(const Duration(days: 10))),
      _Doc('Contract.docx', 'DOC', now.add(const Duration(days: 365))),
    ];

    final filtered = docs.where((d) => _showExpired ? d.expiry.isBefore(now) : !d.expiry.isBefore(now)).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                onToggle: (v) => setState(() => _showExpired = v),
              ),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
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
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final d = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(
                        d.fileNameNoExt,
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
                        _DocRow(label: 'Document Type', text: d.type),
                        const SizedBox(height: 16),
                        _DocRow(
                          label: 'Expiry Date',
                          text: DateFormat('MMM dd, yyyy').format(d.expiry),
                        ),
                        const SizedBox(height: 16),
                        _DocRow(label: 'Document', text: d.fileNameNoExt, trailingIcon: Icons.insert_drive_file_outlined),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Using shared CustomToggle above within a styled container

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

class _Doc {
  _Doc(this.fileName, this.type, this.expiry);
  final String fileName;
  final String type;
  final DateTime expiry;

  String get fileNameNoExt {
    final i = fileName.lastIndexOf('.');
    return i > 0 ? fileName.substring(0, i) : fileName;
  }
}


