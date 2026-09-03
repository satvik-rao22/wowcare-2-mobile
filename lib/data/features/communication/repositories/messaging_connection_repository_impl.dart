import 'package:wowcare/data/features/communication/realtime/message_realtime_data_source.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_connection_status.dart';
import 'package:wowcare/domain/features/communication/repositories/messaging_connection_repository.dart';

/// Thin adapter over the realtime datasource's connection tracker. The
/// datasource is a singleton, so this reflects the currently-active message
/// subscription's health.
class MessagingConnectionRepositoryImpl
    implements MessagingConnectionRepository {
  MessagingConnectionRepositoryImpl(this._realtime);

  final MessageRealtimeDataSource _realtime;

  @override
  Stream<MessagingConnectionStatus> watchConnectionStatus() =>
      _realtime.connectionStatusStream;

  @override
  MessagingConnectionStatus get currentStatus => _realtime.connectionStatus;
}
