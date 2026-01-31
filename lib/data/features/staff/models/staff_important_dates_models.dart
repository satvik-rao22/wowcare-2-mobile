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
  });

  final String importantDateType;
  final String dueDate; // ISO format: "yyyy-MM-dd"
  final String? completedDate; // ISO format: "yyyy-MM-dd"

  Map<String, dynamic> toJson() {
    return {
      'importantDateType': importantDateType,
      'dueDate': dueDate,
      if (completedDate != null) 'completedDate': completedDate,
    };
  }

  @override
  List<Object?> get props => [importantDateType, dueDate, completedDate];
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

