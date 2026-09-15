/// Response model for `GET /api/v1/invoices/family-summary` (data is a list).
class FamilySummaryModel {
  const FamilySummaryModel({
    required this.ownerType,
    required this.ownerCode,
    required this.studentCodes,
    required this.familyName,
    required this.guardianName,
    required this.lastInvoiceAmount,
    required this.lastInvoiceDate,
    required this.lastInvoiceDueDate,
    required this.lastInvoiceStatus,
    required this.lastPaymentAmount,
    required this.lastPaymentDate,
    required this.lastPaymentMethod,
    required this.openBalance,
    this.studentCount = 0,
    this.studentName,
    this.studentPhotoAssetCode,
  });

  final String ownerType;
  final String ownerCode;
  final List<String> studentCodes;
  final String familyName;
  final String guardianName;
  final double lastInvoiceAmount;
  final DateTime? lastInvoiceDate;
  final DateTime? lastInvoiceDueDate;
  final String lastInvoiceStatus;
  final double lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final String lastPaymentMethod;
  final double openBalance;
  final int studentCount;
  final String? studentName;
  final String? studentPhotoAssetCode;

  factory FamilySummaryModel.fromJson(Map<String, dynamic> json) {
    // Tolerate a field arriving as a numeric-looking string (seen for
    // never-billed / no-guardian-yet families) instead of a JSON number —
    // a strict `as num?` cast would throw and take down the whole list.
    double d(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? dt(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    return FamilySummaryModel(
      ownerType: (json['ownerType'] as String?) ?? '',
      ownerCode: (json['ownerCode'] as String?) ?? '',
      studentCodes: (json['studentCodes'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      familyName: (json['familyName'] as String?) ?? '',
      guardianName: (json['guardianName'] as String?) ?? '',
      lastInvoiceAmount: d('lastInvoiceAmount'),
      lastInvoiceDate: dt('lastInvoiceDate'),
      lastInvoiceDueDate: dt('lastInvoiceDueDate'),
      lastInvoiceStatus: (json['lastInvoiceStatus'] as String?) ?? '',
      lastPaymentAmount: d('lastPaymentAmount'),
      lastPaymentDate: dt('lastPaymentDate'),
      lastPaymentMethod: (json['lastPaymentMethod'] as String?) ?? '',
      openBalance: d('openBalance'),
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      studentName: json['studentName'] as String?,
      studentPhotoAssetCode: json['studentPhotoAssetCode'] as String?,
    );
  }

  /// Extracts and maps the family list from the standard API envelope.
  ///
  /// The backend now returns `data` as a Spring Pageable page object
  /// (`{content: [...], pageable: {...}, totalPages, totalElements, ...}`)
  /// rather than a raw array — `data['content']` is the actual list.
  /// Falls back to treating `data` itself as the list for backward
  /// compatibility, in case an older/unpaginated response shape is ever
  /// returned.
  static List<FamilySummaryModel> listFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data is Map<String, dynamic>
        ? (data['content'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(FamilySummaryModel.fromJson)
        .toList();
  }
}
