import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';

/// Bottom sheet for creating or editing a SCHOOL holiday (federal holidays
/// only carry an observance decision and aren't edited here).
Future<void> showHolidayFormSheet(BuildContext context, {Holiday? holiday}) {
  final cubit = context.read<EventsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        gradient: AppColors.buildScaffoldGradient(),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: BlocProvider.value(
        value: cubit,
        child: _HolidayFormSheet(holiday: holiday),
      ),
    ),
  );
}

/// Keyboard-level guard for the date fields: keeps digits only and
/// re-inserts the DD-MM-YYYY dashes at fixed positions, so no other shape
/// of input can ever reach the parser.
class _DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      buffer.write(capped[i]);
      if ((i == 1 || i == 3) && i != capped.length - 1) buffer.write('-');
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _HolidayFormSheet extends StatefulWidget {
  const _HolidayFormSheet({this.holiday});

  final Holiday? holiday;

  @override
  State<_HolidayFormSheet> createState() => _HolidayFormSheetState();
}

class _HolidayFormSheetState extends State<_HolidayFormSheet> {
  /// Hard caps on free-text fields. Enforced at the keyboard (users can't
  /// type past them) and re-checked in [_isFormValid] so a holiday carrying
  /// over-long text from bad server data can't be saved as-is.
  static const int _kNameMaxLength = 80;
  static const int _kDescriptionMaxLength = 500;

  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');

  late final TextEditingController _nameController = TextEditingController(
    text: widget.holiday?.name ?? '',
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.holiday?.description ?? '');
  late final TextEditingController _startDateController =
      TextEditingController(
        text: _dateFormat.format(
          widget.holiday?.startDate ?? _dateOnly(DateTime.now()),
        ),
      );
  late final TextEditingController _endDateController = TextEditingController(
    text: _dateFormat.format(
      widget.holiday?.endDate ?? _dateOnly(DateTime.now()),
    ),
  );

  /// Parsed from the date fields' text; null while the text isn't a valid
  /// DD-MM-YYYY calendar date, which blocks saving.
  late DateTime? _startDate = widget.holiday?.startDate ?? _dateOnly(DateTime.now());
  late DateTime? _endDate = widget.holiday?.endDate ?? _dateOnly(DateTime.now());

  /// Single Date vs Date Range (FR §7/8). Defaults to Single Date; when
  /// editing a multi-day holiday it opens in Range mode.
  late bool _isRange =
      widget.holiday != null &&
      !_isSameDay(widget.holiday!.startDate, widget.holiday!.endDate);

  bool get _isEditing => widget.holiday != null;

  /// Name is mandatory and within the length cap; description (optional) must
  /// also fit the cap; both dates must be valid DD-MM-YYYY calendar dates and
  /// a range can never end before it starts — whether picked or typed
  /// (FR §7/8).
  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _nameController.text.characters.length <= _kNameMaxLength &&
      _descriptionController.text.characters.length <= _kDescriptionMaxLength &&
      _startDate != null &&
      (!_isRange ||
          (_endDate != null && !_endDate!.isBefore(_startDate!)));

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _startDateController.addListener(_onFieldChanged);
    _endDateController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {
    _startDate = _parseDate(_startDateController.text);
    _endDate = _parseDate(_endDateController.text);
  });

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _startDateController.removeListener(_onFieldChanged);
    _endDateController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isEditing ? 'Edit Holiday' : 'Add Holiday',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Holiday name'),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: _kNameMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: _decoration('Holiday name'),
            ),
            const SizedBox(height: 10),
            _dateTypeSelector(),
            const SizedBox(height: 10),
            if (_isRange)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Starts',
                      controller: _startDateController,
                      errorText: _dateError(
                        _startDateController.text,
                        _startDate,
                      ),
                      onPickTap: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateField(
                      label: 'Ends',
                      controller: _endDateController,
                      errorText: _endDateError(),
                      onPickTap: _pickEndDate,
                    ),
                  ),
                ],
              )
            else
              _dateField(
                label: 'Date',
                controller: _startDateController,
                errorText: _dateError(_startDateController.text, _startDate),
                onPickTap: _pickStartDate,
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              maxLength: _kDescriptionMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Description (optional)'),
            ),
            const SizedBox(height: 16),
            BlocBuilder<EventsCubit, EventsState>(
              builder: (context, state) {
                final canSave = _isFormValid && !state.isSaving;
                return SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: canSave
                          ? AppColors.buildPrimaryGradient()
                          : null,
                      color: canSave ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: canSave ? _save : null,
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Add Holiday',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_isFormValid) return;
    final name = _nameController.text.trim();
    final startDate = _startDate!;
    final endDate = _isRange ? _endDate! : startDate;
    final now = DateTime.now();
    final base =
        widget.holiday ??
        Holiday(
          code: '',
          name: '',
          startDate: startDate,
          endDate: endDate,
          type: HolidayType.school,
          createdAt: now,
          updatedAt: now,
        );
    final (ok, message) = await context.read<EventsCubit>().saveHoliday(
      base.copyWith(
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: _descriptionController.text.trim(),
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isSuccess: ok,
      isError: !ok,
    );
    if (ok) Navigator.pop(context);
  }

  /// Single Date / Date Range radio group (FR §7/8). The selected pill takes
  /// the app's primary gradient, matching the tab switchers elsewhere.
  Widget _dateTypeSelector() {
    Widget option(String label, bool rangeValue) {
      final selected = _isRange == rangeValue;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            _isRange = rangeValue;
            if (!_isRange) _endDateController.text = _startDateController.text;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buildPrimaryGradient() : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 15,
                  color: selected ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('Single Date', false),
        const SizedBox(width: 8),
        option('Date Range', true),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.themeColor),
      ),
    );
  }

  /// Manually editable date field (strictly DD-MM-YYYY) with a trailing
  /// calendar icon that opens the date picker.
  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onPickTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [_DateTextInputFormatter()],
          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
          decoration: _decoration('DD-MM-YYYY').copyWith(
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 10.5,
              color: AppColors.errorColor,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: AppColors.themeColor,
              ),
              onPressed: onPickTap,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await _showPicker(initial: _startDate);
    if (picked == null) return;
    _startDateController.text = _dateFormat.format(picked);
    // Picking a start past the current end drags the end along so the range
    // can't go negative (typed input is instead blocked by validation).
    if (_isRange && _endDate != null && _endDate!.isBefore(picked)) {
      _endDateController.text = _dateFormat.format(picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await _showPicker(initial: _endDate, minDate: _startDate);
    if (picked == null) return;
    _endDateController.text = _dateFormat.format(picked);
  }

  Future<DateTime?> _showPicker({DateTime? initial, DateTime? minDate}) async {
    final firstDate = minDate ?? DateTime(DateTime.now().year - 1);
    final base = initial ?? _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: base.isBefore(firstDate) ? firstDate : base,
      firstDate: firstDate,
      lastDate: DateTime(DateTime.now().year + 3),
    );
    return picked == null ? null : _dateOnly(picked);
  }

  String? _dateError(String text, DateTime? parsed) {
    if (text.isEmpty) return 'Required';
    if (parsed == null) return 'Use DD-MM-YYYY';
    return null;
  }

  String? _endDateError() {
    final formatError = _dateError(_endDateController.text, _endDate);
    if (formatError != null) return formatError;
    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
      return "Can't be before start date";
    }
    return null;
  }

  /// Strict DD-MM-YYYY parse: exact shape, then a round-trip check so
  /// rollover dates like 31-02-2026 are rejected instead of silently
  /// becoming another day.
  static DateTime? _parseDate(String text) {
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}
