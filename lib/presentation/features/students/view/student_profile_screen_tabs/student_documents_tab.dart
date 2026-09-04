import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/views/document_viewer_screen.dart';
import 'package:wowcare/presentation/features/students/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/students/cubit/student_documents_list_cubit.dart';
import 'package:wowcare/domain/features/student/entities/student_document.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';

class StudentDocumentsTab extends StatefulWidget {
  const StudentDocumentsTab({
    super.key,
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.canEdit = false,
    this.highlightCode,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  /// Whether the current persona may add/edit/delete documents (resolved from
  /// the school's student-settings by the parent screen).
  final bool canEdit;

  /// Document code (== API `code`/documentUuid) from a notification deep-link;
  /// the matching document card scrolls into view, expands, and flashes.
  final String? highlightCode;

  @override
  State<StudentDocumentsTab> createState() => _StudentDocumentsTabState();
}

class _StudentDocumentsTabState extends State<StudentDocumentsTab> {
  bool _showExpired = false;
  bool _isDownloadingDoc = false;

  /// Notification deep-link target document row.
  final GlobalKey _highlightRowKey = GlobalKey();
  bool _isHighlightTarget(String? code) {
    final target = (widget.highlightCode ?? '').trim();
    final c = (code ?? '').trim();
    return target.isNotEmpty && c.toUpperCase() == target.toUpperCase();
  }

  late final StudentDocumentsListCubit _documentsListCubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _formatDocumentType(String type) {
    final normalizedType = type.trim();
    if (normalizedType.isEmpty) return normalizedType;

    switch (normalizedType) {
      case 'BIRTH_CERTIFICATE':
      case 'Birth_Certificate':
      case 'Birth_Ceriticate':
        return 'Birth Certificate';
      case 'HEALTH_FORMS':
      case 'Health_Forms':
        return 'Health Forms';
      case 'REGISTRATION_FORMS':
      case 'Registration_Forms':
        return 'Registration Forms';
      case 'SPECIAL_PROGRAM_FORMS':
      case 'Special_Program_Forms':
        return 'Special Program Forms';
      case 'OTHER':
      case 'Other':
        return 'Other';
      default:
        final words = normalizedType.replaceAll('_', ' ').split(' ');
        return words
            .where((word) => word.isNotEmpty)
            .map(
              (word) =>
                  '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1).toLowerCase() : ''}',
            )
            .join(' ');
    }
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
      return raw;
    }
  }

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
    _scrollController.dispose();
    _searchController.dispose();
    _documentsListCubit.close();
    super.dispose();
  }

