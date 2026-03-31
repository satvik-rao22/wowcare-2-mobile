import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/student/models/student_pickup_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/students/view/add_pickup_screen.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';

class StudentPickupTabCard extends StatefulWidget {
  const StudentPickupTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.onRefresh,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;
  final Future<void> Function()? onRefresh;


  @override
  State<StudentPickupTabCard> createState() =>
      _StudentPickupTabCardState();
}

class _StudentPickupTabCardState extends State<StudentPickupTabCard> {
  late Future<List<StudentPickupModel>> _pickupsFuture;

  @override
  void initState() {
    super.initState();
    _pickupsFuture = _buildPickupsFuture();
  }

  Future<List<StudentPickupModel>> _buildPickupsFuture() {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return Future.value(const <StudentPickupModel>[]);
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    return repo.getStudentPickups(studentCode: code);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _pickupsFuture = _buildPickupsFuture();
    });
    await widget.onRefresh?.call();
    try {
      await _pickupsFuture;
    } catch (_) {
      // swallow; UI handles errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pickup details',
                      style: AppTextStyles.value.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    GradientAddButton(
                      onTap: () async {
                        final code = widget.studentCode ?? '';
                        if (code.isEmpty) return;
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddPickupScreen(studentCode: code),
                          ),
                        );
                        if (result == true && mounted) {
                          await _handleRefresh();
                        }
                      },
                      wantedButtonSize: 40,
                      iconSize: 22,
                      borderRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<StudentPickupModel>>(
                future: _pickupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: PrimaryCircularLoader(
                        size: 28,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Failed to load pickups',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }

                  final pickups = snapshot.data ?? const <StudentPickupModel>[];
                  if (pickups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No pickups found',
                        style: AppTextStyles.value.copyWith(fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < pickups.length; i++) ...[
                        _PickupCard(
                          name: pickups[i].fullName.isNotEmpty
                              ? pickups[i].fullName
                              : '-',
                          relation: _formatRelation(pickups[i].relation),
                          email: _valueOrDash(pickups[i].email),
                          phoneNumber: _formatPhoneNumber(pickups[i].phoneNumber),
                          onRefresh: _handleRefresh,
                        ),
                        if (i != pickups.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}

String _valueOrDash(String? v) {
  if (v == null) return '-';
  final t = v.trim();
  return t.isEmpty ? '-' : t;
}

String _formatPhoneNumber(String? raw) {
  final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return _valueOrDash(raw);
}

String _formatRelation(String relation) {
  final r = relation.trim();
  if (r.isEmpty) return '-';
  final upper = r.toUpperCase();
  switch (upper) {
    case 'FATHER':
      return 'Father';
    case 'MOTHER':
      return 'Mother';
    case 'GUARDIAN':
      return 'Guardian';
    default:
      // Title-case fallback
      return upper.substring(0, 1) + upper.substring(1).toLowerCase();
  }
}

class _PickupCard extends StatefulWidget {
  const _PickupCard({
    required this.name,
    this.relation,
    this.email,
    this.phoneNumber,
    this.onRefresh,
  });
  final String name;
  final String? relation;
  final String? email;
  final String? phoneNumber;
  /// Called after edit or delete so parent can refresh pickups list and profile cache.
  final Future<void> Function()? onRefresh;

  @override
  State<_PickupCard> createState() => _PickupCardState();
}

class _PickupCardState extends State<_PickupCard> {
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DocumentImageWidget(
                        fileUuid: '',
                        name: widget.name,
                        size: 50,
                      ),
                      SizedBox(width: isTablet ? 16 : 9),
                      Expanded(
                        child: Text(
                          widget.name,
                          style: AppTextStyles.value.copyWith(
                            fontSize: isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.dividerColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Relation',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            widget.relation ?? '-',
                            style: AppTextStyles.value.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Email ID',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              (widget.email != null &&
                                      widget.email!.isNotEmpty &&
                                      widget.email != '-')
                                  ? widget.email!
                                  : '-',
                              style: AppTextStyles.value.copyWith(
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Phone Number',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            widget.phoneNumber ?? '-',
                            style: AppTextStyles.value.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomButtonLayout(
                        confirmButtonLabel: 'Edit',
                        cancelButtonLabel: 'Delete',
                        onPressedConfirm: () {
                          // TODO: Implement Edit Pickup handler; after success call widget.onRefresh?.call()
                        },
                        onPressedCancel: () {
                          // TODO: Implement Delete Pickup handler; after success call widget.onRefresh?.call()
                        },
                        isForm: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
















