import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/auth/repositories/auth_repository.dart';
import 'package:wowcare/domain/features/auth/usecases/forgot_password_usecase.dart';

/// Answers a reset request with [result].
class _FakeAuthRepository implements AuthRepository {
  Either<Failure, String> result = const Right('Reset email sent');

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final logs = <SentryLog>[];
  late _FakeAuthRepository repository;

  setUp(() async {
    logs.clear();
    repository = _FakeAuthRepository();
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

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('a reset request logs its outcome and never the email', () async {
    final useCase = ForgotPasswordUseCase(repository);

    await useCase('asha@example.com');
    repository.result = const Left(NetworkFailure('Network error'));
    final failed = await useCase('asha@example.com');
    await settle();

    expect(failed.isLeft(), isTrue);
    expect(logs.map((log) => log.body), [
      'auth.forgot_password.succeeded',
      'auth.forgot_password.failed',
    ]);
    expect(logs.last.attributes['failure']!.value, 'network');
    for (final log in logs) {
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(contains('asha'))),
      );
    }
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
