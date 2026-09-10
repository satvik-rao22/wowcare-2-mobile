import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/view/document_viewer_screen.dart';
import 'package:wowcare/presentation/features/students/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/students/view_model/student_documents_list_cubit.dart';
import 'package:wowcare/domain/features/student/entities/student_document.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

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
        message: StudentStrings.documentIdNotAvailable,
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
          initialMimeType: doc.mimeType,
          initialFileSizeKb: doc.documentSizeKb,
          initialDocumentNotes: doc.notes,
          initialAssetCode: doc.assetCode,
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
    if (!widget.canEdit) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
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
                  message: StudentStrings.documentIdNotAvailable,
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
                  message: StudentStrings.documentDeletedSuccessfully,
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
          message: StudentStrings.documentLinkNotAvailable,
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
          message: StudentStrings.documentLinkNotAvailable,
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
                StudentStrings.photosPermissionIsRequiredToSaveTheDocumentToY,
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
          message: StudentStrings.savedToYourGallery,
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
          message: StudentStrings.couldNotOpenDocument,
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
          StudentStrings.studentCodeIsRequiredToLoadDocuments,
          style: TextStyle(color: AppColors.primaryColor, fontSize: 16),
        ),
      );
    }

    return BlocProvider<StudentDocumentsListCubit>.value(
      value: _documentsListCubit,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppColors.pageBackgroundColor),
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
                      padding: const EdgeInsets.fromLTRB(
                        6,
                        AppSpacing.md,
                        6,
                        96,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.r14,
                              ),
                              color: AppColors.whiteColor.withValues(
                                alpha: 0.88,
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: StudentStrings.searchDocuments,
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
                                      borderRadius: AppRadius.allMd,
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                AppSpacing.gapVSm,
                                CustomToggle(
                                  label: StudentStrings.showExpiredDocuments,
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
                          AppSpacing.gapVMd,
                          if (state.isLoading && documents.isEmpty)
                            const StudentDocumentsListShimmer()
                          else if (documents.isEmpty)
                            Text(
                              _showExpired
                                  ? StudentStrings.noExpiredDocumentsFound
                                  : (query.isEmpty
                                        ? StudentStrings.noDocumentsFound
                                        : StudentStrings
                                              .noDocumentsMatchYourSearch),
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
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: HighlightableCard(
                                    key: isTarget ? _highlightRowKey : null,
                                    code: doc.documentUuid,
                                    highlightCode: widget.highlightCode,
                                    child: Container(
                                      clipBehavior: Clip.antiAlias,
                                      // Match the Family/Pickup cards: themeColor outline, square top-left.
                                      decoration: const BoxDecoration(
                                        color: AppColors.whiteColor,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(
                                            AppRadius.sm,
                                          ),
                                          bottomLeft: Radius.circular(
                                            AppRadius.sm,
                                          ),
                                          bottomRight: Radius.circular(
                                            AppRadius.sm,
                                          ),
                                        ),
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: AppColors.themeColor,
                                            width: AppDimensions.hairline,
                                          ),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          dividerColor:
                                              AppColors.transparentColor,
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: isTarget,
                                          tilePadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md,
                                                vertical: AppSpacing.xxs,
                                              ),
                                          childrenPadding:
                                              const EdgeInsets.fromLTRB(
                                                AppSpacing.md,
                                                AppSpacing.none,
                                                AppSpacing.md,
                                                AppSpacing.md,
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
                                                    fontFamily: AppFonts.body,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                ),
                                              ),
                                              AppSpacing.gapHXs,
                                              Text(
                                                docTypeDisplay,
                                                style: TextStyle(
                                                  fontFamily: AppFonts.body,
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
                                            AppSpacing.gapVSm,
                                            _DocumentDetailRow(
                                              label:
                                                  StudentStrings.documentType,
                                              value: docTypeDisplay,
                                            ),
                                            AppSpacing.gapVXs,
                                            _DocumentDetailRow(
                                              label: StudentStrings.uploadedBy,
                                              value: uploadedBy,
                                            ),
                                            AppSpacing.gapVXs,
                                            _DocumentDetailRow(
                                              label: StudentStrings.uploadedOn,
                                              value: uploadedOn,
                                            ),
                                            AppSpacing.gapVXs,
                                            _DocumentDetailRow(
                                              label: StudentStrings.expiryDate,
                                              value: expiryDisplay,
                                            ),
                                            AppSpacing.gapVMd,
                                            if (canStudentWrite) ...[
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SkeuKeyBox(
                                                      variant:
                                                          KeyVariant.primary,
                                                      radius: AppRadius.sm,
                                                      height: 40,
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
                                                          StudentStrings.edit,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppFonts.body,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .whiteColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  AppSpacing.gapHSm,
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
                                                            color: AppColors
                                                                .attendanceActionAccentColor,
                                                          ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                                borderRadius:
                                                                    AppRadius
                                                                        .allSm,
                                                              ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                        ),
                                                        child: const Text(
                                                          StudentStrings.delete,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                AppFonts.body,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .attendanceActionAccentColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              AppSpacing.gapVSm,
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
                                                          color: AppColors
                                                              .attendanceActionAccentColor,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                                  AppRadius
                                                                      .allSm,
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
                                                                strokeWidth:
                                                                    AppDimensions
                                                                        .borderThick,
                                                              ),
                                                            )
                                                          : const Text(
                                                              'View',
                                                              style: TextStyle(
                                                                fontFamily: Fonts
                                                                    .manrope,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .attendanceActionAccentColor,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                AppSpacing.gapHSm,
                                                Expanded(
                                                  child: SkeuKeyBox(
                                                    variant: KeyVariant.primary,
                                                    radius: AppRadius.sm,
                                                    height: 40,
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
                                                          fontFamily:
                                                              AppFonts.body,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .whiteColor,
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
                              padding: EdgeInsets.all(AppSpacing.md),
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
                borderRadius: AppRadius.md,
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
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        AppSpacing.gapHSm,
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.body,
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
