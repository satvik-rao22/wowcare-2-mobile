import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/students/view/add_document_screen.dart';

class StudentDocumentsTab extends StatefulWidget {
  const StudentDocumentsTab({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  @override
  State<StudentDocumentsTab> createState() => _StudentDocumentsTabState();
}

class _StudentDocumentsTabState extends State<StudentDocumentsTab> {
  bool _showExpired = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  Future<void> _refreshDocuments() async {
    // TODO: Replace with real API integration (student documents endpoint)
    // For now, trigger a rebuild so pull-to-refresh feels functional.
    setState(() {});
  }

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
    if (_isLoading && _documents.isEmpty) {
      return const Center(child: PrimaryCircularLoader());
    }

    final documents = _documents;

    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: _refreshDocuments,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Only trigger on actual scroll updates, not on initial layout
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                // TODO: Load next page if hasMore
              }
            }
            return false;
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
                      border: Border.all(color: AppColors.cardBorderColor, width: 1),
                      borderRadius: BorderRadius.circular(12),
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
                  if (documents.isEmpty)
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
                      itemCount: documents.length,
                      itemBuilder: (context, i) {
                        final doc = documents[i];
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
                              side: BorderSide(
                                color: AppColors.cardBorderColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: AppColors.cardBorderColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
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
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: PrimaryCircularLoader(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: GradientAddButton(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddStudentDocumentScreen(
                studentCode: widget.studentCode ?? '',
              ),
            ),
          ).then((result) {
            if (result == true && mounted) {
              // TODO: Refresh documents list
              setState(() {
                // Trigger refresh
              });
            }
          });
        },
        size: 50.0,
        iconSize: 28.0,
        borderRadius: 12.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              fontSize: 14,
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
