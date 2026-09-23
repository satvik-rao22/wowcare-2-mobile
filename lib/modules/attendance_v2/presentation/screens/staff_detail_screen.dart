import 'dart:async';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/utils/av2_csv_builder.dart';
import '../../core/utils/av2_save_permission.dart';
import '../../domain/entities/av2_staff_summary.dart';
import '../controllers/av2_day_filter.dart';
import '../controllers/av2_period.dart';
import '../cubit/staff_detail_cubit.dart';
import '../cubit/staff_detail_state.dart';
import '../widgets/av2_detail_scaffold.dart';
import '../widgets/av2_permission_sheet.dart';
import 'staff_detail_view.dart';

/// Entry point for the staff attendance & overtime detail. Given a [staffCode],
/// it loads the profile via [StaffDetailCubit] and renders loading / error /
/// loaded states inside the shared chrome.
class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({
    super.key,
    required this.staffCode,
    this.staffName = '',
  });

  final String staffCode;
  final String staffName;

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late final StaffDetailCubit _cubit;
  late Av2Period _period;
  late String _staffCode = widget.staffCode;
  late String _staffName = widget.staffName;
  bool _refreshing = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = Av2Period.month(DateTime(now.year, now.month, 1));
    _cubit = serviceLocator<StaffDetailCubit>();
    _fetch();
    // Admin can switch between staff from within the screen — preload the list.
    if (context.read<RoleCubit>().state.role == 'admin') {
      unawaited(_cubit.loadStaffList());
    }
  }

  void _fetch() {
    unawaited(
      _cubit.load(
        staffCode: _staffCode,
        staffName: _staffName,
        from: _period.start,
        to: _period.end,
      ),
    );
  }

  void _onPeriodChanged(Av2Period period) {
    setState(() => _period = period);
    _fetch();
  }

  /// Admin picked another staff member from the identity dropdown.
  void _onStaffSelected(Av2StaffSummary staff) {
    if (staff.code == _staffCode) return;
    setState(() {
      _staffCode = staff.code;
      _staffName = staff.name;
    });
    _fetch();
  }

  /// App-bar refresh button: recompute + reload, with a spinner on the icon.
  Future<void> _onRefreshTap() async {
    setState(() => _refreshing = true);
    await _cubit.refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  /// Export CSV: ensures save permission, gathers the full filtered range +
  /// each day's sessions in the background (button shows a spinner), builds a
  /// clean CSV, then opens the OS "Save to Files" dialog so the user picks
  /// where to save — no CSV-capable app required.
  Future<void> _onExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    AppLogger.i(
      '[AV2-EXPORT] start · staff=${widget.staffCode} '
      'range=${_period.start}..${_period.end} filter=${_cubit.state.filter}',
    );

    // 1) Permission gate (mostly a no-op on modern Android/iOS; matters on
    // legacy Android). Only a hard "permanently denied" blocks us.
    final perm = await Av2SavePermissionHelper.ensure();
    if (!mounted) return;
    if (perm != Av2SavePermission.granted) {
      AppLogger.w('[AV2-EXPORT] aborted: storage permission $perm');
      setState(() => _exporting = false);
      await _showStoragePermissionSheet(
        permanentlyDenied: perm == Av2SavePermission.permanentlyDenied,
      );
      return;
    }

    // 2) Gather the data (network + per-day sessions).
    Av2ExportData data;
    try {
      data = await _cubit.buildExport();
      AppLogger.i(
        '[AV2-EXPORT] gathered ${data.profile.days.length} days, '
        '${data.detailByDate.length} day-details',
      );
    } catch (e, s) {
      AppLogger.e('[AV2-EXPORT] failed gathering report data', e, s);
      if (mounted) {
        setState(() => _exporting = false);
        _toast(
          'Couldn’t load the report. Check your connection and try again.',
          isError: true,
        );
      }
      return;
    }

    // 3) Build + save.
    try {
      final bytes = Av2CsvBuilder.buildBytes(
        profile: data.profile,
        detailByDate: data.detailByDate,
        reportLabel: data.filter.label,
        generatedAt: DateTime.now(),
      );
      final baseName = _exportBaseName(data);
      AppLogger.d('[AV2-EXPORT] writing $baseName.csv (${bytes.length} bytes)');

      final saved = await FileSaver.instance.saveAs(
        name: baseName,
        bytes: Uint8List.fromList(bytes),
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      if (!mounted) return;
      // saveAs returns a path on save, null/empty if the user cancelled.
      if (saved != null && saved.isNotEmpty) {
        AppLogger.i('[AV2-EXPORT] saved to: $saved');
        _toast('Saved “$baseName.csv”');
      } else {
        AppLogger.d('[AV2-EXPORT] save cancelled by user');
      }
    } catch (e, s) {
      AppLogger.e('[AV2-EXPORT] failed saving CSV', e, s);
      if (mounted) {
        _toast('Couldn’t save the CSV. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Explains the missing storage permission with steps to grant it; opens app
  /// settings if the user proceeds.
  Future<void> _showStoragePermissionSheet({
    required bool permanentlyDenied,
  }) async {
    final message = permanentlyDenied
        ? 'Storage access is turned off for this app, so the CSV can’t be saved '
              'to your device. You can re-enable it from Settings.'
        : 'To save the attendance CSV to your device, this app needs permission '
              'to store files.';
    final proceed = await showAv2PermissionSheet(
      context,
      title: 'Storage permission needed',
      message: message,
      steps: const [
        'Tap “Open settings” below.',
        'Open “Permissions”.',
        'Allow “Storage” (or “Files and media”).',
        'Come back and tap “Export CSV” again.',
      ],
      confirmLabel: 'Open settings',
    );
    if (proceed == true) await openAppSettings();
  }

  /// File name without extension, e.g. `Aparna_Biwalkar_2026-06-01_2026-06-30_AllDays`.
  String _exportBaseName(Av2ExportData data) {
    final name = data.profile.staffName.trim().isEmpty
        ? 'Staff'
        : data.profile.staffName.trim().replaceAll(RegExp(r'\s+'), '_');
    final tab = switch (data.filter) {
      Av2DayFilter.overtime => 'Overtime',
      Av2DayFilter.absent => 'Absent',
      Av2DayFilter.all => 'AllDays',
    };
    String d(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    return '${name}_${d(data.profile.rangeStart)}_${d(data.profile.rangeEnd)}_$tab';
  }

  /// Every message this screen raises is a failure or a "saved" confirmation,
  /// so it goes through the app's own top snack bar rather than Material's
  /// bottom one — see [CoreUtils.showTopSnackBar].
  void _toast(String message, {bool isError = false}) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: isError,
    );
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Av2DetailScaffold(
      onExport: _onExport,
      isExporting: _exporting,
      onRefresh: _onRefreshTap,
      isRefreshing: _refreshing,
      body: BlocBuilder<StaffDetailCubit, StaffDetailState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.isError) {
            return AppErrorState(
              title: 'Unable to load attendance data.',
              message: state.errorMessage,
              onRetry: _fetch,
            );
          }
          if (state.isLoaded) {
            // Edit is admin-only (org/school admin). RoleCubit is provided
            // app-wide in main.dart.
            final canEdit = context.watch<RoleCubit>().state.role == 'admin';
            return RefreshIndicator(
              color: Av2Colors.theme,
              onRefresh: _cubit.refresh,
              child: StaffDetailView(
                profile: state.profile!,
                period: _period,
                loadDetail: _cubit.dayDetail,
                reloadId: state.reloadId,
                onPeriodChanged: _onPeriodChanged,
                canEdit: canEdit,
                staff: canEdit ? state.staff : const [],
                onStaffSelected: canEdit ? _onStaffSelected : null,
                filter: state.filter,
                onFilterSelected: _cubit.setFilter,
                onLoadMore: _cubit.loadMore,
                hasMore: state.hasMore,
                loadingMore: state.loadingMore,
                onEditSession:
                    ({
                      required recordCode,
                      required signInLocal,
                      signOutLocal,
                    }) => _cubit.editSession(
                      recordCode: recordCode,
                      signInLocal: signInLocal,
                      signOutLocal: signOutLocal,
                    ),
                onDeleteSession: (recordCode) =>
                    _cubit.deleteSession(recordCode: recordCode),
                onEditAbsence:
                    ({
                      required code,
                      required fromDate,
                      required toDate,
                      required reason,
                      required type,
                      required note,
                    }) => _cubit.editAbsence(
                      code: code,
                      fromDate: fromDate,
                      toDate: toDate,
                      reason: reason,
                      type: type,
                      note: note,
                    ),
                onDeleteAbsence: (code) => _cubit.deleteAbsence(code: code),
              ),
            );
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Av2Spacing.xl),
              child: PrimaryCircularLoader(),
            ),
          );
        },
      ),
    );
  }
}
