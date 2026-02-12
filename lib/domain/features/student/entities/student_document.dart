import 'package:equatable/equatable.dart';

class StudentDocument extends Equatable {
  const StudentDocument({
    this.documentUuid,
    required this.name,
    required this.type,
    required this.storagePath,
    required this.mimeType,
    required this.size,
    required this.expiryDate,
    required this.ownerType,
    required this.ownerId,
  });

  final String? documentUuid;
  final String name;
  final String type;
  final String storagePath;
  final String mimeType;
  final int size;
  final String expiryDate;
  final String ownerType;
  final String ownerId;

  @override
  List<Object?> get props => [
    documentUuid,
    name,
    type,
    storagePath,
    mimeType,
    size,
    expiryDate,
    ownerType,
    ownerId,
  ];
}
