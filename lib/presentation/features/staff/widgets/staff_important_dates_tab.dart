import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

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
  Map<String, String> _dates = const {};

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCase = serviceLocator<GetImportantDatesUseCase>();
      final result = await useCase(staffCode: widget.staffCode);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message ?? 'Failed to load important dates';
            _dates = const {};
          });
        },
        (dates) {
          final mapped = <String, String>{};
          for (final date in dates) {
            final type = (date['importantDateType'] ?? '').toUpperCase();
            final dueDate = date['dueDate'] ?? '';
            if (dueDate.isEmpty) continue;

            final label = _mapTypeToLabel(type);
            mapped[label] = _formatDate(dueDate);
          }

          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _dates = mapped;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load important dates';
        _dates = const {};
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
    final entries = _dates.entries.toList();

    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: CustomRefreshIndicator(
        onRefresh: _loadDates,
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
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                else if (entries.isEmpty)
                  const Text(
                    'No important dates available.',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  )
                else
                  ...List.generate(entries.length * 2 - 1, (i) {
                    if (i.isOdd) return const SizedBox(height: 16);
                    final idx = i ~/ 2;
                    final e = entries[idx];
                    final lowerLabel = e.key.toLowerCase();
                    final isCda = lowerLabel.contains('cda');
                    final isBackgroundRecord = lowerLabel.contains('background') && lowerLabel.contains('record');
                    return _DateRow(
                      label: e.key,
                      text: e.value,
                      showInfo: isCda && !isBackgroundRecord,
                      infoText: 'CDA - Child Development Associate',
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
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


