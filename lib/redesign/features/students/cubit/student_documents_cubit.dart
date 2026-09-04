import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

part 'student_documents_state.dart';

/// 5f. The files on a student's record, and adding one.
///
/// The upload has four states because a phone upload has four: nothing
/// chosen, sending, on file, and the one where the connection went. The last
/// keeps the type and the expiry that were typed, so Retry sends the same
/// thing again rather than asking for it twice.
class StudentDocumentsCubit extends Cubit<StudentDocumentsState> {
  StudentDocumentsCubit({
    required StudentsSource source,
    required StudentDocumentsArgs args,
  }) : _source = source,
       super(
         StudentDocumentsState(
           studentId: args.studentId,
           studentName: args.studentName,
           classroomName: args.classroomName,
         ),
       );

  final StudentsSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: DocumentsStatus.loading));

    try {
      final documents = await _source.loadDocuments(state.studentId);
      if (isClosed) return;

      // A deep link arrives with an id and nothing else, so the header's
      // name and classroom are fetched only when they did not come with it.
      var next = state.copyWith(
        status: DocumentsStatus.ready,
        documents: documents,
      );
      if (next.studentName.isEmpty) {
        final record = await _source.loadProfile(state.studentId);
        if (isClosed) return;
        next = next.copyWith(
          studentName: record.student.fullName,
          classroomName: record.student.classroomName,
        );
      }
      emit(next);
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: DocumentsStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void setType(String type) =>
      emit(state.copyWith(draft: state.draft.copyWith(type: type)));

  void setExpiry(DateTime date) =>
      emit(state.copyWith(draft: state.draft.copyWith(expiryDate: date)));

  /// The pink key while nothing is chosen, and the Camera key beside it.
  /// Choosing a file starts the send, which is what the frame's one key does.
  Future<void> chooseFile({bool fromCamera = false}) async {
    if (state.isSending) return;

    final picked = await _source.pickFile(fromCamera: fromCamera);
    if (isClosed || picked == null) return;

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          fileName: picked.name,
          kind: picked.kind,
          sizeKb: picked.sizeKb,
        ),
      ),
    );
    await send();
  }

  /// Sends what the draft holds. Also what Retry calls.
  Future<void> send() async {
    if (!state.draft.isReady || state.isSending) return;

    emit(state.copyWith(upload: UploadStatus.sending, percentSent: 0));
    try {
      final saved = await _source.uploadDocument(
        studentId: state.studentId,
        draft: state.draft,
        onProgress: (sent) {
          if (!isClosed) emit(state.copyWith(percentSent: sent));
        },
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          upload: UploadStatus.done,
          percentSent: 1,
          documents: <StudentDocumentItem>[saved, ...state.documents],
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(upload: UploadStatus.failed));
    }
  }

  /// "Add another" after a send, and "Discard" after a failed one: both put
  /// the card back to an empty file with the type and expiry kept.
  void reset() => emit(
    state.copyWith(
      upload: UploadStatus.idle,
      percentSent: 0,
      draft: state.draft.copyWith(clearFile: true),
    ),
  );
}
