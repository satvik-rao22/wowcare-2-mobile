import 'package:intl/intl.dart';

class DateUtilsNew {
  static String formatToShortReadableDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
