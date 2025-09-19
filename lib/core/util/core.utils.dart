import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/colors.dart';

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
      builder: (_) => Center(
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: const CircularProgressIndicator(),
        ),
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
        ? 20.h + context.mediaQuery.padding.bottom
        : 50.h;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.cardColor,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          margin: EdgeInsets.only(
            left: 10.w,
            right: 10.w,
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
    if (!context.mounted) return;

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
    if (!context.mounted) return;

    const Color successColor = Color.fromRGBO(21, 133, 49, 1);
    const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

    final topInset = MediaQuery.of(context).padding.top;
    final topPosition = topInset + 20.h;

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
            margin: EdgeInsets.only(right: 16.w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.shade50
                      : isWarning
                      ? Colors.orange.shade50
                      : isSuccess
                      ? successBackgroundColor
                      : Colors.black,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(10.r),
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
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
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
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
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
                          fontSize: 14.sp,
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
    return '(${phoneNumber.substring(0, 3)}) '
        '${phoneNumber.substring(3, 6)}-'
        '${phoneNumber.substring(6)}';
  }
}
