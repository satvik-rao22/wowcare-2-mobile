import 'package:intl/intl.dart';

/// How M05 writes a date, an age and a file size. Formatting, not copy, so it
/// lives beside the strings rather than in them.
abstract final class StudentsFormats {
  static final DateFormat _day = DateFormat('d MMM yyyy');
  static final DateFormat _dayShort = DateFormat('EEE d MMM');
  static final DateFormat _time = DateFormat('h:mm a');

  /// `12 Jul 2023`
  static String date(DateTime d) => _day.format(d);

  /// `Thu 20 Aug`
  static String dayShort(DateTime d) => _dayShort.format(d);

  /// `8:42 AM`
  static String time(DateTime d) => _time.format(d);

  /// `3 yrs 1 mo`, counted from [dob] to [today].
  static String age(DateTime dob, DateTime today) {
    var years = today.year - dob.year;
    var months = today.month - dob.month;
    if (today.day < dob.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    final y = years == 1 ? '1 yr' : '$years yrs';
    if (months == 0) return y;
    return '$y $months mo';
  }

  /// `1.8 MB`
  static String fileSize(int kb) {
    if (kb < 1024) return '$kb KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  /// `9:00` from a minute-of-day.
  static String clock(int minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
