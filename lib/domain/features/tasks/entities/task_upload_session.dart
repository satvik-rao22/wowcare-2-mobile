import 'package:equatable/equatable.dart';

/// A school-wide shared upload session for task attachments (Tasks API §8
/// `POST /tasks/upload-session`). It is opened against events-todo-service
/// *before* the task exists; the resulting asset codes are then passed to
/// §1 `assetCodes`.
///
/// [documentApiBasePath] is the base path the response hands back for the
/// follow-up document-microservice calls (presign / complete / poll).
class TaskUploadSession extends Equatable {
  const TaskUploadSession({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;

  @override
  List<Object?> get props => [sessionCode, documentApiBasePath];
}
