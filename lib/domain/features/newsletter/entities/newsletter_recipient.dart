class NewsletterRecipient {
  const NewsletterRecipient({
    required this.id,
    required this.studentCode,
    required this.studentName,
    required this.classroomCode,
  });

  final int id;
  final String studentCode;
  final String studentName;
  final String classroomCode;

  String get displayName {
    final name = studentName.trim();
    if (name.isNotEmpty) return name;
    final code = studentCode.trim();
    return code.isNotEmpty ? code : 'Unknown student';
  }
}
