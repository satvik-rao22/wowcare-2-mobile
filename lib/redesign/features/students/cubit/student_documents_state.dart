part of 'student_documents_cubit.dart';

enum DocumentsStatus { loading, ready, failed }

/// The four states the add-a-document card cycles through.
enum UploadStatus {
  /// Nothing chosen. Name it, pick a type, choose a file.
  idle,

  /// On its way, with the bar filling.
  sending,

  /// On file.
  done,

  /// The connection went. Nothing was saved, and Retry sends it again.
  failed,
}

@immutable
class StudentDocumentsState extends Equatable {
  const StudentDocumentsState({
    required this.studentId,
    this.studentName = '',
    this.classroomName = '',
    this.status = DocumentsStatus.loading,
    this.documents = const <StudentDocumentItem>[],
    this.draft = const DocumentDraft(),
    this.upload = UploadStatus.idle,
    this.percentSent = 0,
  });

  final String studentId;
  final String studentName;
  final String classroomName;

  final DocumentsStatus status;
  final List<StudentDocumentItem> documents;

  final DocumentDraft draft;
  final UploadStatus upload;

  /// 0 to 1.
  final double percentSent;

  bool get isLoading => status == DocumentsStatus.loading;
  bool get isFailed => status == DocumentsStatus.failed;

  bool get isSending => upload == UploadStatus.sending;
  bool get isDone => upload == UploadStatus.done;
  bool get hasUploadFailed => upload == UploadStatus.failed;

  /// The bar shows once there is something to measure.
  bool get showsProgress => upload != UploadStatus.idle;

  /// The type and expiry fields are put away once a file is on its way to
  /// somewhere, because they are no longer the thing being decided.
  bool get showsFields => upload == UploadStatus.idle || isSending;

  /// A whole number, for the "62% sent" line.
  int get percentLabel => (percentSent * 100).round();

  String get initials {
    final parts = studentName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get firstName => studentName.split(' ').first;

  StudentDocumentsState copyWith({
    String? studentName,
    String? classroomName,
    DocumentsStatus? status,
    List<StudentDocumentItem>? documents,
    DocumentDraft? draft,
    UploadStatus? upload,
    double? percentSent,
  }) => StudentDocumentsState(
    studentId: studentId,
    studentName: studentName ?? this.studentName,
    classroomName: classroomName ?? this.classroomName,
    status: status ?? this.status,
    documents: documents ?? this.documents,
    draft: draft ?? this.draft,
    upload: upload ?? this.upload,
    percentSent: percentSent ?? this.percentSent,
  );

  @override
  List<Object?> get props => [
    studentId,
    studentName,
    classroomName,
    status,
    documents,
    draft,
    upload,
    percentSent,
  ];
}
