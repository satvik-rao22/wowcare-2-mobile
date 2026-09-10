import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/entities/video_validation_result.dart';
import 'package:wowcare/domain/features/activity/repositories/video_probe_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/validate_video_for_upload_usecase.dart';

class _StubProbe implements VideoProbeRepository {
  _StubProbe(this.result);
  final VideoProbe result;
  int calls = 0;

  @override
  Future<VideoProbe> probe(String path) async {
    calls++;
    return result;
  }
}

/// Minimal but real ISO-BMFF header: `....ftypisom`. `lookupMimeType` keys off
/// the `ftyp` box at offset 4, so this sniffs as video/mp4 the same way a real
/// capture does.
Uint8List mp4Header() => Uint8List.fromList(<int>[
  0x00, 0x00, 0x00, 0x18, // box size
  0x66, 0x74, 0x79, 0x70, // 'ftyp'
  0x69, 0x73, 0x6F, 0x6D, // 'isom'
  0x00, 0x00, 0x02, 0x00,
  0x69, 0x73, 0x6F, 0x6D,
  0x69, 0x73, 0x6F, 0x32,
]);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('video_validation');
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  File writeVideo(String name, {int padTo = 4096, List<int>? header}) {
    final f = File('${dir.path}${Platform.pathSeparator}$name');
    final bytes = <int>[...(header ?? mp4Header())];
    if (bytes.length < padTo) {
      bytes.addAll(List<int>.filled(padTo - bytes.length, 0));
    }
    f.writeAsBytesSync(bytes);
    return f;
  }

  ValidateVideoForUploadUseCase sut({VideoProbe? probe}) =>
      ValidateVideoForUploadUseCase(
        _StubProbe(
          probe ?? const VideoProbe(decodable: true, durationMs: 5000),
        ),
      );

  test('accepts a well-formed video and reports what it measured', () async {
    final file = writeVideo('good.mp4');
    final result = await sut().call(file.path);

    expect(result, isA<VideoValidationAccepted>());
    final accepted = result as VideoValidationAccepted;
    expect(accepted.sizeBytes, 4096);
    expect(accepted.durationMs, 5000);
    expect(accepted.mimeType, 'video/mp4');
    expect(result.isValid, isTrue);
  });

  group('the three checks the audit found missing', () {
    test(
      'size > 0 — an EMPTY capture is rejected. It previously passed, because '
      '`0 > maxSize` is false, and failed server-side instead',
      () async {
        final file = File('${dir.path}${Platform.pathSeparator}empty.mp4')
          ..writeAsBytesSync(<int>[]);
        final result = await sut().call(file.path);
        expect(
          (result as VideoValidationRejected).reason,
          VideoRejectionReason.emptyFile,
        );
      },
    );

    test(
      'duration > 0 — a file that decodes to a zero-length track is rejected, '
      'the half of the truncated-capture case that does not throw',
      () async {
        final file = writeVideo('zero.mp4');
        final result = await sut(
          probe: const VideoProbe(decodable: true, durationMs: 0),
        ).call(file.path);
        expect(
          (result as VideoValidationRejected).reason,
          VideoRejectionReason.zeroDuration,
        );
      },
    );

    test(
      'mime is sniffed from the HEADER, not the extension — a text file named '
      '.mp4 must not reach the uploader just because it was named convincingly',
      () async {
        final file = File('${dir.path}${Platform.pathSeparator}fake.mp4')
          ..writeAsStringSync('this is definitely not a video, at all, ever');
        final result = await sut().call(file.path);
        expect(
          (result as VideoValidationRejected).reason,
          VideoRejectionReason.unsupportedMimeType,
        );
      },
    );
  });

  group('explicit corrupt-file handling', () {
    test(
      'a file the decoder cannot read is rejected as undecodable — the moov-'
      'atom case, named explicitly rather than inferred from duration',
      () async {
        final file = writeVideo('truncated.mp4');
        final result = await sut(probe: VideoProbe.undecodable).call(file.path);
        expect(
          (result as VideoValidationRejected).reason,
          VideoRejectionReason.undecodable,
        );
      },
    );

    test('the decoder is not even consulted for a file that fails a cheaper rule', () async {
      final probe = _StubProbe(
        const VideoProbe(decodable: true, durationMs: 1000),
      );
      final file = File('${dir.path}${Platform.pathSeparator}empty.mp4')
        ..writeAsBytesSync(<int>[]);
      await ValidateVideoForUploadUseCase(probe).call(file.path);
      expect(probe.calls, 0, reason: 'ordered cheapest-first');
    });
  });

  group('the four checks that already existed', () {
    test('a missing file is rejected', () async {
      final result = await sut().call(
        '${dir.path}${Platform.pathSeparator}nope.mp4',
      );
      expect(
        (result as VideoValidationRejected).reason,
        VideoRejectionReason.fileMissing,
      );
    });

    test('a file over the size maximum is rejected, and reports its size', () async {
      final file = writeVideo(
        'huge.mp4',
        padTo: VideoUploadLimits.maxSizeBytes + 1,
      );
      final result = await sut().call(file.path);
      final rejected = result as VideoValidationRejected;
      expect(rejected.reason, VideoRejectionReason.tooLarge);
      expect(rejected.sizeBytes, VideoUploadLimits.maxSizeBytes + 1);
    });

    test('a file over the duration maximum is rejected', () async {
      final file = writeVideo('long.mp4');
      final result = await sut(
        probe: VideoProbe(
          decodable: true,
          durationMs: VideoUploadLimits.maxDurationSeconds * 1000 + 1,
        ),
      ).call(file.path);
      expect(
        (result as VideoValidationRejected).reason,
        VideoRejectionReason.tooLong,
      );
    });

    test('a file exactly at the duration maximum is accepted', () async {
      final file = writeVideo('exact.mp4');
      final result = await sut(
        probe: VideoProbe(
          decodable: true,
          durationMs: VideoUploadLimits.maxDurationSeconds * 1000,
        ),
      ).call(file.path);
      expect(result, isA<VideoValidationAccepted>());
    });
  });

  test('every rejection reason maps to exactly one rule', () {
    // Guards against a reason being added without a rule, or vice versa.
    expect(VideoRejectionReason.values.length, 7);
  });
}
