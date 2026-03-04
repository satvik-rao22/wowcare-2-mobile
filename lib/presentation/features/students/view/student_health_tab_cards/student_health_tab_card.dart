import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';



class StudentHealthTabCard extends StatefulWidget {
  const StudentHealthTabCard({
    required this.scrollController,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String? studentCode;


  @override
  State<StudentHealthTabCard> createState() =>
      _StudentHealthTabCardState();
}

class _StudentHealthTabCardState extends State<StudentHealthTabCard> {
  late Future<StudentHealthModel?> _healthFuture;
  bool _photoPermission = true;
  bool _hasShownErrorSnackBar = false;

  @override
  void initState() {
    super.initState();
    _healthFuture = _buildHealthFuture();
  }

  Future<StudentHealthModel?> _buildHealthFuture() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return null;
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    try {
      return await repo.getStudentHealth(studentCode: code);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: FutureBuilder<StudentHealthModel?>(
        future: _healthFuture,
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Failed to load health info',
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
                    onPressed: () {
                      setState(() {
                        _healthFuture = _buildHealthFuture();
                        _hasShownErrorSnackBar = false;
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final health = snapshot.data;

          return Column(
            children: [
              _HealthCard(
                allergies: health?.allergy,
                medication: health?.medications,
                dietRestrictions: health?.dietRestrictions,
                photoPermission: _photoPermission,
                onTogglePhotoPermission: (v) {
                  setState(() {
                    _photoPermission = v;
                  });
                },
              ),
              SizedBox(height: 24 + bottomSafe),
            ],
          );
        },
      ),
    );
  }

}

class _HealthCard extends StatelessWidget{
  const _HealthCard({
    required this.allergies,
    required this.medication,
    required this.dietRestrictions,
    required this.photoPermission,
    required this.onTogglePhotoPermission,
  });
  final String? allergies;
  final String? medication;
  final String? dietRestrictions;
  final bool photoPermission;
  final ValueChanged<bool> onTogglePhotoPermission;

  @override
  Widget build(BuildContext context) {
    String _displayOrDash(String? v) {
      if (v == null) return '-';
      final t = v.trim();
      return t.isEmpty ? '-' : t;
    }

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.themeColor, width: 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Allergies',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _displayOrDash(allergies),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff573353),
                            height: 19 / 14,
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
                      const Text(
                        'Medications',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _displayOrDash(medication),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff573353),
                            height: 19 / 14,
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
                      const Text(
                        'Diet Restriction',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _displayOrDash(dietRestrictions),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff573353),
                            height: 19 / 14,
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
                      const Text(
                        'Photo Permission',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      CustomToggle(
                        label: '',
                        isToggled: photoPermission,
                        onToggle: onTogglePhotoPermission,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }

}
















