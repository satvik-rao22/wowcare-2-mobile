import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/file_download_service.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/delete_staff_document_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_documents_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/load_cached_staff_documents_usecase.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_documents_list_cubit.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

class _UnusedRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGet extends GetStaffDocumentsUseCase {
  _FakeGet() : super(_UnusedRepo());
}

class _FakeDelete extends DeleteStaffDocumentUseCase {
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

/// The cubit takes an uploader (for the delete/preview paths) that this test
/// never exercises — it only drives `downloadFile`.
class _UnusedImageUpload implements AssetService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test(
    'downloadFile routes through the injected FileDownloadService — the view no '
    'longer constructs a Dio itself',
    () async {
      final downloader = _RecordingDownloader();
      final cubit = StaffDocumentsListCubit(
        getStaffDocumentsUseCase: _FakeGet(),
        deleteStaffDocumentUseCase: _FakeDelete(),
        loadCachedStaffDocumentsUseCase: LoadCachedStaffDocumentsUseCase(
          _UnusedRepo(),
        ),
        assetService: _UnusedImageUpload(),
        fileDownloadService: downloader,
      );

      await cubit.downloadFile('https://cdn.example/doc.jpg', '/tmp/doc.jpg');

      expect(downloader.url, 'https://cdn.example/doc.jpg');
      expect(downloader.path, '/tmp/doc.jpg');

      await cubit.close();
    },
  );
}
