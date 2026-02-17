import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/student/models/student_pickup_models.dart';
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
    return serviceLocator<StudentRemoteDataSource>()
        .getStudentPickups(studentCode: code);
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
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        CustomRefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: FutureBuilder<List<StudentPickupModel>>(
              future: _pickupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: PrimaryCircularLoader()),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Failed to load pickups',
                            style: AppTextStyles.value.copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.error.toString(),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _handleRefresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final pickups = snapshot.data ?? const <StudentPickupModel>[];
                if (pickups.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'No pickups found',
                        style: AppTextStyles.value.copyWith(fontSize: 16),
                      ),
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
                        phoneNumber: _valueOrDash(pickups[i].phoneNumber),
                        firstChild: i == 0,
                      ),
                      if (i != pickups.length - 1) const SizedBox(height: 20),
                    ],
                    // extra space so the + button doesn't cover content
                    SizedBox(height: 76 + bottomSafe),
                  ],
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16 + bottomSafe,
          child: GradientAddButton(
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
            size: 50.0,
            iconSize: 28.0,
            borderRadius: 12.0,
          ),
        ),
      ],
    );
  }

}

String _valueOrDash(String? v) {
  if (v == null) return '-';
  final t = v.trim();
  return t.isEmpty ? '-' : t;
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

class _PickupCard extends StatelessWidget{
  const _PickupCard({
    required this.name,
    required this.firstChild,
    this.relation,
    this.email,
    this.phoneNumber,
  });
  final String name;
  final String? relation;
  final String? email;
  final String? phoneNumber;
  final bool firstChild;// so that first card can have different top right corner radius
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          // Match staff card styling: radius 12, 1px border.
          borderRadius: BorderRadius.only(
            topRight: firstChild ? const Radius.circular(0) : const Radius.circular(12),
            topLeft: const Radius.circular(12),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              // Match staff card header height.
              height: 60,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
                    name: name,
                    size: 45,
                  ),
                  SizedBox(width: isTablet ? 16 : 9),
                  Flexible(
                    child: Text(
                      name,
                      style: AppTextStyles.value.copyWith(
                        fontSize: isTablet ? 16 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
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
                        relation ?? '-',
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
                      Text(
                        email ?? '-',
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
                        'Phone Number',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        phoneNumber ?? '-',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  CustomButtonLayout(
                    confirmButtonLabel: 'Edit',
                    cancelButtonLabel: 'Delete',
                    onPressedConfirm: () {
                      // TODO: Implement Edit Pickup handler
                    },
                    onPressedCancel: () {
                      // TODO: Implement Delete Pickup handler
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

  }

}
















