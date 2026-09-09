import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/file_download_service.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/delete_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_documents_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_documents_list_cubit.dart';

class _UnusedRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGet extends GetStudentDocumentsUseCase {
  _FakeGet() : super(_UnusedRepo());
}

class _FakeDelete extends DeleteStudentDocumentUseCase {
  _FakeDelete() : super(_UnusedRepo());
}

/// Records the download call instead of hitting the network.
class _RecordingDownloader extends FileDownloadService {
  _RecordingDownloader() : super(dio: Dio());
  String? url;
  String? path;
  @override
  Future<void> downloadToFile(String u, String p) async {
    url = u;
    path = p;
  }
}

void main() {
  test(
    'downloadFile routes through the injected FileDownloadService — the view no '
    'longer constructs a Dio itself',
    () async {
      final downloader = _RecordingDownloader();
      final cubit = StudentDocumentsListCubit(
        getStudentDocumentsUseCase: _FakeGet(),
        deleteStudentDocumentUseCase: _FakeDelete(),
        repository: _UnusedRepo(),
        fileDownloadService: downloader,
      );

      await cubit.downloadFile('https://cdn.example/doc.jpg', '/tmp/doc.jpg');

      expect(downloader.url, 'https://cdn.example/doc.jpg');
      expect(downloader.path, '/tmp/doc.jpg');

      await cubit.close();
    },
  );
}
