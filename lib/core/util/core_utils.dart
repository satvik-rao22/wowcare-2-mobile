import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/core/util/logger_service.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart'; // backend/context extensions not available
// import 'package:schoolerp/core/res/colors.dart'; // backend colors not available

class CoreUtils {
  const CoreUtils._();

  /// Root [Navigator] key for session expiry, deep links, etc. Assign to [MaterialApp.navigatorKey].
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static String? _lastOnScreenErrorMessage;
  static DateTime? _lastOnScreenErrorAt;
  static OverlayEntry? _activeTopBannerEntry;

  /// Log API or application errors and optionally surface them in a top banner.
  ///
  /// When [showOnScreen] is true, uses [context] if provided, otherwise
  /// [rootNavigatorKey]. Repeats of the same message within [dedupeWindow]
  /// are suppressed on-screen (still printed) to avoid snackbar storms from rebuilds.
  static void logApiError(
    String message, {
    bool showOnScreen = false,
    BuildContext? context,
    Duration dedupeWindow = const Duration(seconds: 2),
  }) {
    final trimmed = message.trim();
    // ignore: avoid_print
    AppLogger.e('[API Error] $trimmed');
    if (!showOnScreen || trimmed.isEmpty) return;

    void showBanner(BuildContext ctx) {
      if (!ctx.mounted) return;
      final now = DateTime.now();
      if (_lastOnScreenErrorMessage == trimmed &&
          _lastOnScreenErrorAt != null &&
          now.difference(_lastOnScreenErrorAt!) < dedupeWindow) {
        return;
      }
      _lastOnScreenErrorMessage = trimmed;
      _lastOnScreenErrorAt = now;

      showTopSnackBar(
        context: ctx,
        message: _truncateForSnackBar(trimmed),
        isError: true,
        duration: const Duration(seconds: 4),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context != null) {
        showBanner(context);
        return;
      }
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) showBanner(ctx);
    });
  }

  static String _truncateForSnackBar(String message, {int maxLength = 360}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}…';
  }

  static Future<File?> pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Same top overlay as [showTopSnackBar], themed with [ColorScheme.primary] by default.
  /// [hasBottomNavigationBar] is ignored (kept for call-site compatibility).
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    bool hasBottomNavigationBar = false,
  }) {
    if (context is Element && !context.mounted) return;
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final onBg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    _showTopOverlayBanner(
      context: context,
      message: message,
      backgroundColor: bg,
      borderColor: bg.withOpacity(0.85),
      contentColor: onBg,
      icon: Icons.info_outline_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  static OverlayState? _overlayForBanner(BuildContext context) {
    var overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay != null) return overlay;
    overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay != null) return overlay;
    final root = rootNavigatorKey.currentContext;
    if (root != null) {
      overlay = Overlay.maybeOf(root, rootOverlay: true);
      if (overlay != null) return overlay;
    }
    return null;
  }

  static void _showTopOverlayBanner({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required Color contentColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context is Element && !context.mounted) return;

    // Use the root overlay so messages remain visible even if the current route
    // is popped (e.g., user taps "Skip" and navigation happens immediately).
    final overlay = _overlayForBanner(context);
    if (overlay == null) {
      // Avoid fallback floating SnackBar (can be laid out off-screen and crash).
      // If no overlay is currently available, skip this frame.
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final leftInset = mediaQuery.padding.left;
    final rightInset = mediaQuery.padding.right;
    final screenHeight = mediaQuery.size.height;
    // Keep the banner within the visible screen area (no overflow below screen).
    // We don't use hardcoded max-height; we constrain to the remaining space.
    const extraTopMargin = 20.0;
    final availableHeight =
        screenHeight - topInset - extraTopMargin - bottomInset - 16;
    final bannerMaxHeight = availableHeight > 0 ? availableHeight : 0.0;
    const horizontalMargin = 16.0;

    // Ensure only one banner is visible at a time (prevents "double banners"
    // when multiple events fire back-to-back during login/navigation).
    if (_activeTopBannerEntry?.mounted == true) {
      _activeTopBannerEntry!.remove();
    }

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topInset + extraTopMargin,
        left: leftInset + horizontalMargin,
        right: rightInset + horizontalMargin,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 340,
                maxHeight: bannerMaxHeight,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: contentColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          // If the message is too large, allow scrolling inside
                          // the banner so it never goes under the screen.
                          child: Text(
                            message,
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    _activeTopBannerEntry = overlayEntry;

    Future.delayed(duration, () {
      if (_activeTopBannerEntry == overlayEntry && overlayEntry.mounted) {
        overlayEntry.remove();
      }
      if (_activeTopBannerEntry == overlayEntry) {
        _activeTopBannerEntry = null;
      }
    });
  }

  /// Adapter for legacy SnackBar calls so feature modules can keep message
  /// creation logic while rendering through the unified top banner UI.
  static void showTopSnackBarFromSnackBar({
    required BuildContext context,
    required SnackBar snackBar,
  }) {
    String message = 'Something went wrong';
    final content = snackBar.content;
    if (content is Text) {
      final data = content.data;
      if (data != null && data.trim().isNotEmpty) {
        message = data;
      }
    }

    final bg = snackBar.backgroundColor;
    final hue = bg == null ? null : HSVColor.fromColor(bg).hue;

    // Normalize legacy/custom app colors to semantic variants used by
    // StudentScreen (success/error/warning), so UI is fully consistent.
    final isError = hue != null && (hue <= 25 || hue >= 345);
    final isWarning = hue != null && (hue > 25 && hue <= 70);
    final isSuccess = hue != null && (hue > 70 && hue <= 170);

    // Avoid default black banner for unknown colors: prefer warning style.
    final resolvedWarning = !isError && !isSuccess ? true : isWarning;

    showTopSnackBar(
      context: context,
      message: message,
      isError: isError,
      isWarning: resolvedWarning,
      isSuccess: isSuccess,
      duration: snackBar.duration,
    );
  }

  static void showTopSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isWarning = false,
    bool isSuccess = false,
    bool isAdjust = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context is Element && !context.mounted) return;

    const Color successColor = Color.fromRGBO(21, 133, 49, 1);
    const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

    final backgroundColor = isError
        ? Colors.red.shade50
        : isWarning
        ? Colors.orange.shade50
        : isSuccess
        ? successBackgroundColor
        : Colors.grey.shade200;
    final contentColor = isError
        ? Colors.red
        : isWarning
        ? Colors.orange
        : isSuccess
        ? successColor
        : Colors.black87;
    final borderColor = isError
        ? Colors.red.shade100
        : isWarning
        ? Colors.orange.shade100
        : isSuccess
        ? successBackgroundColor
        : Colors.grey.shade400;
    final icon = isError || isWarning
        ? Icons.error_outline_rounded
        : isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.info_outline_rounded;

    _showTopOverlayBanner(
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      contentColor: contentColor,
      icon: icon,
      duration: duration,
    );
  }

  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) {
      return phoneNumber;
    }
    return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
  }

  /// Reusable inline field-error text widget for form inputs.
  static Widget buildInlineFieldError(
    String? message, {
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 6),
  }) {
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Manrope',
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
