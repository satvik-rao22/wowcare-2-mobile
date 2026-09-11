import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/usecases/video_container_sniffer.dart';

Uint8List bytes(List<int> b, {int padTo = 64}) {
  final out = <int>[...b];
  if (out.length < padTo) out.addAll(List<int>.filled(padTo - out.length, 0));
  return Uint8List.fromList(out);
}

List<int> ascii(String s) => s.codeUnits;

/// `[size][ftyp][brand]`
Uint8List isoBmff(String brand) =>
    bytes(<int>[0, 0, 0, 0x18, ...ascii('ftyp'), ...ascii(brand)]);

Uint8List ebml(String docType) => bytes(<int>[
  0x1A, 0x45, 0xDF, 0xA3,
  0x9F, 0x42, 0x86, 0x81, 0x01,
  0x42, 0x82, docType.length,
  ...ascii(docType),
]);

void main() {
  group('accepted containers', () {
    test('MP4 brands all resolve to video/mp4', () {
      for (final brand in <String>['isom', 'iso2', 'mp41', 'mp42', 'avc1', 'dash']) {
        expect(VideoContainerSniffer.sniff(isoBmff(brand)), 'video/mp4',
            reason: brand);
      }
    });

    test(
      'QuickTime is identified as video/quicktime — package:mime returns NULL '
      'for this, which is why the sniffer is hand-rolled',
      () {
        expect(VideoContainerSniffer.sniff(isoBmff('qt  ')), 'video/quicktime');
      },
    );

    test(
      'WebM is identified as video/webm — package:mime reports audio/weba for '
      'these bytes, because EBML magic is shared with the audio profile',
      () {
        expect(VideoContainerSniffer.sniff(ebml('webm')), 'video/webm');
      },
    );
  });

  group('rejections', () {
    test('plain text is not a video, whatever it is named', () {
      expect(
        VideoContainerSniffer.sniff(bytes(ascii('this is not a video at all'))),
        isNull,
      );
    });

    test(
      'Matroska is rejected: same EBML magic as WebM, but not in the backend'
      "'s accepted set",
      () {
        expect(VideoContainerSniffer.sniff(ebml('matroska')), isNull);
      },
    );

    test('an EBML header with no readable DocType is rejected, not guessed', () {
      expect(
        VideoContainerSniffer.sniff(
          Uint8List.fromList(<int>[0x1A, 0x45, 0xDF, 0xA3]),
        ),
        isNull,
      );
    });

    test('a truncated header is rejected rather than throwing', () {
      for (final len in <int>[0, 1, 3, 4, 8, 11]) {
        expect(
          VideoContainerSniffer.sniff(
            Uint8List.fromList(List<int>.filled(len, 0x66)),
          ),
          isNull,
          reason: 'length $len',
        );
      }
    });

    test('a JPEG is rejected — right family of media, wrong kind', () {
      expect(
        VideoContainerSniffer.sniff(bytes(<int>[0xFF, 0xD8, 0xFF, 0xE0])),
        isNull,
      );
    });
  });
}
