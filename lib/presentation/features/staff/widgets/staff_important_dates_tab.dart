import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

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

      if (type == 'PHYSICAL_CHECKUP') {
        hasPhysicalCheckup = true;
      }

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