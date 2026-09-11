import 'package:equatable/equatable.dart';

/// A session for uploading a classroom logo asset. Returned by the
/// upload-session endpoint; [sessionCode] is then handed to the shared
/// asset upload flow (presign → upload → finalize).
class ClassroomLogoUploadSession extends Equatable {
  const ClassroomLogoUploadSession({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;

  @override
  List<Object?> get props => [sessionCode, documentApiBasePath];
}
