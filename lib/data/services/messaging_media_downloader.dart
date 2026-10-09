import 'package:dio/dio.dart';

/// Raw URL→file download for the messaging full-screen media viewer, kept OUT
/// of the presentation layer (Mandate 5: no direct `Dio` in a view). The
/// target path comes from FileUtils.tempFilePath.
Future<void> downloadMessagingMediaToFile(String url, String outPath) =>
    Dio().download(url, outPath);
