import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/generated_reports_content.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

class GeneratedReportsScreen extends StatefulWidget {
  const GeneratedReportsScreen({super.key});

  static const String routeName = '/reports/generated';

  @override
  State<GeneratedReportsScreen> createState() => _GeneratedReportsScreenState();
}

class _GeneratedReportsScreenState extends State<GeneratedReportsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ValueNotifier<String?> _selectedTag = ValueNotifier<String?>(null);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.d(
      '[REPORTS-UI] GeneratedReportsScreen: initState - starting initial load',
    );
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // After returning from an externally-launched file viewer (PDF/XLSX),
    // Android/iOS can resume Flutter without repainting its surface,
    // leaving a black screen. Force a rebuild on resume to guarantee a
    // fresh frame is drawn.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  /// Dismiss a dialog shown via [showDialog] (which defaults to the root
  /// navigator). Popping through the ambient [context] instead would hit
  /// go_router's branch navigator and pop the screen itself off the page
  /// stack, which crashes with `currentConfiguration.isNotEmpty` once no
  /// pages remain — always target the same (root) navigator the dialog was
  /// pushed on, and never pop when there's nothing left to pop.
  void _dismissDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _loadData({bool isRefresh = false}) {
    final cubit = context.read<ReportsCubit>();
    AppLogger.d(
      '[REPORTS-UI] GeneratedReportsScreen: Loading data [isRefresh=$isRefresh]',
    );
    // Load in sequence: first reports, then tags (chained with .then() to ensure order)
    unawaited(
      cubit.loadRecentReports(isRefresh: isRefresh).then((_) {
        AppLogger.d(
          '[REPORTS-UI] GeneratedReportsScreen: Reports loaded, now loading tags',
        );
        cubit.loadDynamicTags();
      }),
    );
  }

  Future<void> _handleDownload(BuildContext context, String? assetCode) async {
    if (assetCode == null || assetCode.isEmpty) {
      AppLogger.e('[REPORTS-UI-DOWN] Invalid assetCode: $assetCode');
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.unableToDownloadInvalidReportIdentifier,
        isError: true,
      );
      return;
    }

    AppLogger.d('[REPORTS-UI-DOWN] Started for assetCode: $assetCode');

    final cubit = context.read<ReportsCubit>();
    final allReports = cubit.state.recentReports;

    // Find report metadata
    late final ReportMetadataEntity report;
    try {
      report = allReports.firstWhere((r) => r.assetCode == assetCode);
      AppLogger.d('[REPORTS-UI-DOWN] Found report by assetCode');
    } catch (_) {
      if (allReports.isNotEmpty) {
        report = allReports.first;
        AppLogger.d('[REPORTS-UI-DOWN] Using first report as fallback');
      } else {
        report = ReportMetadataEntity(
          reportId: assetCode,
          reportType: ReportType.studentDailyAttendance,
          generatedAt: AppTime.now(),
          assetCode: assetCode,
          fileName: 'report.pdf',
        );
        AppLogger.d('[REPORTS-UI-DOWN] Created default report');
      }
    }

    final fileName = report.fileName ?? 'report.pdf';

    // Show downloading dialog
    if (mounted) {
      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.md),
              Text('Downloading $fileName...'),
            ],
          ),
        ),
      );
    }

    try {
      AppLogger.d('[REPORTS-UI-DOWN] Downloading: $fileName');

      final fileData = await cubit.downloadReport(assetCode);

      if (!mounted) return;
      _dismissDialog(context); // Close download dialog

      if (fileData == null || fileData.isEmpty) {
        AppLogger.e('[REPORTS-UI-DOWN] Bytes empty - assetCode: $assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.failedToDownloadReport,
          isError: true,
        );
        return;
      }

      AppLogger.d(
        '[REPORTS-UI-DOWN] Downloaded: bytesLength=${fileData.length}',
      );

      // Show saving dialog
      if (mounted) {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.md),
                const Text(ReportsStrings.savingFile),
              ],
            ),
          ),
        );
      }

      // Save file
      AppLogger.d('[REPORTS-UI-DOWN] Saving: $fileName');

      final filePath = await cubit.saveReportFile(
        fileData: Uint8List.fromList(fileData),
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!mounted) return;
      _dismissDialog(context); // Close save dialog

      if (filePath == null) {
        AppLogger.e('[REPORTS-UI-DOWN] Save failed - assetCode: $assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.failedToSaveFile,
          isError: true,
        );
        return;
      }

      AppLogger.i('[REPORTS-UI-DOWN] Saved: $filePath');

      // Show success message
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: '$fileName saved successfully',
          isSuccess: true,
        );
      }

      // Try to open file
      AppLogger.d('[REPORTS-UI-DOWN] Opening: $filePath');

      final opened = await cubit.openReportFile(
        filePath: filePath,
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!opened && mounted) {
        AppLogger.w('[REPORTS-UI-DOWN] Auto-open failed, file still saved');
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.savedOpenFromFileManager,
          isSuccess: true,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[REPORTS-UI-DOWN] Exception:\n'
        '  assetCode: $assetCode\n'
        '  fileName: $fileName\n'
        '  error: $e\n'
        '  stackTrace: $stackTrace',
      );

      if (mounted) {
        _dismissDialog(context);

        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error: $e',
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedTag.dispose();
    super.dispose();
  }

  List<ReportMetadataEntity> _filterReports(
    List<ReportMetadataEntity> reports,
    String? selectedTag,
  ) {
    if (selectedTag == null || selectedTag.isEmpty) {
      return reports;
    }
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackgroundColor,
      appBar: const CustomAppBar(hasBackButton: true),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                'assets/bgImages/wowcare_mobile_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(
                      context.responsive(compact: 16.0, medium: 32.0),
                    ),
                    child: Text(
                      ReportsStrings.generatedReports,
                      style: AppTextStyles.reportsHeading(
                        fontSize: context.responsive(
                          compact: 18.0,
                          medium: 24.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(
                        compact: 16.0,
                        medium: 32.0,
                      ),
                    ),
                    child: GeneratedReportsTagFilter(selectedTag: _selectedTag),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      context.responsive(compact: 16.0, medium: 32.0),
                    ),
                    child: GeneratedReportsContent(
                      onRefresh: _loadData,
                      selectedTag: _selectedTag,
                      filterReports: _filterReports,
                      onDownload: _handleDownload,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
