import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/view/document_viewer_screen.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_documents_list_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_document.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/router/app_routes.dart' show StaffRoutes;
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';

class StaffDocumentsTab extends StatelessWidget {
  const StaffDocumentsTab({
    super.key,
    required this.staffCode,
    this.canEdit = false,
    this.highlightCode,
  });

  final String staffCode;

  /// Whether the current persona may add/edit/delete documents (resolved by
  /// the parent screen: Admin always, staff only on their own profile).
  final bool canEdit;

  /// Document code (== API `code`/documentUuid) from a notification deep-link;
  /// the matching document card scrolls into view, expands, and flashes.
  final String? highlightCode;

  @override
  Widget build(BuildContext context) {
    // Cubits are created by the route builder (§1.6), not here.
    return _StaffDocumentsTabView(
      staffCode: staffCode,
      canEdit: canEdit,
      highlightCode: highlightCode,
    );
  }
}

class _StaffDocumentsTabView extends StatefulWidget {
  const _StaffDocumentsTabView({
    required this.staffCode,
    this.canEdit = false,
    this.highlightCode,
  });

  final String staffCode;
  final bool canEdit;
  final String? highlightCode;

  @override
  State<_StaffDocumentsTabView> createState() => _StaffDocumentsTabViewState();
}

class _StaffDocumentsTabViewState extends State<_StaffDocumentsTabView> {
  bool _showExpired = false;
  bool _isDownloadingDoc = false;

  /// Notification deep-link target document row.
  final GlobalKey _highlightRowKey = GlobalKey();
  bool _isHighlightTarget(String? code) {
    final target = (widget.highlightCode ?? '').trim();
    final c = (code ?? '').trim();
    return target.isNotEmpty && c.toUpperCase() == target.toUpperCase();
  }

