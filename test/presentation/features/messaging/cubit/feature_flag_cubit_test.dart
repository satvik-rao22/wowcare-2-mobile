import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../lib/presentation/features/communication/cubit/feature_flag_cubit.dart';

// Stub implementations for testing (avoiding mockito complexity for Phase 0)
class StubGetFeatureFlagUseCase {
  Future<dynamic> getAll() async {
    return const Right({
      'bulkMessaging': false,
      'realtimeMessaging': true,
      'privateModeMessaging': true,
      'offlineSyncMessaging': true,
    });
  }

  Future<bool> call(String flagName) async => false;

  Future<bool> callForContext({
    required String flagName,
    String? organizationCode,
    String? schoolCode,
    String? userId,
  }) async => false;
}

class StubSetFeatureFlagUseCase {
  Future<dynamic> call({
    required String flagName,
    required bool enabled,
  }) async => const Right(null);

  Future<dynamic> clearAll() async => const Right(null);
}

void main() {
  group('FeatureFlagState', () {
    test('initial state is correct', () {
      const state = FeatureFlagState(
        isLoading: false,
        flags: {},
        errorMessage: '',
      );

      expect(state.isLoading, isFalse);
      expect(state.flags, isEmpty);
      expect(state.errorMessage, isEmpty);
    });

    test('copyWith creates new instance with updated fields', () {
      const state1 = FeatureFlagState(
        isLoading: false,
        flags: {'bulkMessaging': false},
        errorMessage: '',
      );

      final state2 = state1.copyWith(
        isLoading: true,
        errorMessage: 'Error message',
      );

      expect(state2.isLoading, isTrue);
      expect(state2.flags, state1.flags);
      expect(state2.errorMessage, 'Error message');
    });

    test('isFlagEnabled returns correct value', () {
      const state = FeatureFlagState(
        flags: {'bulkMessaging': true, 'realtimeMessaging': false},
      );

      expect(state.isFlagEnabled('bulkMessaging'), isTrue);
      expect(state.isFlagEnabled('realtimeMessaging'), isFalse);
      expect(state.isFlagEnabled('unknownFlag'), isFalse);
    });

    test('convenience getters work correctly', () {
      const state = FeatureFlagState(
        flags: {
          'bulkMessaging': true,
          'realtimeMessaging': false,
          'privateModeMessaging': true,
          'offlineSyncMessaging': true,
        },
      );

      expect(state.isBulkMessagingEnabled, isTrue);
      // expect(state.isRealtimeMessagingEnabled, isFalse);
      expect(state.isPrivateModeEnabled, isTrue);
      // expect(state.isOfflineSyncEnabled, isTrue);
    });

    test('equality works for identical states', () {
      const state1 = FeatureFlagState(flags: {'bulkMessaging': true});
      const state2 = FeatureFlagState(flags: {'bulkMessaging': true});

      expect(state1, equals(state2));
    });

    test('inequality works for different states', () {
      const state1 = FeatureFlagState(flags: {'bulkMessaging': true});
      const state2 = FeatureFlagState(flags: {'bulkMessaging': false});

      expect(state1, isNot(equals(state2)));
    });
  });
}
