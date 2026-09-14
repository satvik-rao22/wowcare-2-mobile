import 'package:equatable/equatable.dart';

enum ImportantDateType {
  hireDate('HIRE_DATE'),
  cda('CDA'),
  brc('BRC'),
  firstAidCpr('FIRST_AID_CPR'),
  physicalCheckup('PHYSICAL_CHECKUP'),
  other('OTHER');

  const ImportantDateType(this.value);
  final String value;
}

class ImportantDateRequestModel extends Equatable {
  const ImportantDateRequestModel({
    required this.importantDateType,
    required this.dueDate,
    this.completedDate,
    this.status,
  });

  final String importantDateType;
  final String dueDate; // ISO format: "yyyy-MM-dd"
  final String? completedDate; // ISO format: "yyyy-MM-dd"
  /// Optional status (e.g. "Scheduled", "Completed" for physical checkup).
  final String? status;

  factory ImportantDateRequestModel.fromJson(Map<String, dynamic> json) {
    return ImportantDateRequestModel(
      importantDateType: (json['importantDateType'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      completedDate: json['completedDate']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importantDateType': importantDateType,
      'dueDate': dueDate,
      if (completedDate != null) 'completedDate': completedDate,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }

  @override
  List<Object?> get props => [
    importantDateType,
    dueDate,
    completedDate,
    status,
  ];
}

class ImportantDatesResponseModel extends Equatable {
  const ImportantDatesResponseModel({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String timestamp;

  factory ImportantDatesResponseModel.fromJson(Map<String, dynamic> json) {
    return ImportantDatesResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message, data, timestamp];
}

class PhysicalCheckupSummaryModel {
  const PhysicalCheckupSummaryModel({
    required this.overduePhysicalCheckupCount,
    required this.staffWithoutActivePhysicalCheckupCount,
  });

  final int overduePhysicalCheckupCount;
  final int staffWithoutActivePhysicalCheckupCount;

  factory PhysicalCheckupSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return PhysicalCheckupSummaryModel(
      overduePhysicalCheckupCount:
          (data['overduePhysicalCheckupCount'] as num?)?.toInt() ?? 0,
      staffWithoutActivePhysicalCheckupCount:
          (data['staffWithoutActivePhysicalCheckupCount'] as num?)?.toInt() ??
          0,
    );
  }
}

class WorkBreakReminderResponseModel extends Equatable {
  const WorkBreakReminderResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.timestamp = '',
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String timestamp;

  factory WorkBreakReminderResponseModel.fromJson(Map<String, dynamic> json) {
    return WorkBreakReminderResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [success, message, data, timestamp];
}
