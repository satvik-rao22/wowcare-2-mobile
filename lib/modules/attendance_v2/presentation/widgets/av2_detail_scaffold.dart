import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// Shared chrome for the detail screen: brand scaffold gradient + a transparent
/// AppBar with a visible Refresh action and an "Export CSV" action. Wraps
/// loading, error and loaded states so they share the same frame.
class Av2DetailScaffold extends StatelessWidget {
  const Av2DetailScaffold({
    super.key,
    required this.body,
    this.onExport,
    this.onRefresh,
    this.isRefreshing = false,
    this.isExporting = false,
  });

  final Widget body;
  final VoidCallback? onExport;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Av2Colors.scaffoldFill),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const BackButton(color: Av2Colors.primary),
          title: Text('Staff attendance', style: Av2Text.title),
          centerTitle: false,
          actions: [
            if (onRefresh != null)
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                tooltip: 'Refresh',
                icon: isRefreshing
                    ? const PrimaryCircularLoader(size: 18, strokeWidth: 2)
                    : const Icon(Icons.refresh, color: Av2Colors.primary),
              ),
            Padding(
              padding: const EdgeInsets.only(right: Av2Spacing.sm),
              child: TextButton.icon(
                onPressed: isExporting ? null : onExport,
                icon: isExporting
                    ? const PrimaryCircularLoader(size: 16, strokeWidth: 2)
                    : const Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: Av2Colors.theme,
                      ),
                label: Text(
                  isExporting ? 'Preparing…' : 'Export CSV',
                  style: Av2Text.label.copyWith(
                    color: Av2Colors.theme,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Av2Colors.theme,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                    side: const BorderSide(color: Av2Colors.border),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}
