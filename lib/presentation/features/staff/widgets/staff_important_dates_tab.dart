import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

class StaffImportantDatesTab extends StatefulWidget {
  const StaffImportantDatesTab({super.key, required this.staffCode});

  final String staffCode;

  @override
  State<StaffImportantDatesTab> createState() => _StaffImportantDatesTabState();
}

class _StaffImportantDatesTabState extends State<StaffImportantDatesTab> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');
  static const List<String> _orderedTypes = <String>[
    'HIRE_DATE',
    'CDA',
    'FIRST_AID_CPR',
    'BRC',
    'PHYSICAL_CHECKUP',
  ];

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

  /// Patterns the API may send when the value isn't ISO-8601. We try each so
  /// the date always renders as "MMM dd, yyyy" (with the year), e.g. for a past
  /// date "Jun 02, 2025".
  static final List<DateFormat> _fallbackParsers = <DateFormat>[
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('MMM dd, yyyy'),
    DateFormat('MMM dd yyyy'),
    DateFormat('dd MMM yyyy'),
  ];

  String _formatDate(String isoDate) {
    final raw = isoDate.trim();
    if (raw.isEmpty) return raw;

    // ISO-8601 first (e.g. 2025-06-02 / 2025-06-02T00:00:00Z).
    DateTime? parsed = DateTime.tryParse(raw);

    // Fall back to common non-ISO formats so the year is still shown.
    if (parsed == null) {
      for (final parser in _fallbackParsers) {
        try {
          parsed = parser.parseStrict(raw);
          break;
        } catch (_) {
          // Try the next pattern.
        }
      }
    }

    if (parsed == null) return raw;
    return _displayFormatter.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, String>>.from(_items);

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: CustomRefreshIndicator(
        onRefresh: () => _loadDates(useCache: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildContent(items),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, String>> items) {
    if (_isLoading) {
      return const StaffImportantDatesShimmer();
    }

    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        padding: const EdgeInsets.all(8),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildDateCards(items),
    );
  }

  List<Widget> _buildDateCards(List<Map<String, String>> items) {
    final valuesByType = <String, String>{};
    for (final item in items) {
      final type = (item['importantDateType'] ?? '').toUpperCase();
      final dueDate = item['dueDate'] ?? '';
      if (type.isEmpty || dueDate.trim().isEmpty) continue;
      valuesByType[type] = dueDate;
    }

    final cards = <Widget>[];
    var isFirst = true;
    for (final type in _orderedTypes) {
      final dueDate = valuesByType[type];
      if (dueDate == null) continue;

      final label = _mapTypeToLabel(type);
      final lowerLabel = label.toLowerCase();
      final isCda = lowerLabel.contains('cda');
      final isBackgroundRecord =
          lowerLabel.contains('background') && lowerLabel.contains('record');
      cards.add(
        Container(
          margin: EdgeInsets.only(top: isFirst ? 16 : 12, bottom: 0),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _DateRow(
            label: label,
            text: _formatDate(dueDate),
            showInfo: isCda && !isBackgroundRecord,
            infoText: 'CDA - Child Development Associate',
          ),
        ),
      );
      isFirst = false;
    }

    return cards;
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.text,
    this.showInfo = false,
    this.infoText,
  });
  final String label;
  final String text;
  final bool showInfo;
  final String? infoText;

  @override
  Widget build(BuildContext context) {
    final displayText =
        (text.trim().isEmpty || text.trim().toLowerCase() == 'no cda')
        ? '-'
        : text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              infoText ?? 'CDA - Child Development Associate',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    overlay.insert(entry);
                    Future.delayed(
                      const Duration(seconds: 2),
                    ).then((_) => entry.remove());
                  },
                  child: const Icon(
                    Icons.info_outline,
                    size: 24,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
