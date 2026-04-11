import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  
  static const routeName = '/role-selection';

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  Future<void> _completeLoginAndGoDashboard() async {
    // Mark login flow as completed so Splash routes to dashboard on next launch.
    await serviceLocator<StorageService>().saveBool(StorageKeys.loginCompleted, true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    MediaRes.logo_wow,
                    height: screenHeight * 0.12,
                    width: screenHeight * 0.12,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return AppColors.buildPrimaryGradient().createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'WowCare',
                      style: TextStyle(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.08),
                  Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: screenHeight * 0.028,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.08,
                    child: InkWell(
                      onTap: () async {
                        await context.read<RoleProvider>().setRole('admin');
                        await context
                            .read<RoleProvider>()
                            .refreshAccessFromServer(force: true);
                        await _completeLoginAndGoDashboard();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.buildPrimaryGradient(),
                        ),
                        child: Center(
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.08,
                    child: InkWell(
                      onTap: () async {
                        await context.read<RoleProvider>().setRole('parent');
                        await context
                            .read<RoleProvider>()
                            .refreshAccessFromServer(force: true);
                        await _completeLoginAndGoDashboard();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.buildPrimaryGradient(),
                        ),
                        child: Center(
                          child: Text(
                            'Parent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
