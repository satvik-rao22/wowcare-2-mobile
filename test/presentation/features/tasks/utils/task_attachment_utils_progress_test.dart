import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';

void main() {
  // The upload-on-pick loop stops when a round achieves nothing, so that it
  // can't spin against the network. That check must be about the *files* the
  // round owned — a length comparison abandons anything picked mid-flight.
  group('uploadRoundMadeProgress', () {
    test('a round that uploaded its file made progress', () {
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: {'/tmp/a.pdf'},
          stillOutstanding: const <String>{},
        ),
        isTrue,
      );
    });

    test('progress counts even when a new file was picked mid-flight', () {
      // The regression: one file in, one file out, so the *count* is unchanged —
      // but the attempted file did upload, so the loop must continue and pick
      // up the newly added one instead of silently leaving it unuploaded.
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: {'/tmp/a.pdf'},
          stillOutstanding: {'/tmp/b.png'},
        ),
        isTrue,
      );
    });

    test('a partial round still counts as progress', () {
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: {'/tmp/a.pdf', '/tmp/b.png'},
          stillOutstanding: {'/tmp/b.png'},
        ),
        isTrue,
      );
    });

    test('a round that resolved none of its own files has stalled', () {
      // Stop here: retrying immediately would hammer the network forever.
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: {'/tmp/a.pdf'},
          stillOutstanding: {'/tmp/a.pdf'},
        ),
        isFalse,
      );
    });

    test('a stall is a stall even when other files were added', () {
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: {'/tmp/a.pdf'},
          stillOutstanding: {'/tmp/a.pdf', '/tmp/b.png'},
        ),
        isFalse,
      );
    });

    test('nothing attempted is not progress, so the loop exits', () {
      expect(
        TaskAttachmentUtils.uploadRoundMadeProgress(
          attempted: const <String>{},
          stillOutstanding: const <String>{},
        ),
        isFalse,
      );
    });
  });
}
