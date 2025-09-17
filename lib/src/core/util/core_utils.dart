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

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/src/core/extentions/context_extentions.dart';

import '../res/colors.dart';

class CoreUtils {
  const CoreUtils._();

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

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    bool hasBottomNavigationBar = false,
  }) {
    double bottomMargin = hasBottomNavigationBar
        ? 20 + context.mediaQuery.padding.bottom
        : 50;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.cardColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.only(left: 10, right: 10, bottom: bottomMargin),
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
    // Check if the context is still valid
    if (!context.mounted) return;

    // Use a more robust approach with a custom overlay
    _showCustomSnackBar(
      context: context,
      message: message,
      isError: isError,
      isWarning: isWarning,
      isSuccess: isSuccess,
      isAdjust: isAdjust,
      duration: duration,
    );
  }

  static void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isWarning = false,
    bool isSuccess = false,
    bool isAdjust = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Check if the context is still valid
    if (!context.mounted) return;

    const Color successColor = Color.fromRGBO(21, 133, 49, 1);
    const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

    // Calculate position - position from top
    final topInset = MediaQuery.of(context).padding.top;
    final topPosition = topInset + 20; // 20px below the status bar

    // Create overlay entry
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPosition,
        right: 0,
        left: MediaQuery.of(context).size.width / 3,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.shade50
                      : isWarning
                      ? Colors.orange.shade50
                      : isSuccess
                      ? successBackgroundColor
                      : Colors.black,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
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
                  children: [
                    Icon(
                      isError
                          ? Icons.error
                          : isWarning
                          ? Icons.error
                          : Icons.check,
                      color: isError
                          ? Colors.red
                          : isWarning
                          ? Colors.orange
                          : isSuccess
                          ? successColor
                          : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isError
                              ? Colors.red
                              : isWarning
                              ? Colors.orange
                              : isSuccess
                              ? successColor
                              : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );

    // Insert overlay
    overlay.insert(overlayEntry);

    // Remove overlay after duration
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
