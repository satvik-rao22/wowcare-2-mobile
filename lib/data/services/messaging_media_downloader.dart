import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Temp-directory path + raw URL→file download for the messaging full-screen
/// media viewer, kept OUT of the presentation layer (Mandate 5: no direct
/// `Dio`/`path_provider` in a view).
///
/// Same mechanism the view used inline: the OS temp directory as the download
/// target, and `Dio().download` to materialize a remote URL to a local file —
/// behaviour unchanged.
Future<String> messagingMediaTempDirPath() async =>
    (await getTemporaryDirectory()).path;

Future<void> downloadMessagingMediaToFile(String url, String outPath) =>
    Dio().download(url, outPath);