  Future<void> _handleEdit(BuildContext context, StudentDocument doc) async {
    if (!widget.canEdit) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
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

    final result = await context.push<bool>(
      AddStudentDocumentScreen.routeName,
      extra: <String, dynamic>{
        'studentCode': widget.studentCode ?? '',
        'isEdit': true,
        'initialDocumentName': doc.documentName,
        'initialDocumentType': doc.documentType,
        'initialExpiryDate': expiryDate,
        'initialFilePath': doc.documentUrl,
        'initialMimeType': doc.mimeType,
        'initialFileSizeKb': doc.documentSizeKb,
        'initialDocumentNotes': null,
        'initialAssetCode': doc.assetCode,
        'documentUuid': doc.documentUuid,
      },
    );

    if (result == true && mounted) {
      _documentsListCubit.refresh(
        widget.studentCode ?? '',
        expiredOnly: _showExpired ? true : null,
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, StudentDocument doc) async {
    if (!widget.canEdit) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
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

  /// The downloadable URL is resolved from the asset code; documentUrl can be
  /// just a file name for newer rows.
  Future<String> _resolveDocumentUrl(StudentDocument doc) async {
    final assetCode = (doc.assetCode ?? '').trim();
    final rawUrl = doc.documentUrl.trim();
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    if (assetCode.isNotEmpty) {
      return (await serviceLocator<ImageUploadService>().getMediaAssetUrlByCode(
        assetCode: assetCode,
      )).trim();
    }
    return '';
  }

  bool _isResolvingViewUrl = false;

  Future<void> _handleView(BuildContext context, StudentDocument doc) async {
    if (_isResolvingViewUrl) return;
    setState(() => _isResolvingViewUrl = true);
    try {
      final url = await _resolveDocumentUrl(doc);
      // Do NOT log the resolved URL (a pre-signed document-access link) or the
      // document name (PII); only non-sensitive metadata + whether it resolved.
      AppLogger.d(
        '[StudentDocumentsTab] _handleView mimeType=${doc.mimeType} '
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
        DocumentViewerScreen.routeName,
        extra: <String, dynamic>{
          'url': url,
          'documentName': doc.documentName,
          'mimeType': doc.mimeType,
        },
      );
    } catch (e, st) {
      AppLogger.e('[StudentDocumentsTab] _handleView failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isResolvingViewUrl = false);
    }
  }

  Future<void> _handleDownload(
    BuildContext context,
    StudentDocument doc,
  ) async {
    if (_isDownloadingDoc) return;

    setState(() => _isDownloadingDoc = true);
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
        message:
            'Failed to download document: ${ApiErrorHandler.extractErrorMessage(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDownloadingDoc = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStudentWrite = widget.canEdit;
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          BlocBuilder<StudentDocumentsListCubit, StudentDocumentsListState>(
            builder: (context, state) {
              final query = _searchController.text.trim().toLowerCase();
              final documents = query.isEmpty
                  ? state.documents
                  : state.documents
                        .where((d) {
                          final name = d.documentName.toLowerCase();
                          final type = d.documentType.toLowerCase();
                          final uploadedBy = (d.uploadedBy ?? '').toLowerCase();
                          return name.contains(query) ||
                              type.contains(query) ||
                              uploadedBy.contains(query);
                        })
                        .toList(growable: false);

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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      // Extra bottom padding so the floating add button doesn't overlap the last items.
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
                              color: Colors.white.withValues(alpha: 0.88),
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
                                    fillColor: const Color(0xFFF8F7FA),
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
                                      studentCode,
                                      expiredOnly: v ? true : null,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state.isLoading && documents.isEmpty)
                            const StudentDocumentsListShimmer()
                          else if (documents.isEmpty)
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
                              itemBuilder: (context, i) {
                                final doc = documents[i];
                                final uploadedOn = _formatIsoDate(
                                  doc.createdAt,
                                );
                                final expiryDisplay = _formatExpiryDate(
                                  doc.expiryDate,
                                );
                                final uploadedBy =
                                    (doc.uploadedBy ?? '').trim().isEmpty
                                    ? 'system'
                                    : doc.uploadedBy!.trim();
                                final docTypeDisplay = _formatDocumentType(
                                  doc.documentType,
                                );
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
                                      clipBehavior: Clip.antiAlias,
                                      // Match the Family/Pickup cards: themeColor outline, square top-left.
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: AppColors.themeColor,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent,
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: isTarget,
                                          tilePadding:
                                              const EdgeInsets.symmetric(
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Manrope',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                docTypeDisplay,
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
                                              color: Color(0xFFE9ECEF),
                                            ),
                                            const SizedBox(height: 12),
                                            _DocumentDetailRow(
                                              label: 'Document Type',
                                              value: docTypeDisplay,
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
                                            if (canStudentWrite) ...[
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
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                        child: const Text(
                                                          'Edit',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Manrope',
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
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
                                                          side:
                                                              const BorderSide(
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
                                                            fontFamily:
                                                                'Manrope',
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
                                                    child: OutlinedButton(
                                                      onPressed:
                                                          _isResolvingViewUrl
                                                          ? null
                                                          : () => _handleView(
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
                                                      child: _isResolvingViewUrl
                                                          ? const SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child: PrimaryCircularLoader(
                                                                size: 18,
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                          : const Text(
                                                              'View',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Manrope',
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Color(
                                                                  0xFF6C7FD8,
                                                                ),
                                                              ),
                                                            ),
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
                                                      style:
                                                          TextButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.zero,
                                                          ),
                                                      child: const Text(
                                                        'Download',
                                                        style: TextStyle(
                                                          fontFamily: 'Manrope',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.white,
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
          if (canStudentWrite)
            Positioned(
              right: 16,
              bottom: 16,
              child: GradientAddButton(
                onTap: () {
                  context
                      .push<bool>(
                        AddStudentDocumentScreen.routeName,
                        extra: <String, dynamic>{
                          'studentCode': widget.studentCode ?? '',
                        },
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
            ),
        ],
      ),
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
            color: Color(0xff573353),
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
              color: Color(0xff573353),
            ),
          ),
        ),
      ],
    );
  }
}
