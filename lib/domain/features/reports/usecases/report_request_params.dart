import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'report_params.dart';

class ReportRequestParams extends Equatable implements ReportParams {
  const ReportRequestParams({
    required this.reportType,
    required this.startDate,
    this.endDate,
    this.date,
    this.format = '',
    this.roomCodes,
    this.studentCodes,
    this.staffCodes,
    this.tagCodes,
    required this.schoolName,
    this.search,
    this.folderClassGrouping,
    this.periodType,
    this.invoiceStatuses,
    this.transactionStatuses,
    this.transactionTypes,
    this.paymentMethods,
  });

  @override
  final ReportType reportType;

  @override
  final DateTime startDate;

  final DateTime? date;

  @override
  final String format;

  final DateTime? endDate;

  final List<String>? roomCodes;
  final List<String>? studentCodes;
  final List<String>? staffCodes;
  final List<String>? tagCodes;
  final String? schoolName;
  final String? search;
  final String? folderClassGrouping;
  final String? periodType;
  final List<String>? invoiceStatuses;
  final List<String>? transactionStatuses;
  final List<String>? transactionTypes;
  final List<String>? paymentMethods;

  ReportRequestParams copyWith({
    ReportType? reportType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? date,
    String? format,
    List<String>? roomCodes,
    List<String>? studentCodes,
    List<String>? staffCodes,
    List<String>? tagCodes,
    String? schoolName,
    String? search,
    String? folderClassGrouping,
    String? periodType,
    List<String>? invoiceStatuses,
    List<String>? transactionStatuses,
    List<String>? transactionTypes,
    List<String>? paymentMethods,
  }) {
    return ReportRequestParams(
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      date: date ?? this.date,
      format: format ?? this.format,
      roomCodes: roomCodes ?? this.roomCodes,
      studentCodes: studentCodes ?? this.studentCodes,
      staffCodes: staffCodes ?? this.staffCodes,
      tagCodes: tagCodes ?? this.tagCodes,
      schoolName: schoolName ?? this.schoolName,
      search: search ?? this.search,
      folderClassGrouping: folderClassGrouping ?? this.folderClassGrouping,
      periodType: periodType ?? this.periodType,
      invoiceStatuses: invoiceStatuses ?? this.invoiceStatuses,
      transactionStatuses: transactionStatuses ?? this.transactionStatuses,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }

  /// Build cache identifier from params.
  String toCacheIdentifier() {
    final parts = <String>[
      reportType.backendValue,
      startDate.toIso8601String().split('T')[0],
      if (endDate != null) endDate!.toIso8601String().split('T')[0],
      if (roomCodes != null && roomCodes!.isNotEmpty)
        'classrooms=${roomCodes!.join(',')}',
      if (studentCodes != null && studentCodes!.isNotEmpty)
        'students=${studentCodes!.join(',')}',
      if (staffCodes != null && staffCodes!.isNotEmpty)
        'staff=${staffCodes!.join(',')}',
      if (tagCodes != null && tagCodes!.isNotEmpty)
        'tags=${tagCodes!.join(',')}',
      if (search != null && search!.trim().isNotEmpty)
        'search=${search!.trim().toLowerCase()}',
      if (schoolName != null && schoolName!.trim().isNotEmpty)
        'school=${schoolName!.trim().toLowerCase()}',
      if (format.isNotEmpty) 'format=$format',
      if (date != null) 'date=${date!.toIso8601String().split('T')[0]}',
      if (folderClassGrouping != null && folderClassGrouping!.isNotEmpty)
        'grouping=$folderClassGrouping',
      if (periodType != null && periodType!.isNotEmpty)
        'periodType=$periodType',
      if (invoiceStatuses != null && invoiceStatuses!.isNotEmpty)
        'invoiceStatuses=${invoiceStatuses!.join(',')}',
      if (transactionStatuses != null && transactionStatuses!.isNotEmpty)
        'transactionStatuses=${transactionStatuses!.join(',')}',
      if (transactionTypes != null && transactionTypes!.isNotEmpty)
        'transactionTypes=${transactionTypes!.join(',')}',
      if (paymentMethods != null && paymentMethods!.isNotEmpty)
        'paymentMethods=${paymentMethods!.join(',')}',
    ];
    return parts.join('|');
  }

  @override
  List<Object?> get props => [
    reportType,
    startDate,
    endDate,
    date,
    format,
    roomCodes,
    studentCodes,
    staffCodes,
    tagCodes,
    schoolName,
    search,
    folderClassGrouping,
    periodType,
    invoiceStatuses,
    transactionStatuses,
    transactionTypes,
    paymentMethods,
  ];
}
