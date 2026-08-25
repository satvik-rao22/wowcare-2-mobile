import 'package:equatable/equatable.dart';
import '../../../../domain/features/student/entities/vaccine_item.dart';

class VaccineModel extends Equatable {
  const VaccineModel({required this.code, required this.name});

  final String code;
  final String name;

  factory VaccineModel.fromJson(Map<String, dynamic> json) {
    final code =
        (json['code'] ??
                json['vaccineCode'] ??
                json['id'] ??
                json['vaccineId'] ??
                json['vaccineIdentifier'] ??
                '')
            .toString()
            .trim();
    final name =
        (json['name'] ??
                json['vaccineName'] ??
                json['displayName'] ??
                json['label'] ??
                json['title'] ??
                '')
            .toString()
            .trim();
    return VaccineModel(code: code, name: name);
  }

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  VaccineItem toEntity() => VaccineItem(code: code, name: name);

  @override
  List<Object?> get props => [code, name];

  @override
  String toString() => 'VaccineModel(code: $code, name: $name)';
}
