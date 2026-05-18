class CopyShiftResponse {
  final int copiedCount;
  final int skippedCount;

  CopyShiftResponse({required this.copiedCount, required this.skippedCount});

  factory CopyShiftResponse.fromJson(Map<String, dynamic> json) {
    return CopyShiftResponse(
      copiedCount: json['copiedCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
    );
  }
}
