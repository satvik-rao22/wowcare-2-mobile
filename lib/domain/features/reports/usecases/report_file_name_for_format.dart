/// Returns [fileName] with the extension implied by the chosen export
/// [format] (`PDF` → `.pdf`, anything else → `.xlsx`).
///
/// The synchronous billing endpoints stream the file back and label it
/// `<reportType>_report.xlsx` regardless of the requested format, so a PDF
/// arrived named `.xlsx` — which made the viewer show the Excel placeholder
/// instead of the PDF and made the saved file open with the wrong handler.
String reportFileNameForFormat(String? fileName, String format) {
  final extension = format.trim().toUpperCase() == 'PDF' ? 'pdf' : 'xlsx';
  final name = (fileName ?? '').trim();
  final base = name.isEmpty ? 'report' : name;
  final dotIndex = base.lastIndexOf('.');
  final stem = dotIndex > 0 ? base.substring(0, dotIndex) : base;
  return '$stem.$extension';
}
