import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';


class StudentImmunizationTabCard extends StatefulWidget {
  const StudentImmunizationTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;


  @override
  State<StudentImmunizationTabCard> createState() =>
      _StudentImmunizationTabCardState();
}

class _StudentImmunizationTabCardState extends State<StudentImmunizationTabCard> {
  late Future<List<StudentImmunizationModel>> _immunizationFuture;
  bool _hasShownErrorSnackBar = false;

  @override
  void initState() {
    super.initState();
    _immunizationFuture = _buildImmunizationFuture();
  }

  Future<List<StudentImmunizationModel>> _buildImmunizationFuture() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return const <StudentImmunizationModel>[];
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    try {
      return await repo.getStudentImmunizations(studentCode: code);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        setState(() {
          _immunizationFuture =
              serviceLocator<StudentRepository>() is StudentRepositoryImpl
                  ? (serviceLocator<StudentRepository>() as StudentRepositoryImpl)
                      .getStudentImmunizations(
                      studentCode: widget.studentCode ?? '',
                      forceRefresh: true,
                    )
                  : _buildImmunizationFuture();
          _hasShownErrorSnackBar = false;
        });
        try {
          await _immunizationFuture;
        } catch (_) {
          // handled in FutureBuilder
        }
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: FutureBuilder<List<StudentImmunizationModel>>(
          future: _immunizationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: PrimaryCircularLoader()),
              );
            }

            if (snapshot.hasError) {
              final message = snapshot.error.toString();
              CoreUtils.logApiError(message);
              if (!_hasShownErrorSnackBar) {
                _hasShownErrorSnackBar = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: message,
                    isError: true,
                  );
                });
              }
              return const SizedBox.shrink();
            }

            final items = snapshot.data ?? const <StudentImmunizationModel>[];
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No immunization records found',
                  style: AppTextStyles.value.copyWith(fontSize: 16),
                ),
              );
            }

            // Group by vaccine name
            final Map<String, List<StudentImmunizationModel>> grouped = {};
            for (final m in items) {
              grouped.putIfAbsent(m.vaccineName, () => []).add(m);
            }

            final sortedKeys = grouped.keys.toList()..sort();

            return Column(
              children: [
                for (int i = 0; i < sortedKeys.length; i++) ...[
                  _ImmunizationCard(
                    vaccineName: sortedKeys[i],
                    doses: grouped[sortedKeys[i]]!..sort(
                      (a, b) => a.doseNumber.compareTo(b.doseNumber),
                    ),
                    isFirstCard: i == 0,
                  ),
                  if (i != sortedKeys.length - 1) const SizedBox(height: 20),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

}

class _ImmunizationCard extends StatefulWidget {
  const _ImmunizationCard({
    required this.vaccineName,
    required this.doses,
    required this.isFirstCard,
  });
  final bool isFirstCard;
  final String vaccineName;
  final List<StudentImmunizationModel> doses;

  @override
  State<_ImmunizationCard> createState() => _ImmunizationCardState();
}

class _ImmunizationCardState extends State<_ImmunizationCard> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: widget.isFirstCard ? const Radius.circular(0) : const Radius.circular(8),
                topLeft: const Radius.circular(8),
                bottomLeft: const Radius.circular(8),
                bottomRight: const Radius.circular(8),
              ),
              border: Border.all(color: AppColors.themeColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                      ),
                      alignment: Alignment.center,
                      child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Vaccine',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primaryColor.withOpacity(0.5),
                                  fontSize: 14,
                                  letterSpacing: 14 * (-3 / 100),
                                ),
                              ),
                              Text(
                                widget.vaccineName,
                                style: AppTextStyles.value.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),


                    ),
                    if (isExpanded) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.dividerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final dose in widget.doses)
                              _DoseRow(model: dose),
                            const SizedBox(height: 20),

                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.model});
  final StudentImmunizationModel model;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dose ${model.doseNumber}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryColor.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 14 * (-3 / 100),
              ),
            ),
            Row(
              children: [
                _Chip(
                  label: _statusLabel(model.status),
                  labelColor: _statusLabelColor(model.status),
                  color: _statusBgColor(model.status),
                ),
                const SizedBox(width: 10),
                Text(
                  _doseDateText(model),
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

  }

  String _statusLabel(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return 'Completed';
    if (upper == 'DUE') return 'Due';
    if (upper == 'EXEMPTED') return 'Exempted';
    return upper.isEmpty
        ? '-'
        : upper[0] + upper.substring(1).toLowerCase();
  }

  Color _statusLabelColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return const Color(0xFF38C820);
    if (upper == 'DUE') return const Color(0xFFEABA00);
    if (upper == 'EXEMPTED') return const Color(0xFF6C6377);
    return AppColors.primaryColor.withOpacity(0.8);
  }

  Color _statusBgColor(String raw) {
    final upper = raw.trim().toUpperCase();
    if (upper == 'COMPLETED') return const Color(0x1A38C820);
    if (upper == 'DUE') return const Color(0x1AEABA00);
    if (upper == 'EXEMPTED') return const Color(0xFFECEFF1);
    return const Color(0xFFF3F4FB);
  }

  String _doseDateText(StudentImmunizationModel model) {
    if ((model.administeredDate ?? '').isNotEmpty) {
      return model.administeredDate!;
    }
    if ((model.dueDate ?? '').isNotEmpty) {
      return model.dueDate!;
    }
    return '-';
  }

}


class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color});
  final String label;
  final Color labelColor;
  final Color color;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.value.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}






