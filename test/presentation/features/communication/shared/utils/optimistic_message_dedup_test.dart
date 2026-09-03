import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/optimistic_message_dedup.dart';

MessageEntity _msg({
  required String code,
  String? localTempCode,
  String text = 'Ok',
  String senderCode = 'USR-1',
  required MessageStatus status,
  required DateTime sentAt,
}) {
  return MessageEntity(
    id: code,
    code: code,
    conversationCode: 'CONV-1',
    senderCode: senderCode,
    senderName: 'Sender',
    senderRole: ParticipantRole.staff,
    text: text,
    messageType: MessageType.text,
    status: status,
    sentAt: sentAt,
    organizationCode: 'ORG-1',
    schoolCode: 'SCH-1',
    localTempCode: localTempCode,
  );
}

final _t0 = DateTime.utc(2026, 1, 1, 12, 0, 0);

void main() {
  group('unconfirmedOptimisticMessages', () {
    test('empty pending returns empty', () {
      expect(
        unconfirmedOptimisticMessages(pending: const [], fresh: const []),
        isEmpty,
      );
    });

    test(
        'TWO identical quick optimistic messages + ONE confirmation → exactly '
        'one stays pending (the confirmation absorbs only one)', () {
      final p1 = _msg(
          code: '', localTempCode: 'T1', status: MessageStatus.pending, sentAt: _t0);
      final p2 = _msg(
          code: '',
          localTempCode: 'T2',
          status: MessageStatus.pending,
          sentAt: _t0.add(const Duration(seconds: 2)));
      final confirmed = _msg(
          code: 'SRV-1',
          status: MessageStatus.sent,
          sentAt: _t0.add(const Duration(seconds: 1)));

      final survivors = unconfirmedOptimisticMessages(
        pending: [p1, p2],
        fresh: [confirmed],
      );

      // Exactly one optimistic message survives — the other was confirmed.
      // (The old `.any()` match dropped BOTH, losing a message.)
      expect(survivors.length, 1);
      // The nearest-in-time pending (p1) is the one claimed; p2 survives.
      expect(survivors.single.localTempCode, 'T2');
    });

    test('TWO identical optimistic + TWO confirmations → none survive', () {
      final p1 = _msg(
          code: '', localTempCode: 'T1', status: MessageStatus.pending, sentAt: _t0);
      final p2 = _msg(
          code: '',
          localTempCode: 'T2',
          status: MessageStatus.pending,
          sentAt: _t0.add(const Duration(seconds: 2)));
      final c1 = _msg(
          code: 'SRV-1',
          status: MessageStatus.sent,
          sentAt: _t0.add(const Duration(seconds: 1)));
      final c2 = _msg(
          code: 'SRV-2',
          status: MessageStatus.sent,
          sentAt: _t0.add(const Duration(seconds: 3)));

      final survivors = unconfirmedOptimisticMessages(
        pending: [p1, p2],
        fresh: [c1, c2],
      );

      expect(survivors, isEmpty);
    });

    test('a pending whose code already appears in fresh is dropped', () {
      final p = _msg(
          code: 'SRV-1',
          localTempCode: 'T1',
          status: MessageStatus.pending,
          sentAt: _t0);
      final confirmed =
          _msg(code: 'SRV-1', status: MessageStatus.sent, sentAt: _t0);

      expect(
        unconfirmedOptimisticMessages(pending: [p], fresh: [confirmed]),
        isEmpty,
      );
    });

    test('a FAILED message is always kept even if text matches a confirmation',
        () {
      final failed = _msg(
          code: '',
          localTempCode: 'T1',
          status: MessageStatus.failed,
          sentAt: _t0);
      final confirmed = _msg(
          code: 'SRV-1',
          status: MessageStatus.sent,
          sentAt: _t0.add(const Duration(seconds: 1)));

      final survivors = unconfirmedOptimisticMessages(
        pending: [failed],
        fresh: [confirmed],
      );
      expect(survivors.single.localTempCode, 'T1');
    });

    test('a confirmation outside the window does not absorb the pending', () {
      final p = _msg(
          code: '', localTempCode: 'T1', status: MessageStatus.pending, sentAt: _t0);
      final farConfirmed = _msg(
          code: 'SRV-1',
          status: MessageStatus.sent,
          sentAt: _t0.add(const Duration(seconds: 45)));

      final survivors = unconfirmedOptimisticMessages(
        pending: [p],
        fresh: [farConfirmed],
        window: const Duration(seconds: 30),
      );
      expect(survivors.single.localTempCode, 'T1');
    });

    test('a different-sender confirmation does not absorb the pending', () {
      final p = _msg(
          code: '', localTempCode: 'T1', status: MessageStatus.pending, sentAt: _t0);
      final other = _msg(
          code: 'SRV-1',
          senderCode: 'USR-2',
          status: MessageStatus.sent,
          sentAt: _t0);

      final survivors =
          unconfirmedOptimisticMessages(pending: [p], fresh: [other]);
      expect(survivors.single.localTempCode, 'T1');
    });
  });
}
