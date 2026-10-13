import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
// ignore: implementation_imports
import 'package:gal/src/gal_platform_interface.dart';
import 'package:wowcare/core/utils/file_utils/file_actions.dart';

/// Stands in for the native gallery.
final class _FakeGallery extends GalPlatform {
  bool hasAccessNow = false;

  /// What the OS permission prompt answers.
  bool grantOnRequest = false;
  int requestCount = 0;
  final saved = <String>[];
  GalExceptionType? failWith;

  @override
  Future<bool> hasAccess({bool toAlbum = false}) async => hasAccessNow;

  @override
  Future<bool> requestAccess({bool toAlbum = false}) async {
    requestCount++;
    return hasAccessNow = grantOnRequest;
  }

  @override
  Future<void> putImage(String path, {String? album}) => _put('image:$path');

  @override
  Future<void> putVideo(String path, {String? album}) => _put('video:$path');

  Future<void> _put(String entry) async {
    final type = failWith;
    if (type != null) {
      throw GalException(
        type: type,
        platformException: PlatformException(code: type.name),
        stackTrace: StackTrace.empty,
      );
    }
    saved.add(entry);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGallery gallery;
  setUp(() => GalPlatform.instance = gallery = _FakeGallery());

  group('ensureGalleryAccess', () {
    test('already allowed → true, no prompt', () async {
      gallery.hasAccessNow = true;
      expect(await FileActions.ensureGalleryAccess(), isTrue);
      expect(gallery.requestCount, 0);
    });

    test('asks once; allowed → true', () async {
      gallery.grantOnRequest = true;
      expect(await FileActions.ensureGalleryAccess(), isTrue);
      expect(gallery.requestCount, 1);
    });

    test('asks once; refused → false', () async {
      expect(await FileActions.ensureGalleryAccess(), isFalse);
      expect(gallery.requestCount, 1);
    });
  });

  group('saveToGallery', () {
    test('photos and videos go to the right gallery call', () async {
      await FileActions.saveToGallery('/tmp/a.jpg', isVideo: false);
      await FileActions.saveToGallery('/tmp/b.mp4', isVideo: true);
      expect(gallery.saved, ['image:/tmp/a.jpg', 'video:/tmp/b.mp4']);
    });

    test('an OS refusal becomes a GallerySaveException with its message', () {
      gallery.failWith = GalExceptionType.notEnoughSpace;
      expect(
        FileActions.saveToGallery('/tmp/a.jpg', isVideo: false),
        throwsA(
          isA<GallerySaveException>().having(
            (e) => e.message,
            'message',
            GalExceptionType.notEnoughSpace.message,
          ),
        ),
      );
    });
  });
}
