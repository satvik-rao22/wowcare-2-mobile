import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';

/// What the Forte card WebView pops with when a card is tokenized.
const _tokenized = {
  'success': true,
  'paymentType': 'card',
  'data': {
    'onetime_token': 'ott_secret_123',
    'card_type': 'visa',
    'last_4': '4242',
  },
  'accountHolder': 'JANE DOE',
  'makePrimary': true,
  'makeAutopay': false,
};

void main() {
  group('cardTokenizeFailureOf', () {
    test('a returned one-time token is a success', () {
      expect(cardTokenizeFailureOf(_tokenized), isNull);
      expect(
        cardTokenizeFailureOf({
          'success': true,
          'data': {'onetimeToken': 'ott_1'},
        }),
        isNull,
      );
    });

    test('closing the WebView without a result is cancelled', () {
      expect(cardTokenizeFailureOf(null), EventFailure.cancelled);
    });

    test('a card that does not match the picked type is validation', () {
      expect(
        cardTokenizeFailureOf({
          'success': false,
          'error': {
            'event': 'card_type_mismatch',
            'response_description': 'The card you entered is a Visa',
          },
        }),
        EventFailure.validation,
      );
    });

    test('the Forte script failing to load is network', () {
      expect(
        cardTokenizeFailureOf({
          'success': false,
          'error': 'Unable to load Forte payment library',
        }),
        EventFailure.network,
      );
    });

    test('any other error, or a success without a token, is unknown', () {
      for (final result in <Object>[
        {
          'success': false,
          'error': {'response_code': 'F01', 'response_description': 'Bad'},
        },
        {'success': false, 'error': 'Invalid payload'},
        {'success': false},
        {'success': true, 'data': <String, Object>{}},
        {'success': true, 'data': 'ott_1'},
        'not a map',
      ]) {
        expect(cardTokenizeFailureOf(result), EventFailure.unknown);
      }
    });
  });

  group('logging', () {
    final logs = <SentryLog>[];

    setUp(() async {
      logs.clear();
      await Sentry.init((options) {
        options
          ..dsn = 'https://key@o1.ingest.sentry.io/1'
          ..enableLogs = true
          ..transport = _DiscardingTransport()
          ..beforeSendLog = (log) {
            logs.add(log);
            return log;
          };
      });
    });

    tearDown(() => Sentry.close());

    // The screen tracks its WebView push exactly like this.
    Future<Object?> session(Object? popped) => AppEvents.track(
      AppEvent.billingCardTokenize,
      () async => popped,
      failureOf: cardTokenizeFailureOf,
    );

    test('one line per session, and never the token or card', () async {
      final returned = await session(_tokenized);
      await session(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(returned, same(_tokenized));
      expect(logs.map((log) => log.body), [
        'billing.card_tokenize.succeeded',
        'billing.card_tokenize.failed',
      ]);
      expect(logs.last.attributes['failure']!.value, 'cancelled');
      final logged = [
        for (final log in logs)
          for (final attribute in log.attributes.values) '${attribute.value}',
      ].join(' ');
      for (final value in ['ott_secret_123', '4242', 'visa', 'JANE DOE']) {
        expect(logged, isNot(contains(value)));
      }
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
