import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/students/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/students/cubit/student_documents_list_cubit.dart';
import 'package:wowcare/domain/features/student/entities/student_document.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class StudentDocumentsTab extends StatefulWidget {
  const StudentDocumentsTab({
    super.key,
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
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
  late final StudentDocumentsListCubit _documentsListCubit;

  @override
  void initState() {
    super.initState();
    _documentsListCubit = serviceLocator<StudentDocumentsListCubit>();
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isNotEmpty) {
      _documentsListCubit.loadInitial(
        studentCode,
        expiredOnly: _showExpired ? true : null,
      );
    }
  }

  @override
  void dispose() {
    _documentsListCubit.close();
    super.dispose();
  }

  Future<void> _handleEdit(BuildContext context, StudentDocument doc) async {
    if (doc.documentUuid == null || doc.documentUuid!.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Document ID not available',
        isError: true,
      );
      return;
    }

    final expiryDate = (doc.expiryDate.trim().isEmpty)
        ? null
        : DateFormat('yyyy-MM-dd').parse(doc.expiryDate);

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddStudentDocumentScreen(
          studentCode: widget.studentCode ?? '',
          isEdit: true,
          initialDocumentName: doc.documentName,
          initialDocumentType: doc.documentType,
          initialExpiryDate: expiryDate,
          initialFilePath: doc.documentUrl,
          documentUuid: doc.documentUuid,
        ),
      ),
    );

    if (result == true && mounted) {
      _documentsListCubit.refresh(
        widget.studentCode ?? '',
        expiredOnly: _showExpired ? true : null,
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, StudentDocument doc) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DeleteConfirmationBottomSheet(
          name: doc.documentName,
          type: 'document',
          onDelete: () async {
            try {
              if (doc.documentUuid == null || doc.documentUuid!.isEmpty) {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Document ID not available',
                  isError: true,
                );
                return;
              }

              final errorMessage = await _documentsListCubit.deleteDocument(
                widget.studentCode ?? '',
                doc.documentUuid!,
              );

              Navigator.of(ctx).pop();
              if (!mounted) return;

              if (errorMessage != null) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: errorMessage,
                  isError: true,
                );
              } else {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Document deleted successfully',
                  isSuccess: true,
                );
              }
            } catch (e) {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              final message = ApiErrorHandler.extractErrorMessage(e);
              CoreUtils.showTopSnackBar(
                context: context,
                message: message,
                isError: true,
              );
            }
          },
          onCancel: () {
            Navigator.of(ctx).pop();
          },
        );
      },
    );
  }

  Future<void> _handleDownload(BuildContext context, StudentDocument doc) async {
    if (doc.documentUrl.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Document URL not available',
        isError: true,
      );
      return;
    }

    try {
      final uri = Uri.parse(doc.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Could not open document',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Error downloading document: ${ApiErrorHandler.extractErrorMessage(e)}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      return const Center(
        child: Text(
          'Student code is required to load documents',
          style: TextStyle(color: AppColors.primaryColor, fontSize: 16),
        ),
      );
    }

    return BlocProvider<StudentDocumentsListCubit>.value(
      value: _documentsListCubit,
      child: Scaffold(
        body: BlocBuilder<StudentDocumentsListCubit, StudentDocumentsListState>(
          builder: (context, state) {
            if (state.isLoading && state.documents.isEmpty) {
              return const Center(child: PrimaryCircularLoader());
            }

            final documents = state.documents;

            return CustomRefreshIndicator(
              onRefresh: () async {
                await _documentsListCubit.refresh(
                  studentCode,
                  expiredOnly: _showExpired ? true : null,
                );
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                      final s = _documentsListCubit.state;
                      if (!s.isLoading && !s.isLoadingMore && s.hasMore) {
                        _documentsListCubit.loadNextPage(
                          studentCode,
                          expiredOnly: _showExpired ? true : null,
                        );
                      }
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
                              _documentsListCubit.refresh(
                                studentCode,
                                expiredOnly: v ? true : null,
                              );
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
                              final expiryDate = DateFormat('yyyy-MM-dd').parse(doc.expiryDate);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ExpansionTile(
                                  title: Text(
                                    doc.documentName,
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
                                    _DocRow(label: 'Document Type', text: doc.documentType),
                                    const SizedBox(height: 16),
                                    _DocRow(
                                      label: 'Expiry Date',
                                      text: DateFormat('MMM dd, yyyy').format(expiryDate),
                                    ),
                                    const SizedBox(height: 16),
                                    _DocRow(
                                      label: 'Document',
                                      text: doc.documentName,
                                      trailingIcon: Icons.insert_drive_file_outlined,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              gradient: AppColors.buildPrimaryGradient(),
                                            ),
                                            child: TextButton(
                                              onPressed: () => _handleEdit(context, doc),
                                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                              child: const Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 16 / 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: () => _handleDelete(context, doc),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF6C7FD8)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF6C7FD8),
                                                  height: 16 / 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              gradient: AppColors.buildPrimaryGradient(),
                                            ),
                                            child: TextButton(
                                              onPressed: () => _handleDownload(context, doc),
                                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                              child: const Text(
                                                'Download',
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  height: 16 / 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PrimaryCircularLoader(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: GradientAddButton(
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => AddStudentDocumentScreen(
                      studentCode: widget.studentCode ?? '',
                    ),
                  ),
                )
                .then((result) {
              if (result == true && mounted) {
                _documentsListCubit.refresh(
                  studentCode,
                  expiredOnly: _showExpired ? true : null,
                );
              }
            });
          },
          size: 50.0,
          iconSize: 28.0,
          borderRadius: 12.0,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          ),
      ],
    );
  }
}
