import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/features/Student-Module/Student-Module-DataSource/student_data_cubit.dart';
import '../../../domain/features/Student-Module/entities/Student-Entity.dart';
import '../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../shared/common/widgets/custom_shimmer_loader.dart';

class DocumentsTabContent extends StatefulWidget {
  const DocumentsTabContent({required this.student});

  final StudentEntity student;

  @override
  State<DocumentsTabContent> createState() => _DocumentsTabContentState();
}

class _DocumentsTabContentState extends State<DocumentsTabContent> {
  bool _isShowExpiredDocumentsOn = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentDocuments();
  }

  void _fetchStudentDocuments() {
    context.read<StudentDataCubit>().getAllDocuments(
      widget.student.id,
      widget.student.schoolId,
    );
  }

  void _onRefresh() {
    _fetchStudentDocuments();
  }

  DateTime _parseExpiryDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now().add(const Duration(days: 1));
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  String _removeFileExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isShowExpiredDocumentsOn = !_isShowExpiredDocumentsOn;
              });
            },
            child: Container(
              width: 58,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: _isShowExpiredDocumentsOn
                    ? null
                    : LinearGradient(
                        colors: [Colors.blue, Colors.blue[700]!],
                      ).withOpacity(0.4),
                color: _isShowExpiredDocumentsOn ? Colors.green[600] : null,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: _isShowExpiredDocumentsOn ? 26 : 2,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Show Expired Documents",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: ShimmerLoader(height: 60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async => _onRefresh(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildToggleCard(),
            const SizedBox(height: 16),
            BlocConsumer<StudentDataCubit, StudentDataState>(
              listener: (context, state) {
                if (state is DocumentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Document Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (state is GettingAllDocuments) {
                  return _buildShimmerLoading();
                }
                if (state is DocumentError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error in Fetching Documents',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStudentDocuments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AllDocumentsLoaded) {
                  final today = DateTime.now();
                  final todayDate = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  );

                  final filteredDocuments = state.documents.where((doc) {
                    final expiryDate = _parseExpiryDate(doc!.expiryDate);
                    final expiryDateOnly = DateTime(
                      expiryDate.year,
                      expiryDate.month,
                      expiryDate.day,
                    );

                    if (_isShowExpiredDocumentsOn) {
                      return expiryDateOnly.isBefore(todayDate);
                    } else {
                      return expiryDateOnly.isAtSameMomentAs(todayDate) ||
                          expiryDateOnly.isAfter(todayDate);
                    }
                  }).toList();

                  return filteredDocuments.isEmpty
                      ? Text(
                          _isShowExpiredDocumentsOn
                              ? 'No expired documents found'
                              : 'No documents found',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredDocuments.length,
                          itemBuilder: (context, index) {
                            final document = filteredDocuments[index];
                            final expiryDate = _parseExpiryDate(
                              document.expiryDate,
                            );
                            final formattedExpiryDate = DateFormat(
                              'MMM dd, yyyy',
                            ).format(expiryDate);
                            final displayFileName = _removeFileExtension(
                              document.name.isNotEmpty
                                  ? document.name
                                  : 'Unknown',
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                title: Text(
                                  displayFileName,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                collapsedBackgroundColor: Colors.white,
                                collapsedShape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                children: [
                                  Divider(color: Colors.blue.withOpacity(0.1)),
                                  const SizedBox(height: 16),
                                  _buildDocumentsField(
                                    label: 'Document Type',
                                    text: 'Unknown',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDocumentsField(
                                    label: 'Expiry Date',
                                    text: formattedExpiryDate,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDocumentsField(
                                    label: 'Document',
                                    text: displayFileName,
                                    isDocumentField: true,
                                    documentId: document.documentId,
                                    fileName: document.name,
                                    onDocumentTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Opening ${document.name}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                }
                return const Text(
                  'Unexpected Error',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

extension on Object {
  String? get expiryDate => null;
}

String _getFileExtension(String fileName) {
  final lastDotIndex = fileName.lastIndexOf('.');
  if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }
  return '';
}

IconData _getDocumentIcon(String fileName) {
  final extension = _getFileExtension(fileName);
  const imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'svg',
    'tiff',
    'ico',
  ];
  const pdfExtensions = ['pdf'];
  const docExtensions = ['doc', 'docx', 'txt', 'rtf'];
  const excelExtensions = ['xls', 'xlsx', 'csv'];
  const presentationExtensions = ['ppt', 'pptx'];

  if (imageExtensions.contains(extension)) {
    return Icons.image_outlined;
  } else if (pdfExtensions.contains(extension)) {
    return Icons.picture_as_pdf_outlined;
  } else if (docExtensions.contains(extension)) {
    return Icons.description_outlined;
  } else if (excelExtensions.contains(extension)) {
    return Icons.table_chart_outlined;
  } else if (presentationExtensions.contains(extension)) {
    return Icons.slideshow_outlined;
  } else {
    return Icons.insert_drive_file_outlined;
  }
}

Widget _buildDocumentsField({
  required String label,
  required String text,
  bool isDocumentField = false,
  String? documentId,
  String? fileName,
  bool isLoading = false,
  VoidCallback? onDocumentTap,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Tooltip(
              message: label,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.blue.withOpacity(0.5),
                  letterSpacing: 14 * (-3 / 100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      const SizedBox(width: 16),
      if (!isDocumentField)
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      if (isDocumentField && isLoading)
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        ),
      if (isDocumentField && !isLoading)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onDocumentTap,
            child: Icon(
              fileName != null
                  ? _getDocumentIcon(fileName)
                  : Icons.insert_drive_file_outlined,
              color: Colors.blue,
            ),
          ),
        ),
    ],
  );
}
