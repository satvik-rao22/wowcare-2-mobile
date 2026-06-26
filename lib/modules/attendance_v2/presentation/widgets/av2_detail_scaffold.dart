import 'package:flutter/material.dart';
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
      decoration: const BoxDecoration(gradient: Av2Colors.scaffoldGradient),
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
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Av2Colors.theme),
                      )
                    : const Icon(Icons.refresh, color: Av2Colors.primary),
              ),
            Padding(
              padding: const EdgeInsets.only(right: Av2Spacing.sm),
              child: TextButton.icon(
                onPressed: isExporting ? null : onExport,
                icon: isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Av2Colors.theme),
                      )
                    : const Icon(Icons.file_download_outlined,
                        size: 18, color: Av2Colors.theme),
                label: Text(
                  isExporting ? 'Preparing…' : 'Export CSV',
                  style: Av2Text.label.copyWith(
                    color: Av2Colors.theme,
                    fontWeight: FontWeight.w600,
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