  late final StaffDocumentsListCubit _documentsListCubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _documentsListCubit = context.read<StaffDocumentsListCubit>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _isResolvingViewUrl.dispose();
    super.dispose();
  }

  String _formatIsoDate(String? iso) {
    final raw = (iso ?? '').trim();
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatExpiryDate(String? expiryDate) {
    final raw = (expiryDate ?? '').trim();
    if (raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      // Sometimes expiryDate is "yyyy-MM-dd" (still parseable), fallback to raw.
      return raw;
    }
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

    final expiryDate =
        (doc.expiryDate == null || doc.expiryDate!.trim().isEmpty)
        ? null
        : DateFormat('yyyy-MM-dd').parse(doc.expiryDate!);

    final result = await context.push<bool>(
      StaffRoutes.documentForm,
      extra: StaffDocumentFormArgs(
        staffCode: widget.staffCode,
        isEdit: true,
        documentUuid: doc.documentUuid,
        initialDocumentName: doc.documentName,
        initialDocumentType: doc.documentType,
        initialExpiryDate: expiryDate,
        initialFilePath: doc.documentUrl,
        initialMimeType: doc.mimeType,
        initialFileSizeKb: doc.documentSizeKb,
        initialDocumentNotes: doc.documentNotes,
        initialAssetCode: doc.assetCode,
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
      backgroundColor: AppColors.transparentColor,
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

  /// `documentUrl` from the API is just a file name (e.g. "photo.webp"), not a
  /// link — resolve the downloadable URL from the asset code.
  Future<String> _resolveDocumentUrl(StaffDocument doc) async {
    final assetCode = (doc.assetCode ?? '').trim();
    final rawUrl = doc.documentUrl.trim();
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (assetCode.isNotEmpty) {
      return _documentsListCubit.resolveMediaAssetUrl(assetCode);
    }
    return '';
  }

  final ValueNotifier<bool> _isResolvingViewUrl = ValueNotifier<bool>(false);

  Future<void> _handleView(BuildContext context, StaffDocument doc) async {
    if (_isResolvingViewUrl.value) return;
    _isResolvingViewUrl.value = true;
    try {
      final url = await _resolveDocumentUrl(doc);
      // Do NOT log the resolved URL (a pre-signed document-access link) or the
      // document name (PII); only non-sensitive metadata + whether it resolved.
      AppLogger.d(
        '[StaffDocumentsTab] _handleView mimeType=${doc.mimeType} '
        'resolved=${url.isNotEmpty}',
      );
      if (!mounted) return;
      if (url.isEmpty || Uri.tryParse(url) == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Document link not available',
          isError: true,
        );
        return;
      }
      context.push(
        StaffRoutes.documentViewer,
        extra: DocumentViewerArgs(
          url: url,
          documentName: doc.documentName,
          mimeType: doc.mimeType,
        ),
      );
    } catch (e, st) {
      AppLogger.e('[StaffDocumentsTab] _handleView failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) _isResolvingViewUrl.value = false;
    }
  }

  Future<void> _handleDownload(BuildContext context, StaffDocument doc) async {
    if (_isDownloadingDoc) return;

    _isDownloadingDoc = true;
    try {
      final url = await _resolveDocumentUrl(doc);
      if (!mounted) return;
      if (url.isEmpty || Uri.tryParse(url) == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Document link not available',
          isError: true,
        );
        return;
      }

      final mime = doc.mimeType.toLowerCase();
      final isVideo = mime.startsWith('video/');
      final isImage = mime.startsWith('image/');

      // Images/videos save to the device gallery (same as the photo activity).
      if (isImage || isVideo) {
        if (!await Gal.hasAccess(toAlbum: true)) {
          await Gal.requestAccess(toAlbum: true);
        }
        if (!await Gal.hasAccess(toAlbum: true)) {
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message:
                'Photos permission is required to save the document to your gallery.',
            isWarning: true,
          );
          return;
        }

        final tempDir = await getTemporaryDirectory();
        var ext = p.extension(Uri.parse(url).path).trim().toLowerCase();
        if (ext.isEmpty) ext = isVideo ? '.mp4' : '.jpg';
        final stamp = AppTime.nowUtc().millisecondsSinceEpoch;
        final base = doc.documentName.trim().isNotEmpty
            ? doc.documentName.trim()
            : 'wowcare_document_$stamp';
        final safeBase = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final outPath = p.join(tempDir.path, '$safeBase$ext');

        // Plain-Dio download via the shared service: the URL is a pre-signed
        // external (CloudFront) link, so the app's auth header / API base URL
        // must NOT be attached, and the View must not construct a Dio itself.
        await _documentsListCubit.downloadFile(url, outPath);
        if (isVideo) {
          await Gal.putVideo(outPath);
        } else {
          await Gal.putImage(outPath);
        }
        try {
          await File(outPath).delete();
        } catch (_) {}

        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Saved to your gallery.',
          isSuccess: true,
        );
        return;
      }

      // Non-media documents (PDF, etc.) can't go to the gallery — open them.
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Could not open document',
          isError: true,
        );
      }
    } on GalException catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: e.type.message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to download document: ${e.toString()}',
        isError: true,
      );
    } finally {
      _isDownloadingDoc = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<StaffDocumentsListCubit, StaffDocumentsListState>(
          builder: (context, state) {
            if (state.isLoading && state.documents.isEmpty) {
              return const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                physics: AlwaysScrollableScrollPhysics(),
                child: StaffDocumentsListShimmer(),
              );
            }

            final query = _searchController.text.trim().toLowerCase();
            final documents = state.documents.where((d) {
              if (query.isEmpty) return true;
              return d.documentName.toLowerCase().contains(query) ||
                  d.documentType.toLowerCase().contains(query) ||
                  (d.uploadedBy ?? '').toLowerCase().contains(query);
            }).toList();

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
                      if (!state.isLoading &&
                          !state.isLoadingMore &&
                          state.hasMore) {
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
                    // Extra bottom padding so the floating add button
                    // doesn't overlap the last items.
                    padding: const EdgeInsets.fromLTRB(6, 16, 6, 96),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: AppColors.cardColor.withValues(alpha: 0.88),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search documents...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      _searchController.text.trim().isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () => setState(() {
                                            _searchController.clear();
                                          }),
                                          icon: const Icon(Icons.close),
                                        ),
                                  filled: true,
                                  fillColor:
                                      AppColors.staffLightBackgroundColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              CustomToggle(
                                label: 'Show Expired Documents',
                                isToggled: _showExpired,
                                onToggle: (v) {
                                  setState(() => _showExpired = v);
                                  _documentsListCubit.refresh(
                                    widget.staffCode,
                                    expired: v ? true : null,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (documents.isEmpty)
                          Text(
                            _showExpired
                                ? 'No expired documents found'
                                : (query.isEmpty
                                      ? 'No documents found'
                                      : 'No documents match your search'),
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
                            itemBuilder: (context, index) {
                              final doc = documents[index];
                              final uploadedOn = _formatIsoDate(doc.createdAt);
                              final expiryDisplay = _formatExpiryDate(
                                doc.expiryDate,
                              );
                              final uploadedBy =
                                  (doc.uploadedBy ?? '').trim().isEmpty
                                  ? 'system'
                                  : doc.uploadedBy!.trim();
                              final isTarget = _isHighlightTarget(
                                doc.documentUuid,
                              );
                              if (isTarget) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  final ctx = _highlightRowKey.currentContext;
                                  if (ctx != null) {
                                    Scrollable.ensureVisible(
                                      ctx,
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      alignment: 0.1,
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: HighlightableCard(
                                  key: isTarget ? _highlightRowKey : null,
                                  code: doc.documentUuid,
                                  highlightCode: widget.highlightCode,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cardColor.withValues(
                                        alpha: 0.88,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor:
                                            AppColors.transparentColor,
                                      ),
                                      child: ExpansionTile(
                                        initiallyExpanded: isTarget,
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        childrenPadding:
                                            const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                        title: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doc.documentName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              doc.documentType,
                                              style: TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.primaryColor
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        children: [
                                          const Divider(
                                            height: 1,
                                            color: AppColors
                                                .attendanceCardDividerColor,
                                          ),
                                          const SizedBox(height: 12),
                                          _DocumentDetailRow(
                                            label: 'Document Type',
                                            value: doc.documentType,
                                          ),
                                          const SizedBox(height: 8),
                                          _DocumentDetailRow(
                                            label: 'Uploaded By',
                                            value: uploadedBy,
                                          ),
                                          const SizedBox(height: 8),
                                          _DocumentDetailRow(
                                            label: 'Uploaded On',
                                            value: uploadedOn,
                                          ),
                                          const SizedBox(height: 8),
                                          _DocumentDetailRow(
                                            label: 'Expiry Date',
                                            value: expiryDisplay,
                                          ),
                                          const SizedBox(height: 16),
                                          if (widget.canEdit) ...[
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      gradient:
                                                          AppColors.buildPrimaryGradient(),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () =>
                                                          _handleEdit(
                                                            context,
                                                            doc,
                                                          ),
                                                      style:
                                                          TextButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.zero,
                                                          ),
                                                      child: const Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontFamily: 'Manrope',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .cardColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: SizedBox(
                                                    height: 40,
                                                    child: OutlinedButton(
                                                      onPressed: () =>
                                                          _handleDelete(
                                                            context,
                                                            doc,
                                                          ),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFF6C7FD8,
                                                          ),
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          fontFamily: 'Manrope',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Color(
                                                            0xFF6C7FD8,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  height: 40,
                                                  child: ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        _isResolvingViewUrl,
                                                    builder:
                                                        (
                                                          context,
                                                          isResolvingViewUrl,
                                                          _,
                                                        ) {
                                                          return OutlinedButton(
                                                            onPressed:
                                                                isResolvingViewUrl
                                                                ? null
                                                                : () =>
                                                                      _handleView(
                                                                        context,
                                                                        doc,
                                                                      ),
                                                            style: OutlinedButton.styleFrom(
                                                              side: const BorderSide(
                                                                color: Color(
                                                                  0xFF6C7FD8,
                                                                ),
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                            child:
                                                                isResolvingViewUrl
                                                                ? const SizedBox(
                                                                    width: 18,
                                                                    height: 18,
                                                                    child:
                                                                        PrimaryCircularLoader(),
                                                                  )
                                                                : const Text(
                                                                    'View',
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Manrope',
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Color(
                                                                        0xFF6C7FD8,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    gradient:
                                                        AppColors.buildPrimaryGradient(),
                                                  ),
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        _handleDownload(
                                                          context,
                                                          doc,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: const Text(
                                                      'Download',
                                                      style: TextStyle(
                                                        fontFamily: 'Manrope',
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppColors.cardColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
        if (widget.canEdit)
          Positioned(
            right: 16,
            bottom: 16,
            child: GradientAddButton(
              onTap: () {
                context
                    .push<bool>(
                      StaffRoutes.documentForm,
                      extra: StaffDocumentFormArgs(staffCode: widget.staffCode),
                    )
                    .then((result) {
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
          ),
      ],
    );
  }
}

class _DocumentDetailRow extends StatelessWidget {
  const _DocumentDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
