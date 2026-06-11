import 'package:flutter/material.dart';
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
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _HolidayFormSheet(holiday: holiday),
    ),
  );
}

class _HolidayFormSheet extends StatefulWidget {
  const _HolidayFormSheet({this.holiday});

  final Holiday? holiday;

  @override
  State<_HolidayFormSheet> createState() => _HolidayFormSheetState();
}

class _HolidayFormSheetState extends State<_HolidayFormSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.holiday?.name ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.holiday?.description ?? '');
  late DateTime _startDate =
      widget.holiday?.startDate ?? _dateOnly(DateTime.now());
  late DateTime _endDate =
      widget.holiday?.endDate ?? _dateOnly(DateTime.now());

  bool get _isEditing => widget.holiday != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
              _isEditing ? 'Edit School Holiday' : 'New School Holiday',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Holiday name'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: 'Starts',
                    value: _startDate,
                    onPicked: (date) => setState(() {
                      _startDate = date;
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateTile(
                    label: 'Ends',
                    value: _endDate,
                    onPicked: (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Description (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
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
                  onPressed: _save,
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Add Holiday',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Holiday name is required',
        isWarning: true,
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'End date must be on or after the start date',
        isWarning: true,
      );
      return;
    }
    final now = DateTime.now();
    final base = widget.holiday ??
        Holiday(
          code: '',
          name: '',
          startDate: _startDate,
          endDate: _endDate,
          type: HolidayType.school,
          createdAt: now,
          updatedAt: now,
        );
    final ok = await context.read<EventsCubit>().saveHoliday(
          base.copyWith(
            name: name,
            startDate: _startDate,
            endDate: _endDate,
            description: _descriptionController.text.trim(),
            updatedAt: now,
          ),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not save the holiday. Please try again.',
        isError: true,
      );
    }
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.grey[100],
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPicked,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(DateTime.now().year - 1),
            lastDate: DateTime(DateTime.now().year + 3),
          );
          if (picked != null) onPicked(_dateOnly(picked));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$label  ${DateFormat('MMM d').format(value)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);
}
