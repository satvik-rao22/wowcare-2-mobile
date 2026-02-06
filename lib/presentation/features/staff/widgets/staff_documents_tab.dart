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
import 'package:wowcare/presentation/features/staff/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class StaffDocumentsTab extends StatefulWidget {
  const StaffDocumentsTab({
    super.key,
    required this.staffCode,
  });

  final String staffCode;

  @override
  State<StaffDocumentsTab> createState() => _StaffDocumentsTabState();
}

class _StaffDocumentsTabState extends State<StaffDocumentsTab> {
  bool _showExpired = false;
  late final StaffDocumentsListCubit _documentsListCubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _documentsListCubit = serviceLocator<StaffDocumentsListCubit>()
      ..loadInitial(widget.staffCode, expired: _showExpired ? true : null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _documentsListCubit.close();
    super.dispose();
  }

  Future<void> _handleEdit(BuildContext context, StaffDocument doc) async {
    if (doc.documentUuid == null || doc.documentUuid!.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Document UUID not available',
        isError: true,
      );
      return;
    }

    final expiryDate = DateFormat('yyyy-MM-dd').parse(doc.expiryDate);
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<StaffDocumentCubit>(
          create: (_) => serviceLocator<StaffDocumentCubit>(),
          child: AddDocumentScreen(
            staffCode: widget.staffCode,
            isEdit: true,
            documentUuid: doc.documentUuid,
            initialDocumentName: doc.documentName,
            initialDocumentType: doc.documentType,
            initialExpiryDate: expiryDate,
            initialFilePath: doc.documentUrl,
            initialMimeType: doc.mimeType,
            initialFileSizeKb: doc.documentSizeKb,
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      _documentsListCubit.refresh(
        widget.staffCode,
        expired: _showExpired ? true : null,
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, StaffDocument doc) async {
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
                  message: 'Document UUID not available',
                  isError: true,
                );
                return;
              }

              final errorMessage = await _documentsListCubit.deleteDocument(
                widget.staffCode,
                doc.documentUuid!,
              );

              Navigator.of(ctx).pop();
              if (!mounted) return;

              if (errorMessage != null) {
                // Show error message
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: errorMessage,
                  isError: true,
                );
              } else {
                // Success - list already refreshed in cubit
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

  Future<void> _handleDownload(BuildContext context, StaffDocument doc) async {
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
        message: 'Error downloading document: ${e.toString()}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffDocumentsListCubit>.value(
      value: _documentsListCubit,
      child: Scaffold(
          body: BlocBuilder<StaffDocumentsListCubit, StaffDocumentsListState>(
            builder: (context, state) {
              if (state.isLoading && state.documents.isEmpty) {
                return const Center(child: PrimaryCircularLoader());
              }

              // Use documents directly from API - no frontend filtering
              final documents = state.documents;

              return CustomRefreshIndicator(
                onRefresh: () async {
                  await _documentsListCubit.refresh(
                    widget.staffCode,
                    expired: _showExpired ? true : null,
                  );
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Only trigger on actual scroll updates, not on initial layout
                    if (notification is ScrollUpdateNotification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                        final state = _documentsListCubit.state;
                        if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
                          _documentsListCubit.loadNextPage(
                            widget.staffCode,
                            expired: _showExpired ? true : null,
                          );
                        }
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
              // Call API with the new filter
              _documentsListCubit.refresh(
                widget.staffCode,
                expired: v ? true : null,
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
                                    _DocRow(label: 'Document Type', text: doc.documentType),
                                    const SizedBox(height: 16),
                                    _DocRow(
                                      label: 'Expiry Date',
                                      text: DateFormat('MMM dd, yyyy').format(expiryDate),
                                    ),
                                    const SizedBox(height: 16),
                                    _DocRow(label: 'Document', text: doc.documentName, trailingIcon: Icons.insert_drive_file_outlined),
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
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
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
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider<StaffDocumentCubit>(
                    create: (_) => serviceLocator<StaffDocumentCubit>(),
                    child: AddDocumentScreen(
                      staffCode: widget.staffCode,
                    ),
                  ),
                ),
              ).then((result) {
                // Refresh documents list after successfully adding a new document
                // Cache is already invalidated in repository, so this will fetch fresh data
                if (result == true && mounted) {
                  _documentsListCubit.refresh(
                    widget.staffCode,
                    expired: _showExpired ? true : null,
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


