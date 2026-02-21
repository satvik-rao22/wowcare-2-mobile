import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/staff/view/edit_important_dates_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class StaffDatesTab extends StatefulWidget {
  const StaffDatesTab({super.key, required this.staffCode});

  final String staffCode;

  @override
  State<StaffDatesTab> createState() => _StaffDatesTabState();
}

class _StaffDatesTabState extends State<StaffDatesTab> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');

  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, String> _datesByType = {};
  /// Full list from API/cache for passing to edit screen and Physical Checkup display.
  List<Map<String, String>> _importantDatesList = [];

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
            _datesByType.clear();
            _importantDatesList = List.from(cached);
            for (final date in cached) {
              final type = (date['importantDateType'] ?? '').toUpperCase();
              final dueDate = date['dueDate'] ?? '';
              if (type.isEmpty || dueDate.isEmpty) continue;
              _datesByType[type] = _formatDate(dueDate);
            }

            setState(() {
              _isLoading = false;
              _errorMessage = null;
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
            _datesByType.clear();
            _importantDatesList = [];
          });
        },
        (dates) {
          _datesByType.clear();
          _importantDatesList = List.from(dates);
          for (final date in dates) {
            final type = (date['importantDateType'] ?? '').toUpperCase();
            final dueDate = date['dueDate'] ?? '';
            if (type.isEmpty || dueDate.isEmpty) continue;
            _datesByType[type] = _formatDate(dueDate);
          }

          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load important dates';
        _datesByType.clear();
        _importantDatesList = [];
      });
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

  String _getDateForType(String type) {
    return _datesByType[type.toUpperCase()] ?? '';
  }

  Map<String, String>? _getEntryByType(String type) {
    final key = type.toUpperCase();
    for (final e in _importantDatesList) {
      if ((e['importantDateType'] ?? '').toUpperCase() == key) return e;
    }
    return null;
  }

  DateTime? _parseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  /// Maps API status (OVERDUE, SCHEDULED, COMPLETED) to edit-screen dropdown value.
  String? _apiStatusToDropdown(String? apiStatus) {
    if (apiStatus == null) return null;
    switch (apiStatus.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'OVERDUE':
      case 'SCHEDULED':
        return 'Scheduled';
      default:
        return 'Scheduled';
    }
  }

  Widget _buildPhysicalCheckupSection() {
    final physical = _getEntryByType('PHYSICAL_CHECKUP');
    const completedColor = Color.fromRGBO(56, 200, 32, 1);
    const completedBg = Color.fromRGBO(56, 200, 32, 0.1);
    const overdueColor = Color.fromRGBO(234, 186, 0, 1);
    const overdueBg = Color.fromRGBO(234, 186, 0, 0.1);
    const scheduledColor = Color.fromRGBO(234, 186, 0, 1);
    const scheduledBg = Color.fromRGBO(234, 186, 0, 0.1);

    String statusLabel;
    Color statusColor;
    Color statusBg;
    if (physical == null) {
      statusLabel = '-';
      statusColor = AppColors.primaryColor.withOpacity(0.5);
      statusBg = AppColors.primaryColor.withOpacity(0.1);
    } else {
      switch ((physical['status'] ?? '').toUpperCase()) {
        case 'COMPLETED':
          statusLabel = 'Completed';
          statusColor = completedColor;
          statusBg = completedBg;
          break;
        case 'OVERDUE':
          statusLabel = 'Overdue';
          statusColor = overdueColor;
          statusBg = overdueBg;
          break;
        case 'SCHEDULED':
          statusLabel = 'Scheduled';
          statusColor = scheduledColor;
          statusBg = scheduledBg;
          break;
        default:
          statusLabel = physical['status']?.isNotEmpty == true ? physical['status']! : 'Scheduled';
          statusColor = scheduledColor;
          statusBg = scheduledBg;
      }
    }
    final dateStr = physical != null
        ? _formatDate(physical['completedDate'] ?? physical['dueDate'] ?? '')
        : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Physical Checkup',
          style: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.5),
            fontSize: 16,
            letterSpacing: 14 * (-3 / 100),
          ),
        ),
        const SizedBox(height: 12),
        _PhysicalCard(
          statusLabel: statusLabel,
          statusColor: statusColor,
          statusBg: statusBg,
          date: dateStr,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hireDate = _getDateForType('HIRE_DATE');
    final cdaDate = _getDateForType('CDA');
    final firstAidDate = _getDateForType('FIRST_AID_CPR');
    final brcDate = _getDateForType('BRC');

    return CustomRefreshIndicator(
      onRefresh: () => _loadDates(useCache: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.themeColor),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(16),
              ),
              color: Colors.white,
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
                    GestureDetector(
                      onTap: () {
                        final hire = _getEntryByType('HIRE_DATE');
                        final cda = _getEntryByType('CDA');
                        final firstAid = _getEntryByType('FIRST_AID_CPR');
                        final brc = _getEntryByType('BRC');
                        final physical = _getEntryByType('PHYSICAL_CHECKUP');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditImportantDatesScreen(
                              staffCode: widget.staffCode,
                              initialHireDate: _parseIsoDate(hire?['dueDate']),
                              initialCdaExaminationDate: _parseIsoDate(cda?['dueDate']),
                              initialFirstAidCprExpirationDate: _parseIsoDate(firstAid?['dueDate']),
                              initialBackgroundRecordCheckExpirationDate: _parseIsoDate(brc?['dueDate']),
                              initialPhysicalCheckupDate: _parseIsoDate(physical?['dueDate']),
                              initialPhysicalCheckupStatus: _apiStatusToDropdown(physical?['status']),
                            ),
                          ),
                        ).then((_) {
                          if (mounted) _loadDates(useCache: false);
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.buildPrimaryGradient(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.edit,
                          size: 22,
                          color: Colors.white,
                        ),
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
                else ...[
                  _DateRow(
                    label: 'Hire Date',
                    text: hireDate.isEmpty ? '' : hireDate,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'CDA Examination Date',
                    text: cdaDate.isEmpty ? 'No CDA Examination Date' : cdaDate,
                    showInfo: true,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'First Aid / CPR Expiration Date',
                    text: firstAidDate.isEmpty ? '' : firstAidDate,
                  ),
                  const SizedBox(height: 16),
                  _DateRow(
                    label: 'Background Record Check Expiration Date',
                    text: brcDate.isEmpty ? '' : brcDate,
                    showInfo: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPhysicalCheckupSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text, this.showInfo = false});
  final String label;
  final String text;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  fontSize: 16,
                  letterSpacing: 14 * (-3 / 100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Child Development Associate',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: true,
                waitDuration: Duration(milliseconds: 50),
                showDuration: Duration(seconds: 2),
                verticalOffset: 6,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          (() {
            final t = text.trim();
            final tl = t.toLowerCase();
            if (t.isEmpty) return '-';
            if (tl.contains('no cda')) return '-';
            if (tl.contains('first aid') || tl.contains('cpr')) return '-';
            if (tl.contains('background record')) return '-';
            return text;
          })(),
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PhysicalCard extends StatelessWidget {
  const _PhysicalCard({
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.date,
  });

  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkup Date',
                style: TextStyle(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  letterSpacing: 14 * (-3 / 100),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


