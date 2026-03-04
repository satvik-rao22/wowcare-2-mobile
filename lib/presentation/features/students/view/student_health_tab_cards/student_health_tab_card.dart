import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_health_screen.dart';



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
      final model = await repo.getStudentHealth(studentCode: code);
      _photoPermission = true; // backend currently omits this; default to true
      return model;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return CustomRefreshIndicator(
      onRefresh: () async {
        setState(() {
          _healthFuture = _buildHealthFuture();
          _hasShownErrorSnackBar = false;
        });
        try {
          await _healthFuture;
        } catch (_) {
          // errors handled by FutureBuilder
        }
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
            // Do not show an inline error widget; just keep the card hidden.
            return const SizedBox.shrink();
          }

            final health = snapshot.data;

            return Column(
              children: [
                _HealthCard(
                  allergies: health?.allergy,
                  medication: health?.medications,
                  dietRestrictions: health?.dietRestrictions,
                  photoPermission: _photoPermission,
                  onTogglePhotoPermission: (v) async {
                  final code = widget.studentCode;
                  if (code == null || code.isEmpty) return;
                  setState(() {
                    _photoPermission = v;
                  });
                  try {
                    final repo =
                        serviceLocator<StudentRepository>() as StudentRepositoryImpl;
                    final body = {
                      'allergy': health?.allergy ?? '',
                      'medications': health?.medications ?? '',
                      'dietRestrictions': health?.dietRestrictions ?? '',
                      'photoPermission': v,
                    };
                    await repo.updateStudentHealth(
                      studentCode: code,
                      body: body,
                    );
                  } catch (e) {
                    CoreUtils.logApiError(e.toString());
                    if (!mounted) return;
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Failed to update photo permission',
                      isError: true,
                    );
                    }
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                    final code = widget.studentCode;
                    if (code == null || code.isEmpty) return;
                    final currentHealth = health;
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditStudentHealthScreen(
                          studentCode: code,
                          initialHealth: currentHealth,
                        ),
                      ),
                    );
                      if (result == true && mounted) {
                        setState(() {
                          _healthFuture = _buildHealthFuture();
                          _hasShownErrorSnackBar = false;
                        });
                      }
                    },
                    child: const Text(
                      'Edit health details',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24 + bottomSafe),
              ],
            );
          },
        ),
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
















