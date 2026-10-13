import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// What [FileActions.open] reports: whether an app took the file, and if not,
/// why (e.g. no app on the device opens this type).
typedef OpenFileResult = ({bool opened, String message});

/// [FileActions.saveToGallery] failed; [message] is ready to show the user
/// ("Not enough space for storage.", "Unsupported file formats."…).
class GallerySaveException implements Exception {
  const GallerySaveException(this.message);

  final String message;

  @override
  String toString() => 'GallerySaveException: $message';
}

/// The one place the app hands a finished file to the OS: open it in another
/// app, share it, or save it to the photo gallery.
///
/// ```dart
/// final result = await FileActions.open(path, mimeType: 'application/pdf');
/// if (!result.opened) showError(result.message);
///
/// await FileActions.share(path, fileName: 'invoice-12.pdf');
///
/// // Check access before downloading, so a refusal wastes nothing:
/// if (!await FileActions.ensureGalleryAccess()) return;
/// await FileActions.saveToGallery(downloadedPath, isVideo: false);
/// ```
///
/// Which file util?
/// | Need                                        | Use                       |
/// |---------------------------------------------|---------------------------|
/// | Name, extension, MIME type, app folders     | FileUtils                 |
/// | Let the user pick a file / photo / video    | FilePickerUtils           |
/// | Download a URL into a file                  | FileDownloadService       |
/// | Open, share or save a file to the gallery   | FileActions (this file)   |
///
/// The open_filex, share_plus and gal plugins stay inside this file.
abstract final class FileActions {
  /// Opens the file at [path] in an app on the device.
  ///
  /// A failed hand-off comes back as `opened: false`, not an exception: on
  /// Android, "no app opens this type" (routine for XLSX) is reported this
  /// way, so a caller that ignored the result would claim success.
  static Future<OpenFileResult> open(String path, {String? mimeType}) async {
    final result = await OpenFilex.open(path, type: mimeType);
    return (opened: result.type == ResultType.done, message: result.message);
  }

  /// Shows the system share sheet for the file at [path]. [fileName] is the
  /// name the receiving app sees.
  static Future<void> share(
    String path, {
    String? mimeType,
    String? fileName,
  }) async {
    await Share.shareXFiles([
      XFile(path, mimeType: mimeType),
    ], fileNameOverrides: fileName == null ? null : [fileName]);
  }

  /// Whether the app may save to the photo gallery, asking once if needed.
  /// When refused, tells the user why and returns false.
  ///
  /// Call it before downloading what you want to save.
  static Future<bool> ensureGalleryAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) return true;
    await Gal.requestAccess(toAlbum: true);
    if (await Gal.hasAccess(toAlbum: true)) return true;
    _show(AppStrings.mediaPermissionRequired);
    return false;
  }

  /// Saves the photo or video at [path] to the gallery. Throws a
  /// [GallerySaveException] with a user-readable message if the OS refuses
  /// (e.g. an unsupported format or a full device).
  static Future<void> saveToGallery(
    String path, {
    required bool isVideo,
  }) async {
    AppLogger.d('[FileActions] Saving ${isVideo ? 'video' : 'photo'} $path');
    try {
      await (isVideo ? Gal.putVideo(path) : Gal.putImage(path));
    } on GalException catch (e) {
      throw GallerySaveException(e.type.message);
    }
  }

  /// A context inside the root navigator — still valid after the screen that
  /// started the action has closed.
  static void _show(String message) {
    final context = CoreUtils.rootNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isWarning: true,
    );
  }
}
