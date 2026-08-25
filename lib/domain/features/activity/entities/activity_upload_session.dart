import 'package:equatable/equatable.dart';

class ActivityUploadSession extends Equatable {
  const ActivityUploadSession({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;

  @override
  List<Object?> get props => [sessionCode, documentApiBasePath];
}
