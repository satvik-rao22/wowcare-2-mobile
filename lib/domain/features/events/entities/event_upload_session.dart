import 'package:equatable/equatable.dart';

/// A shared upload session for event attachments
/// (`POST /events/upload-session`), opened against the Events/Todo service
/// *before* the event exists; the resulting asset codes are then passed to
/// create/update as `assetCodes`.
///
/// [documentApiBasePath] is the base path the response hands back for the
/// follow-up document-microservice calls (presign / complete / poll).
///
/// Mirrors `TaskUploadSession` — same service, same flow, different domain.
class EventUploadSession extends Equatable {
  const EventUploadSession({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;

  @override
  List<Object?> get props => [sessionCode, documentApiBasePath];
}
