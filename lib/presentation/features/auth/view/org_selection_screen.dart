import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrganizationSelectionScreen extends StatefulWidget {
  const OrganizationSelectionScreen({super.key, this.isSwitchFlow = false});

  final bool isSwitchFlow;

  @override
  State<OrganizationSelectionScreen> createState() =>
      _OrganizationSelectionScreenState();
}

class _OrganizationSelectionScreenState
    extends State<OrganizationSelectionScreen> {
  String? _selectedOrgCode;
  bool _hasTriggeredOrgNamesLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always fetch fresh org names from API (no cache)
    if (_hasTriggeredOrgNamesLoad) return;
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is! AuthLoaded) return;
    final orgCodes = (authCubit.state as AuthLoaded)
        .loginResponse
        .roles
        .map((r) => r.organizationCode)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (orgCodes.isEmpty) return;
    _hasTriggeredOrgNamesLoad = true;
    authCubit.loadOrganizationNames(orgCodes);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final screenHeight = size.height - padding.top - padding.bottom;
    final screenWidth = size.width;

    void onBack() {
      if (widget.isSwitchFlow) {
        Navigator.of(context).pop();
      } else {
        context.read<AuthCubit>().logout();
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      }
    }

    return PopScope(
      canPop: widget.isSwitchFlow,
      onPopInvoked: (_) {
        if (!widget.isSwitchFlow) onBack();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final login = state.loginResponse;
          final userName = login.displayName.isNotEmpty
              ? login.displayName
              : login.email;
          final userRole =
              login.roles.isNotEmpty ? login.roles.first.role : '';

          // Always use roles for org codes; org names from API (no cache)
          final orgCodes = state.loginResponse.roles
              .map((r) => r.organizationCode)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          final orgNames = state.orgNames;
          final orgDisplayItems = (orgNames.length == orgCodes.length &&
                  orgNames.isNotEmpty)
              ? orgNames
              : orgCodes;

          final isNextEnabled = _selectedOrgCode != null && orgCodes.isNotEmpty;

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
                                    fileUuid: login.userCode,
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
                              SizedBox(height: screenHeight * 0.035),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select Organization',
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
                                  "Choose the organization you want to continue with.",
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
                              CustomDropdown(
                                hintText: orgDisplayItems.isNotEmpty
                                    ? 'Select organization'
                                    : 'No organizations',
                                items: orgDisplayItems,
                                selectedItem: () {
                                  if (_selectedOrgCode == null) return null;
                                  final index = orgCodes.indexOf(_selectedOrgCode!);
                                  if (index != -1 && index < orgDisplayItems.length) {
                                    return orgDisplayItems[index];
                                  }
                                  return null;
                                }(),
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
                                    if (value == null) {
                                      _selectedOrgCode = null;
                                    } else {
                                      final index = orgDisplayItems.indexOf(value);
                                      if (index != -1 && index < orgCodes.length) {
                                        _selectedOrgCode = orgCodes[index];
                                      }
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
                        confirmButtonLabel: 'Continue',
                        showCancelButton: false,
                        isForm: false,
                        onPressedConfirm: isNextEnabled
                            ? () async {
                                if (_selectedOrgCode == null) return;
                                final authCubit = context.read<AuthCubit>();
                                await authCubit.updateLoginContext(
                                  lastLoginOrganizationCode: _selectedOrgCode!,
                                  lastLoginSchoolCode: null,
                                );
                                if (!context.mounted) return;
                                // Always pass null so school selection fetches fresh from API
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SchoolSelectionScreen(
                                      selectedOrg: _selectedOrgCode!,
                                      isSwitchFlow: widget.isSwitchFlow,
                                      schoolsForOrg: null,
                                      orgFromLoginContext: !widget.isSwitchFlow,
                                    ),
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
