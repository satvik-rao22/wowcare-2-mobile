import 'package:equatable/equatable.dart';

/// FEDERAL holidays come from the public calendar and the school decides
/// whether to observe them ([HolidayStatus]); SCHOOL holidays are created
/// by admins and are always observed.
enum HolidayType {
  federal('FEDERAL'),
  school('SCHOOL');

  const HolidayType(this.value);

  final String value;

  String get label {
    switch (this) {
      case HolidayType.federal:
        return 'Federal';
      case HolidayType.school:
        return 'School';
    }
  }

  static HolidayType fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    return HolidayType.values.firstWhere(
      (t) => t.value == normalized,
      orElse: () => HolidayType.school,
    );
  }
}

/// Observance decision for federal holidays only.
enum HolidayStatus {
  pending('PENDING'),
  considered('CONSIDERED'),
  rejected('REJECTED');

  const HolidayStatus(this.value);

  final String value;

  String get label {
    switch (this) {
      case HolidayStatus.pending:
        return 'Pending';
      case HolidayStatus.considered:
        return 'Observed';
      case HolidayStatus.rejected:
        return 'Not Observed';
    }
  }

  static HolidayStatus? fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    for (final status in HolidayStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}

/// Action sent to `PATCH /api/v1/holidays/{code}/status` for federal holidays.
/// `approve`: PENDING→CONSIDERED or REJECTED→CONSIDERED (re-approve).
/// `reject`: PENDING→REJECTED.
enum HolidayStatusAction {
  approve('APPROVE'),
  reject('REJECT');

  const HolidayStatusAction(this.value);

  final String value;
}

class Holiday extends Equatable {
  const Holiday({
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description = '',
    required this.type,
    this.status,
    this.version = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String code;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final HolidayType type;

  /// Only meaningful for [HolidayType.federal]; null for school holidays.
  final HolidayStatus? status;

  /// Optimistic-locking version echoed back as the `If-Match` header on
  /// `PATCH` requests (update / status change).
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// School holidays and observed federal holidays block the calendar.
  bool get isObserved =>
      type == HolidayType.school || status == HolidayStatus.considered;

  bool coversDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final first = DateTime(startDate.year, startDate.month, startDate.day);
    final last = DateTime(endDate.year, endDate.month, endDate.day);
    return !target.isBefore(first) && !target.isAfter(last);
  }

  Holiday copyWith({
    String? code,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    HolidayType? type,
    HolidayStatus? Function()? status,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Holiday(
      code: code ?? this.code,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status != null ? status() : this.status,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        code,
        name,
        startDate,
        endDate,
        description,
        type,
        status,
        version,
        createdAt,
        updatedAt,
      ];
}
