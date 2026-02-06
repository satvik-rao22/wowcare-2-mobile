import 'package:equatable/equatable.dart';

class StaffCountModel extends Equatable {
  const StaffCountModel({
    required this.total,
    required this.active,
    required this.upcoming,
  });

  final int total;
  final int active;
  final int upcoming;

  factory StaffCountModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return StaffCountModel(
      total: (data['total'] as num?)?.toInt() ?? 0,
      active: (data['active'] as num?)?.toInt() ?? 0,
      upcoming: (data['upcoming'] as num?)?.toInt() ?? 0,
    );
  }

  factory StaffCountModel.fromCacheJson(Map<String, dynamic> json) {
    return StaffCountModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'upcoming': upcoming,
    };
  }

  @override
  List<Object?> get props => [total, active, upcoming];
}















