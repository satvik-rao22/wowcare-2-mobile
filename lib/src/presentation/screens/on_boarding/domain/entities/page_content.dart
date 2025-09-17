import 'package:equatable/equatable.dart';

import '../../../../../core/res/media_res.dart';

class PageContent extends Equatable {
  const PageContent({
    required this.image,
    required this.title,
    required this.description,
  });

  const PageContent.first()
    : this(
        image: MediaRes.onboardingimage11,
        title: 'Welcome to Wow! Care',
        description:
            "Simplify preschool management with Wow! Care. From admissions to daily progress tracking, we've got you covered.",
      );

  const PageContent.second()
    : this(
        image: MediaRes.onboardingimage14,
        title: 'Track Attendance Effortlessly',
        description:
            "Mark and monitor attendance seamlessly, ensuring transparency and accuracy every day.",
      );

  const PageContent.third()
    : this(
        image: MediaRes.onboardingimage12,
        title: 'Engage with Real-Time Updates',
        description:
            "Stay connected with instant updates on daily activities, events, and notices. Keep parents in the loop at all times.",
      );

  const PageContent.forth()
    : this(
        image: MediaRes.onboardingimage15,
        title: 'Personalized Student Profiles',
        description:
            "Access and update student profiles with ease. View progress reports, achievements, and more in one place.",
      );

  final String image;
  final String title;
  final String description;

  @override
  List<Object?> get props => [image, title, description];
}
