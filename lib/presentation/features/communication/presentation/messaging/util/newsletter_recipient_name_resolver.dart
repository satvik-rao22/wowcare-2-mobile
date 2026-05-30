import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

/// Fills missing [NewsletterRecipient.studentName] values via student profile API.
Future<List<NewsletterRecipient>> enrichNewsletterRecipientNames(
  List<NewsletterRecipient> recipients,
) async {
  if (recipients.isEmpty) return recipients;

  final StudentRepository repository = serviceLocator<StudentRepository>();
  final List<Future<NewsletterRecipient>> lookups = recipients.map(
    (NewsletterRecipient recipient) async {
      if (recipient.studentName.trim().isNotEmpty) return recipient;

      final String studentCode = recipient.studentCode.trim();
      if (studentCode.isEmpty) return recipient;

      try {
        final profile =
            await repository.getStudentProfile(code: studentCode);
        final String name = profile.fullName.trim();
        if (name.isEmpty) return recipient;

        return NewsletterRecipient(
          id: recipient.id,
          studentCode: recipient.studentCode,
          studentName: name,
          classroomCode: recipient.classroomCode,
        );
      } catch (_) {
        return recipient;
      }
    },
  ).toList();

  return Future.wait(lookups);
}
