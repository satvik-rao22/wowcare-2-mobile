// // import 'dart:io';

// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:schoolerp/core/extentions/context_extentions.dart';
// // import 'package:schoolerp/core/res/colors.dart';

// // class CoreUtils {
// //   const CoreUtils._();

// //   static Future<File?> pickImage() async {
// //     final image = await ImagePicker().pickImage(source: ImageSource.gallery);
// //     if (image != null) {
// //       return File(image.path);
// //     }
// //     return null;
// //   }

// //   static void showLoadingDialog(BuildContext context) {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (_) => const Center(
// //         child: CircularProgressIndicator(),
// //       ),
// //     );
// //   }

// //   static void showSnackBar(
// //     BuildContext context,
// //     String message, {
// //     Color? backgroundColor,
// //     bool hasBottomNavigationBar = false,
// //   }) {
// //     double bottomMargin =
// //         hasBottomNavigationBar ? 20 + context.mediaQuery.padding.bottom : 50;

// //     ScaffoldMessenger.of(context)
// //       ..removeCurrentSnackBar()
// //       ..showSnackBar(
// //         SnackBar(
// //           content: Padding(
// //             padding: const EdgeInsets.symmetric(
// //               vertical: 5,
// //             ),
// //             child: Text(
// //               message,
// //               style: const TextStyle(
// //                 color: AppColors.cardColor,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ),
// //           behavior: SnackBarBehavior.floating,
// //           backgroundColor: backgroundColor ?? AppColors.primaryColor,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(20),
// //           ),
// //           margin: EdgeInsets.only(
// //             left: 10,
// //             right: 10,
// //             bottom: bottomMargin,
// //           ),
// //         ),
// //       );
// //   }

// //   static void showTopSnackBar({
// //     required BuildContext context,
// //     required String message,
// //     bool isError = false,
// //     bool isWarning = false,
// //     bool isSuccess = false,
// //     bool isAdjust = false,
// //     Duration duration = const Duration(seconds: 2),
// //   }) {
// //     ScaffoldMessenger.of(context).removeCurrentSnackBar();

// //     const Color successColor = Color.fromRGBO(21, 133, 49, 1);
// //     const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

// //     final screenHeight = MediaQuery.of(context).size.height;
// //     final topInset = MediaQuery.of(context).padding.top;
// //     // Position the bottom of the SnackBar 120px from the top of the screen.
// //     // This is more robust than calculating based on AppBar height, which can
// //     // be incorrect, especially with SliverAppBars, preventing off-screen errors.
// //     final bottomMargin = screenHeight - topInset - 120;

// //     final snackBar = SnackBar(
// //       content: Container(
// //         padding: const EdgeInsets.symmetric(
// //           vertical: 1,
// //         ),
// //         child: Row(
// //           children: [
// //             Icon(
// //               isError
// //                   ? Icons.error
// //                   : isWarning
// //                       ? Icons.error
// //                       : Icons.check,
// //               color: isError
// //                   ? Colors.red
// //                   : isWarning
// //                       ? Colors.orange
// //                       : isSuccess
// //                           ? successColor
// //                           : Colors.black,
// //               size: 20,
// //             ),
// //             const SizedBox(width: 8),
// //             Expanded(
// //               child: Text(
// //                 message,
// //                 style: TextStyle(
// //                   color: isError
// //                       ? Colors.red
// //                       : isWarning
// //                           ? Colors.orange
// //                           : isSuccess
// //                               ? successColor
// //                               : Colors.black,
// //                   fontSize: 14,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //       backgroundColor: isError
// //           ? Colors.red.shade50
// //           : isWarning
// //               ? Colors.orange.shade50
// //               : isSuccess
// //                   ? successBackgroundColor
// //                   : Colors.black,
// //       padding: const EdgeInsets.symmetric(
// //         horizontal: 5,
// //         vertical: 10,
// //       ),
// //       behavior: SnackBarBehavior.floating,
// //       duration: duration,
// //       elevation: 8,
// //       dismissDirection: DismissDirection.startToEnd,
// //       margin: EdgeInsets.only(
// //         bottom: bottomMargin,
// //         right: 0,
// //         left: context.width / 3,
// //       ),
// //       shape: RoundedRectangleBorder(
// //         borderRadius: const BorderRadius.horizontal(
// //           left: Radius.circular(10),
// //         ),
// //         side: BorderSide(
// //           color: isError
// //               ? Colors.red.shade100
// //               : isWarning
// //                   ? Colors.orange.shade100
// //                   : isSuccess
// //                       ? successBackgroundColor
// //                       : Colors.black,
// //         ),
// //       ),
// //     );

// //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
// //   }

// //   static String formatPhoneNumber(String phoneNumber) {
// //     if (phoneNumber.length != 10) {
// //       return phoneNumber;
// //     }
// //     return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
// //   }
// // }

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/res/colors.dart';

// class CoreUtils {
//   const CoreUtils._();

//   static Future<File?> pickImage() async {
//     final image = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       return File(image.path);
//     }
//     return null;
//   }

//   static void showLoadingDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }

//   static void showSnackBar(
//     BuildContext context,
//     String message, {
//     Color? backgroundColor,
//     bool hasBottomNavigationBar = false,
//   }) {
//     double bottomMargin =
//         hasBottomNavigationBar ? 20 + context.mediaQuery.padding.bottom : 50;

