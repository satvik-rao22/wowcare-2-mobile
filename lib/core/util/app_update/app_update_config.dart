import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import '../device_information_service/device_info.dart';
import '../remote_config_service/remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles app update logic and shows appropriate bottom sheet
/// Returns true when user can proceed to next screen
Future<bool> handleAppUpdate(BuildContext context) async {
  try {
    final currentBuild = await DeviceInformation.instance.buildNo;
    final AppUpdateConfig config = RemoteConfigUtil.instance.appUpdateConfig;
    // Parse build numbers safely
    final int currentBuildNum = int.tryParse(currentBuild.toString()) ?? 0;

    if (currentBuildNum <= 0) {
      // If we can't get build number, allow user to proceed
      return true;
    }

    if (Platform.isIOS) {
      if (currentBuildNum < config.iosMinimumBuildVersion) {
        await showForceUpdateSheet(context, config: config);
        return false; // User must update, cannot proceed
      } else if (currentBuildNum < config.iosLatestBuildVersion) {
        await showOptionalUpdateSheet(context, config: config);
        return true; // User can proceed regardless of choice
      }
    } else if (Platform.isAndroid) {
      if (currentBuildNum < config.androidMinimumBuildVersion) {
        await showForceUpdateSheet(context, config: config);
        return false; // User must update, cannot proceed
      } else if (currentBuildNum < config.androidLatestBuildVersion) {
        await showOptionalUpdateSheet(context, config: config);
        return true; // User can proceed regardless of choice
      }
    }

    // No update needed, proceed to next screen
    return true;
  } catch (e, s) {
    debugPrint('Error checking app update: $e $s');
    // On error, allow user to proceed to avoid blocking them
    return true;
  }
}

Future<void> showOptionalUpdateSheet(
  BuildContext context, {
  required AppUpdateConfig config,
}) async {
  if (!context.mounted) return;

  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bottomSheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }
                    },
                  ),
                ],
              ),
              const Icon(
                Icons.system_update_alt,
                size: 64,
                color: AppColors.themeColor,
              ),
              const SizedBox(height: 16),
              Text(
                Platform.isIOS
                    ? config.iosUpdateTitle
                    : config.androidUpdateTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                Platform.isIOS
                    ? config.iosUpdateDescription
                    : config.androidUpdateDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _openStore(
                          bottomSheetContext,
                          updateUrl: Platform.isIOS
                              ? config.iosUpdateUrl
                              : config.androidUpdateUrl,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparentColor,
                          shadowColor: AppColors.transparentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'UPDATE',
                          style: TextStyle(
                            color: AppColors.textOnDarkColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
      );
    },
  );
}

Future<void> showForceUpdateSheet(
  BuildContext context, {
  required AppUpdateConfig config,
}) async {
  if (!context.mounted) return;

  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bottomSheetContext) {
      return PopScope(
        canPop: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update_alt,
                  size: 64,
                  color: AppColors.themeColor,
                ),
                const SizedBox(height: 16),
                Text(
                  Platform.isIOS
                      ? config.iosUpdateTitle
                      : config.androidUpdateTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  Platform.isIOS
                      ? config.iosUpdateDescription
                      : config.androidUpdateDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.themeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _openStore(
                        bottomSheetContext,
                        updateUrl: Platform.isIOS
                            ? config.iosUpdateUrl
                            : config.androidUpdateUrl,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparentColor,
                        shadowColor: AppColors.transparentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'UPDATE NOW',
                        style: TextStyle(
                          color: AppColors.textOnDarkColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _openStore(
  BuildContext context, {
  required String updateUrl,
}) async {
  try {
    final Uri storeUri = Uri.parse(updateUrl);

    final canLaunch = await canLaunchUrl(storeUri);

    if (canLaunch) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open store. Please update manually.'),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Error opening store: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening store. Please try again.')),
      );
    }
  }
}
