import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_metadata_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';
import 'package:wowcare/domain/features/reports/repositories/reports_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/download_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/generate_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/save_report_file_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';

class _FakeReportsRepository implements ReportsRepository {
  Object? generateError;
  Object? downloadError;
  int calls = 0;

  @override
  Future<ReportEntity> generateReport(ReportParams params) async {
    calls++;
    if (generateError != null) throw generateError!;
    return ReportEntity(
      reportId: 'RPT-1',
      reportType: params.reportType,
      generatedAt: DateTime(2026, 10, 12),
      assetCode: 'AST-1',
      fileName: 'staff.pdf',
    );
  }

  @override
  Future<String> getReportDownloadUrl(String assetCode) async {
    calls++;
    return 'https://files.example.com/$assetCode';
  }

  @override
  Future<List<int>> downloadReportFile(String downloadUrl) async {
    calls++;
    if (downloadError != null) throw downloadError!;
    return const [1, 2, 3];
  }

  @override
  Future<List<ReportMetadataEntity>> getRecentReports() async => const [];

  @override
  Future<List<String>> getStudentTags() async => const [];
}

class _FakeFileDownloadRepository implements FileDownloadRepository {
  Either<Failure, String> result = const Right('/storage/reports/staff.pdf');

  @override
  Future<Either<Failure, String>> downloadAndSaveFile({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
  }) async => result;

  @override
  Future<Either<Failure, bool>> openFile({
    required String filePath,
    required String fileName,
    required String assetCode,
  }) async => const Right(true);
}

const _params = StaffDetailsReportParams(
  reportType: ReportType.staffDetails,
  staffFieldsSelected: {'Name'},
  statusFilter: 'Active Staff',
  format: 'PDF',
  schoolName: 'Sunrise Academy',
  classroomCodes: ['CLS-9'],
);

/// Every identifier the tests pass in or get back; none may be logged.
const _identifiers = [
  'Sunrise Academy',
  'CLS-9',
  'RPT-1',
  'AST-1',
  'staff.pdf',
  'https://files.example.com/AST-1',
  '/storage/reports/staff.pdf',
];

void main() {
  final logs = <SentryLog>[];
  late _FakeReportsRepository reports;
  late _FakeFileDownloadRepository files;

  setUp(() async {
    logs.clear();
    reports = _FakeReportsRepository();
    files = _FakeFileDownloadRepository();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  void expectNoIdentifiers() {
    final logged = [
      for (final log in logs) ...[
        log.body,
        for (final attribute in log.attributes.values) '${attribute.value}',
      ],
    ].join(' ');
    for (final identifier in _identifiers) {
      expect(logged, isNot(contains(identifier)));
    }
  }

  test('generate, download and save log one success each', () async {
    final generated = await GenerateReportUseCase(reports)(_params);
    final downloaded = await DownloadReportUseCase(reports)('AST-1');
    final saved = await SaveReportFileUseCase(files)(
      fileData: Uint8List.fromList(const [1, 2, 3]),
      fileName: 'staff.pdf',
      assetCode: 'AST-1',
    );
    await settle();

    expect(generated.isRight(), isTrue);
    expect(downloaded.isRight(), isTrue);
    expect(saved.isRight(), isTrue);
    // The download's two repository calls are one user action.
    expect(reports.calls, 3);
    expect(logs.map((log) => log.body), [
      'report.generate.succeeded',
      'report.download.succeeded',
      'report.save.succeeded',
    ]);
    expectNoIdentifiers();
  });

  test('a generate failure keeps its raw bucket although it is returned as a '
      'ServerFailure', () async {
    reports.generateError = DioException(
      requestOptions: RequestOptions(path: '/reports'),
      type: DioExceptionType.receiveTimeout,
    );

    final result = await GenerateReportUseCase(reports)(_params);
    await settle();

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<ServerFailure>(),
    );
    expect(logs.single.body, 'report.generate.failed');
    expect(logs.single.attributes['failure']!.value, 'timeout');
    expectNoIdentifiers();
  });

  test('a failed download step logs one failure, not one per step', () async {
    reports.downloadError = DioException(
      requestOptions: RequestOptions(path: '/files'),
      type: DioExceptionType.connectionError,
    );

    final result = await DownloadReportUseCase(reports)('AST-1');
    await settle();

    expect(result.isLeft(), isTrue);
    expect(logs.single.body, 'report.download.failed');
    expect(logs.single.attributes['failure']!.value, 'network');
    expectNoIdentifiers();
  });

  test(
    'a save that returns a Left without throwing is logged as failed',
    () async {
      files.result = const Left(FileDownloadFailure('Failed to save file'));

      final result = await SaveReportFileUseCase(files)(
        fileData: Uint8List.fromList(const [1, 2, 3]),
        fileName: 'staff.pdf',
        assetCode: 'AST-1',
      );
      await settle();

      expect(result.isLeft(), isTrue);
      expect(logs.single.body, 'report.save.failed');
      expect(logs.single.attributes['failure']!.value, 'unknown');
      expectNoIdentifiers();
    },
  );
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
