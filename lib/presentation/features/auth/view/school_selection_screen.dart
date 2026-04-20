import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/org_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({
    super.key,
    required this.selectedOrg,
    this.isSwitchFlow = false,
    this.schoolsForOrg,
    /// True when org comes from login-context (redirect select-school).
    /// Only then do we call names-by-org API for that org.
    this.orgFromLoginContext = false,
  });

  final String selectedOrg;
  final bool isSwitchFlow;
  /// When switching org from Dashboard: list of {schoolCode, schoolName} for selected org.
  final List<Map<String, String>>? schoolsForOrg;
  final bool orgFromLoginContext;

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  String? _selectedSchool;
  String? _selectedSchoolCode;
  bool _hasTriggeredLoad = false;

  String _formatRole(String role) {
    if (role.isEmpty) return '';
    final cleaned = role.toLowerCase().replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always fetch fresh school names from API (no cache)
    if (!_hasTriggeredLoad) {
      _hasTriggeredLoad = true;
      context.read<AuthCubit>().loadSchoolsForOrg(widget.selectedOrg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    Future<void> onBack() async {
      if (widget.isSwitchFlow) {
        Navigator.of(context).pop();
        return;
      }
      if (widget.orgFromLoginContext) {
        // Redirect flow: PATCH login-context with org and school both null,
        // then go to org selection so user can select org -> school again
        final authCubit = context.read<AuthCubit>();
        await authCubit.updateLoginContext(
          lastLoginOrganizationCode: null,
          lastLoginSchoolCode: null,
        );
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const OrganizationSelectionScreen(isSwitchFlow: true),
          ),
        );
        return;
      }
      context.read<AuthCubit>().logout();
      Navigator.pushReplacementNamed(context, SignInScreen.routeName);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await onBack();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthLoaded && !widget.isSwitchFlow) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final login = state is AuthLoaded ? state.loginResponse : null;
          final userName = login?.displayName.isNotEmpty == true
              ? login!.displayName
              : (login?.email ?? '');
          final rawRole = login?.roles.isNotEmpty == true
              ? login!.roles.first.role
              : '';
          final userRole = _formatRole(rawRole);

          // Get organization codes and names to find the display name
          final orgCodes = (login?.roles ?? [])
              .map((r) => r.organizationCode)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          final orgNames = state is AuthLoaded ? state.orgNames : <String>[];
          
          // Find the organization name for the selected org code
          String orgDisplayName = widget.selectedOrg; // fallback to code
          final orgIndex = orgCodes.indexOf(widget.selectedOrg);
          if (orgIndex != -1 && 
              orgIndex < orgNames.length && 
              orgNames.isNotEmpty &&
              orgNames.length == orgCodes.length) {
            orgDisplayName = orgNames[orgIndex];
          }

          final List<Map<String, String>> schoolEntries =
              widget.schoolsForOrg != null
                  ? widget.schoolsForOrg!
                  : (state is AuthLoaded
                      ? (state.schoolsByOrg[widget.selectedOrg] ?? const [])
                      : const <Map<String, String>>[]);
          final schools = schoolEntries
              .map((e) => e['schoolName'] ?? e['schoolCode'] ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          final isLoading = state is AuthLoaded &&
              state.isPrefetchingSchools &&
              schools.isEmpty;

          // If school API failed (e.g. 404) we keep the flow but
          // surface the error once using the shared top banner.
          if (!isLoading &&
              schools.isEmpty &&
              state is AuthLoaded &&
              (state.lastErrorMessage != null &&
                  state.lastErrorMessage!.isNotEmpty)) {
            final errMsg = state.lastErrorMessage!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              CoreUtils.showTopSnackBar(
                context: context,
                message: errMsg,
                isError: true,
              );
            });
          }

          final isNextEnabled = _selectedSchool != null && schools.isNotEmpty;

          return Scaffold(
            body: Container(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Back button at top (same layout as ForgotPasswordScreen)
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFF333333),
                            size: screenHeight * 0.03,
                          ),
                          onPressed: onBack,
                        ),
                      ),
                    ),
                    Expanded(
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
                                  return AppColors.buildPrimaryGradient()
                                      .createShader(bounds);
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
                              SizedBox(height: screenHeight * 0.03),
                              // Profile avatar + name/role in a row (like design)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DocumentImageWidget(
                                    fileUuid: login?.userCode ?? '',
                                    name: userName,
                                    size: screenHeight * 0.07,
                                    fontSize: screenHeight * 0.024,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: screenHeight * 0.022,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF573353),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text(
                                        userRole,
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: screenHeight * 0.016,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              // Organization name (same idea as previous subtitle)
                              Text(
                                orgDisplayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF573353),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select your School',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: screenHeight * 0.022,
                                    height: 2 / 6,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Choose the school you want to continue with.",
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: screenHeight * 0.016,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF333333),
                                    height: 22 / 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: const Color(0xFFFFF3E9),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              if (isLoading)
                                Padding(
                                  padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                                  child: const LinearProgressIndicator(),
                                ),
                              CustomDropdown(
                                hintText: isLoading
                                    ? 'Loading schools...'
                                    : (schools.isNotEmpty
                                        ? 'Select school'
                                        : 'No schools found'),
                                items: schools,
                                selectedItem: _selectedSchool,
                                height: screenHeight * 0.06,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01,
                                  horizontal: screenWidth * 0.04,
                                ),
                                leadingIcon: SvgPicture.asset(
                                  MediaRes.homeIcon,
                                  height: screenHeight * 0.022,
                                  width: screenHeight * 0.022,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF573353),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                selectedTextStyle: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: screenHeight * 0.022,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                ),
                                popupItemTextStyle: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF333333),
                                ),
                                onSelect: (value) {
                                  setState(() {
                                    _selectedSchool = value;
                                    if (value != null && schoolEntries.isNotEmpty) {
                                      final entry = schoolEntries.firstWhere(
                                        (e) =>
                                            (e['schoolName'] ?? e['schoolCode']) ==
                                            value,
                                        orElse: () => <String, String>{},
                                      );
                                      _selectedSchoolCode =
                                          entry['schoolCode'] ?? entry['schoolName'];
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: CustomButtonLayout(
                        confirmButtonLabel: 'Next',
                        showCancelButton: false,
                        isForm: false,
                        onPressedConfirm: isNextEnabled
                            ? () async {
                                if (_selectedSchool == null) return;
                                final authCubit = context.read<AuthCubit>();
                                final schoolCode = _selectedSchoolCode ??
                                    _selectedSchool!;
                                await authCubit.updateLoginContext(
                                  lastLoginOrganizationCode: widget.selectedOrg,
                                  lastLoginSchoolCode: schoolCode,
                                );
                                if (widget.isSwitchFlow) {
                                  await authCubit.setSelectedOrgAndSchool(
                                    organizationCode: widget.selectedOrg,
                                    schoolCode: schoolCode,
                                    schoolName: _selectedSchool,
                                  );
                                } else {
                                  await authCubit.completeLogin(
                                    selectedOrgCode: widget.selectedOrg,
                                    selectedSchoolName: _selectedSchool!,
                                    selectedSchoolCode: _selectedSchoolCode,
                                  );
                                }
                                // After selecting org/school (either during login
                                // or when switching organisation), prefetch the
                                // staff profile for this context so that My Profile
                                // loads instantly from cache.
                                await authCubit.prefetchStaffProfileForOrgAndSchool(
                                  organizationCode: widget.selectedOrg,
                                  schoolCode: schoolCode,
                                );
                                if (!context.mounted) return;
                                await context
                                    .read<RoleProvider>()
                                    .refreshAccessFromServer(force: true);
                                if (!context.mounted) return;
                                context.read<ParentChildProvider>().invalidate();
                                await context
                                    .read<ParentChildProvider>()
                                    .ensureLoaded(force: true);
                                if (!context.mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardScreen(),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