//     ScaffoldMessenger.of(context)
//       ..removeCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Padding(
//             padding: const EdgeInsets.symmetric(
//               vertical: 5,
//             ),
//             child: Text(
//               message,
//               style: const TextStyle(
//                 color: AppColors.cardColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: backgroundColor ?? AppColors.primaryColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           margin: EdgeInsets.only(
//             left: 10,
//             right: 10,
//             bottom: bottomMargin,
//           ),
//         ),
//       );
//   }

//   static void showTopSnackBar({
//     required BuildContext context,
//     required String message,
//     bool isError = false,
//     bool isWarning = false,
//     bool isSuccess = false,
//     bool isAdjust = false,
//     Duration duration = const Duration(seconds: 2),
//   }) {
//     ScaffoldMessenger.of(context).removeCurrentSnackBar();

//     const Color successColor = Color.fromRGBO(21, 133, 49, 1);
//     const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

//     final snackBar = SnackBar(
//       content: Container(
//         padding: const EdgeInsets.symmetric(
//           vertical: 1,
//         ),
//         child: Row(
//           children: [
//             Icon(
//               isError
//                   ? Icons.error
//                   : isWarning
//                       ? Icons.error
//                       : Icons.check,
//               color: isError
//                   ? Colors.red
//                   : isWarning
//                       ? Colors.orange
//                       : isSuccess
//                           ? successColor
//                           : Colors.black,
//               size: 20,
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 message,
//                 style: TextStyle(
//                   color: isError
//                       ? Colors.red
//                       : isWarning
//                           ? Colors.orange
//                           : isSuccess
//                               ? successColor
//                               : Colors.black,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       backgroundColor: isError
//           ? Colors.red.shade50
//           : isWarning
//               ? Colors.orange.shade50
//               : isSuccess
//                   ? successBackgroundColor
//                   : Colors.black,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 5,
//         vertical: 10,
//       ),
//       behavior: SnackBarBehavior.floating,
//       duration: duration,
//       elevation: 8,
//       dismissDirection: DismissDirection.startToEnd,
//       margin: EdgeInsets.only(
//         bottom: isAdjust
//             ? context.height -
//                 (AppBar().preferredSize.height +
//                     MediaQuery.of(context).padding.top +
//                     250)
//             : context.height -
//                 (AppBar().preferredSize.height +
//                     context.mediaQuery.padding.top +
//                     200),
//         right: 0,
//         left: context.width / 3,
//       ),
//       shape: RoundedRectangleBorder(
//         borderRadius: const BorderRadius.horizontal(
//           left: Radius.circular(10),
//         ),
//         side: BorderSide(
//           color: isError
//               ? Colors.red.shade100
//               : isWarning
//                   ? Colors.orange.shade100
//                   : isSuccess
//                       ? successBackgroundColor
//                       : Colors.black,
//         ),
//       ),
//     );

//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }

//   static String formatPhoneNumber(String phoneNumber) {
//     if (phoneNumber.length != 10) {
//       return phoneNumber;
//     }
//     return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
//   }
// }


import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart'; // backend/context extensions not available
// import 'package:schoolerp/core/res/colors.dart'; // backend colors not available

class CoreUtils {
  const CoreUtils._();

  /// Root [Navigator] key for session expiry, deep links, etc. Assign to [MaterialApp.navigatorKey].
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static String? _lastOnScreenErrorMessage;
  static DateTime? _lastOnScreenErrorAt;

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
    print('[API Error] $trimmed');
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
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    bool hasBottomNavigationBar = false,
  }) {
    double bottomMargin = hasBottomNavigationBar
        ? 20 + MediaQuery.of(context).padding.bottom
        : 50;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: bottomMargin,
          ),
        ),
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
    // Don't attempt to show UI from a disposed context.
    if (context is Element && !context.mounted) return;

    const Color successColor = Color.fromRGBO(21, 133, 49, 1);
    const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

    final backgroundColor = isError
        ? Colors.red.shade50
        : isWarning
            ? Colors.orange.shade50
            : isSuccess
                ? successBackgroundColor
                : Colors.black;
    final contentColor = isError
        ? Colors.red
        : isWarning
            ? Colors.orange
            : isSuccess
                ? successColor
                : Colors.black;

    // Use the root overlay so messages remain visible even if the current route
    // is popped (e.g., user taps "Skip" and navigation happens immediately).
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback: use ScaffoldMessenger if no Overlay is available.
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: duration,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final leftInset = mediaQuery.padding.left;
    final rightInset = mediaQuery.padding.right;
    const horizontalMargin = 16.0;
    // Push the banner clearly below the status bar so it never "sticks" to
    // the very top edge of the device (as in the screenshot the user shared).
    const extraTopMargin = 20.0;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topInset + extraTopMargin,
        left: leftInset + horizontalMargin,
        right: rightInset + horizontalMargin,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isError
                          ? Colors.red.shade100
                          : isWarning
                              ? Colors.orange.shade100
                              : isSuccess
                                  ? successBackgroundColor
                                  : Colors.black,
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
                      Icon(
                        isError || isWarning ? Icons.error : Icons.check,
                        color: contentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: contentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: message,
                                style: TextStyle(
                                  color: contentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) {
      return phoneNumber;
    }
    return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
  }
}