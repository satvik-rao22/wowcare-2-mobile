import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StaffImportantDatesTab extends StatefulWidget {
  const StaffImportantDatesTab({
    super.key,
    required this.staffCode,
  });

  final String staffCode;

  @override
  State<StaffImportantDatesTab> createState() => _StaffImportantDatesTabState();
}

class _StaffImportantDatesTabState extends State<StaffImportantDatesTab> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  final DateFormat _apiFormatter = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, String>> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates({bool useCache = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try cache first if useCache is true
      if (useCache) {
        final repository = serviceLocator<StaffRepository>();
        if (repository is StaffRepositoryWithCache) {
          final cached = await (repository as StaffRepositoryWithCache)
              .loadCachedImportantDates(widget.staffCode);

          if (cached != null && mounted) {
            final items = <Map<String, String>>[];
            for (final date in cached) {
              final type = (date['importantDateType'] ?? '').toUpperCase();
              final dueDate = date['dueDate'] ?? '';
              if (dueDate.isEmpty) continue;
              items.add(<String, String>{
                'importantDateType': type,
                'dueDate': dueDate,
                if ((date['status'] ?? '').toString().isNotEmpty)
                  'status': (date['status'] ?? '').toString(),
              });
            }

            setState(() {
              _isLoading = false;
              _errorMessage = null;
              _items = items;
            });

            // Don't hit API if cache is valid - return early
            return;
          }
        }
      }

      // No cache or cache invalid - load from API
      final useCase = serviceLocator<GetImportantDatesUseCase>();
      final result = await useCase(staffCode: widget.staffCode);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message ?? 'Failed to load important dates';
            _items = const [];
          });
        },
        (dates) {
          final items = <Map<String, String>>[];
          for (final date in dates) {
            final type = (date['importantDateType'] ?? '').toUpperCase();
            final dueDate = date['dueDate'] ?? '';
            if (dueDate.isEmpty) continue;
            items.add(<String, String>{
              'importantDateType': type,
              'dueDate': dueDate,
              if ((date['status'] ?? '').toString().isNotEmpty)
                'status': (date['status'] ?? '').toString(),
            });
          }

          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _items = items;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load important dates';
        _items = const [];
      });
    }
  }

  String _mapTypeToLabel(String type) {
    switch (type) {
      case 'HIRE_DATE':
        return 'Hire Date';
      case 'CDA':
        return 'CDA Examination Date';
      case 'BRC':
        return 'Background Record Check Expiration Date';
      case 'FIRST_AID_CPR':
        return 'First Aid / CPR Expiration Date';
      case 'PHYSICAL_CHECKUP':
        return 'Physical Checkup';
      default:
        return type.isEmpty ? 'Other' : type;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _displayFormatter.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, String>>.from(_items);
    // Keep stable ordering by known types first.
    const typeOrder = <String, int>{
      'HIRE_DATE': 0,
      'CDA': 1,
      'FIRST_AID_CPR': 2,
      'BRC': 3,
      'PHYSICAL_CHECKUP': 4,
    };
    items.sort((a, b) {
      final at = (a['importantDateType'] ?? '').toUpperCase();
      final bt = (b['importantDateType'] ?? '').toUpperCase();
      final ai = typeOrder[at] ?? 999;
      final bi = typeOrder[bt] ?? 999;
      return ai.compareTo(bi);
    });

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: CustomRefreshIndicator(
        onRefresh: () => _loadDates(useCache: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Important Dates',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: PrimaryCircularLoader(
                      size: 24,
                      strokeWidth: 2,
                    ),
                  )
                else if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  )
                else if (items.isEmpty)
                  const Text(
                    'No important dates available.',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  )
                else
                  ..._buildRows(items),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows(List<Map<String, String>> items) {
    final rows = <Widget>[];
    bool hasPhysicalCheckup = false;

    for (final item in items) {
      final type = (item['importantDateType'] ?? '').toUpperCase();
      final dueDate = item['dueDate'] ?? '';
      final status = (item['status'] ?? '').toString();

      if (type == 'PHYSICAL_CHECKUP') {
        hasPhysicalCheckup = true;
        final upperStatus = status.toUpperCase();
        // If completed (or missing), keep existing UI style (same as other rows).
        if (upperStatus == 'COMPLETED' || upperStatus.isEmpty) {
          rows.add(
            _DateRow(
              label: _mapTypeToLabel(type),
              text: _formatDate(dueDate),
            ),
          );
        } else {
          rows.add(
            _PhysicalCheckupCard(
              status: _mapPhysicalStatusToUi(status),
              dateText: _formatDate(dueDate),
              onMore: () => _openEditPhysicalDialog(
                initialDateIso: dueDate,
                initialStatusUi: _mapPhysicalStatusToUi(status),
              ),
            ),
          );
        }
      } else {
        final label = _mapTypeToLabel(type);
        final lowerLabel = label.toLowerCase();
        final isCda = lowerLabel.contains('cda');
        final isBackgroundRecord =
            lowerLabel.contains('background') && lowerLabel.contains('record');
        rows.add(
          _DateRow(
            label: label,
            text: _formatDate(dueDate),
            showInfo: isCda && !isBackgroundRecord,
            infoText: 'CDA - Child Development Associate',
          ),
        );
      }
    }

    // If there is no physical checkup record at all, still show the label
    // with "-" as the value, consistent with other date rows.
    if (!hasPhysicalCheckup) {
      rows.add(
        _DateRow(
          label: _mapTypeToLabel('PHYSICAL_CHECKUP'),
          text: '-',
        ),
      );
    }

    // interleave spacing
    final spaced = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      spaced.add(rows[i]);
      if (i != rows.length - 1) spaced.add(const SizedBox(height: 16));
    }
    return spaced;
  }

  String _mapPhysicalStatusToUi(String status) {
    final upper = status.toUpperCase();
    if (upper == 'COMPLETED') return 'Completed';
    if (upper == 'SCHEDULED') return 'Scheduled';
    if (upper == 'DUE') return 'Due';
    return status;
  }

  Future<void> _openEditPhysicalDialog({
    required String initialDateIso,
    required String initialStatusUi,
  }) async {
    if (!mounted) return;

    DateTime? selectedDate;
    try {
      selectedDate = DateTime.parse(initialDateIso);
    } catch (_) {
      selectedDate = null;
    }
    String statusUi = initialStatusUi.isNotEmpty ? initialStatusUi : 'Scheduled';

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isLargeTablet = screenWidth > 900;
        final bottomSafe = MediaQuery.of(context).padding.bottom;

        final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
        final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeTablet ? 1200.0 : double.infinity,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: verticalPadding,
                    bottom: verticalPadding + bottomSafe,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Physical Examination',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff573353),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: AppColors.primaryColor),
                          ),
                        ],
                      ),
                      SizedBox(height: verticalPadding),
                      if (isTablet)
                        Row(
                          children: [
                            Expanded(
                              child: _DialogField(
                                label: 'Physical Checkup Date *',
                                value: selectedDate != null
                                    ? _apiFormatter.format(selectedDate!)
                                    : '',
                                suffix: SvgPicture.asset(
                                  MediaRes.calender_icon,
                                  height: 20.0,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.primaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () async {
                                  final result = await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (context) => CalendarDialog(
                                      isRangePicker: false,
                                      isTimePicker: false,
                                      initialDate: selectedDate,
                                      firstDate: (() {
                                        final now = DateTime.now();
                                        return DateTime(now.year, now.month, now.day);
                                      })(),
                                    ),
                                  );
                                  if (result == null || result['date'] == null) return;
                                  final picked = result['date'] as DateTime;
                                  setLocalState(() => selectedDate = picked);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DialogDropdown(
                                label: 'Status *',
                                value: statusUi,
                                options: const ['Due', 'Scheduled', 'Completed'],
                                onChanged: (v) => setLocalState(() => statusUi = v),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _DialogField(
                              label: 'Physical Checkup Date *',
                              value: selectedDate != null
                                  ? _apiFormatter.format(selectedDate!)
                                  : '',
                              suffix: SvgPicture.asset(
                                MediaRes.calender_icon,
                                height: 20.0,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onTap: () async {
                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => CalendarDialog(
                                    isRangePicker: false,
                                    isTimePicker: false,
                                    initialDate: selectedDate,
                                    firstDate: (() {
                                      final now = DateTime.now();
                                      return DateTime(now.year, now.month, now.day);
                                    })(),
                                  ),
                                );
                                if (result == null || result['date'] == null) return;
                                final picked = result['date'] as DateTime;
                                setLocalState(() => selectedDate = picked);
                              },
                            ),
                            const SizedBox(height: 16),
                            _DialogDropdown(
                              label: 'Status *',
                              value: statusUi,
                              options: const ['Due', 'Scheduled', 'Completed'],
                              onChanged: (v) => setLocalState(() => statusUi = v),
                            ),
                          ],
                        ),
                      SizedBox(height: verticalPadding),
                      Builder(
                        builder: (_) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final canSave =
                              selectedDate != null && !selectedDate!.isBefore(today);

                          return CustomButtonLayout(
                            confirmButtonLabel: 'Save',
                            cancelButtonLabel: 'Cancel',
                            isForm: false,
                            isLoading: isSaving,
                            onPressedCancel: () => Navigator.of(context).pop(),
                            onPressedConfirm: canSave
                                ? () async {

                          final dueIso = _apiFormatter.format(selectedDate!);
                          final statusApi = statusUi == 'Completed'
                              ? 'COMPLETED'
                              : statusUi == 'Scheduled'
                                  ? 'SCHEDULED'
                                  : 'DUE';

                          final payload = <String, String>{
                            'importantDateType': 'PHYSICAL_CHECKUP',
                            'dueDate': dueIso,
                            'status': statusApi,
                            if (statusApi == 'COMPLETED') 'completedDate': dueIso,
                          };

                          setLocalState(() => isSaving = true);
                          try {
                            final repo = serviceLocator<StaffRepository>();
                            final msg = await repo.updateImportantDates(
                              staffCode: widget.staffCode,
                              dates: [payload],
                            );
                            if (!context.mounted) return;
                            CoreUtils.showTopSnackBar(
                              context: context,
                              message: msg.isNotEmpty ? msg : 'Updated successfully',
                              isSuccess: true,
                            );
                            Navigator.of(context).pop();
                            await _loadDates(useCache: false);
                          } catch (e) {
                            if (!context.mounted) return;
                            CoreUtils.logApiError(e.toString());
                            CoreUtils.showTopSnackBar(
                              context: context,
                              message:
                                  'Failed to update physical checkup. Please try again.',
                              isError: true,
                            );
                          } finally {
                            // `setLocalState` belongs to the bottom sheet; guard with sheet context.
                            if (context.mounted) {
                              setLocalState(() => isSaving = false);
                            }
                          }
                        }
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text, this.showInfo = false, this.infoText});
  final String label;
  final String text;
  final bool showInfo;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final displayText = (text.trim().isEmpty || text.trim().toLowerCase() == 'no cda') ? '-' : text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showInfo) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final overlay = Overlay.of(context);
                    final renderObject = context.findRenderObject();
                    if (renderObject is! RenderBox) return;
                    final offset = renderObject.localToGlobal(Offset.zero);
                    final entry = OverlayEntry(
                      builder: (ctx) => Positioned(
                        left: offset.dx - 8,
                        top: offset.dy - 44,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              infoText ?? 'CDA - Child Development Associate',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Manrope'),
                            ),
                          ),
                        ),
                      ),
                    );

                    overlay.insert(entry);
                    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
                  },
                  child: const Icon(Icons.info_outline, size: 24, color: AppColors.primaryColor),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PhysicalCheckupCard extends StatelessWidget {
  const _PhysicalCheckupCard({
    required this.status,
    required this.dateText,
    required this.onMore,
  });

  final String status;
  final String dateText;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    final Color pillBg = upper == 'DUE'
        ? const Color(0xFFFFF4D6)
        : const Color(0xFFE7F0FF);
    final Color pillText = upper == 'DUE'
        ? const Color(0xFFB07A00)
        : const Color(0xFF1E5EFF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: pillText,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_horiz, color: AppColors.primaryColor),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Checkup Date',
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.6),
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                dateText,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget suffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.6),
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                suffix,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogDropdown extends StatelessWidget {
  const _DialogDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.6),
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryColor),
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}


