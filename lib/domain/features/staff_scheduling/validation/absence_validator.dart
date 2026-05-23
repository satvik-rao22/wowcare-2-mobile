import 'package:intl/intl.dart';
import '../../attendance/usecases/get_staff_absent_form_list_usecase.dart';

class AbsenceValidator {
  AbsenceValidator(this._getStaffAbsentFormListUseCase);

  final GetStaffAbsentFormListUseCase _getStaffAbsentFormListUseCase;

  Future<bool> isStaffAbsentOnAnyDate({
    required String staffCode,
    required List<DateTime> dates,
  }) async {
    if (dates.isEmpty) return false;
    final sorted = [...dates]..sort((a, b) => a.compareTo(b));
    final from = DateFormat('yyyy-MM-dd').format(sorted.first);
    final to = DateFormat('yyyy-MM-dd').format(sorted.last);

    final page = await _getStaffAbsentFormListUseCase(
      fromAbsenceDate: from,
      toAbsenceDate: to,
      page: 0,
      size: 200,
    );

    final absentDatesByStaff = page.items
        .where((e) => e.staffCode == staffCode)
        .map((e) => e.absenceDate)
        .toSet();

    for (final d in dates) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      if (absentDatesByStaff.contains(key)) return true;
    }
    return false;
  }
}

