import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
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
  List<Map<String, String>> _orgSchoolList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isSwitchFlow) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is! AuthLoaded) {
      await authCubit.loadCachedData();
    }
    final local = serviceLocator<AuthLocalDataSource>();
    final list = await local.getOrganizationsAndSchools();
    if (mounted) {
      setState(() {
        _orgSchoolList = list;
        _loading = false;
      });
    }
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
          if (widget.isSwitchFlow && _loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is! AuthLoaded && !widget.isSwitchFlow) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final login = state is AuthLoaded ? state.loginResponse : null;
          final userName = login?.displayName.isNotEmpty == true
              ? login!.displayName
              : (login?.email ?? '');
          final userRole =
              login?.roles.isNotEmpty == true ? login!.roles.first.role : '';

          List<String> orgCodes;
          List<String> orgDisplayItems;
          if (widget.isSwitchFlow && _orgSchoolList.isNotEmpty) {
            orgCodes = _orgSchoolList
                .map((e) => e['organizationCode'] ?? '')
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            orgDisplayItems = orgCodes;
          } else if (state is AuthLoaded) {
            orgCodes = state.loginResponse.roles
                .map((r) => r.organizationCode)
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            final orgNames = state.orgNames;
            orgDisplayItems = (orgNames.length == orgCodes.length &&
                    orgNames.isNotEmpty)
                ? orgNames
                : orgCodes;
          } else {
            orgCodes = [];
            orgDisplayItems = [];
          }

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
                      child: SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: InkWell(
                          onTap: isNextEnabled
                              ? () {
                                  if (_selectedOrgCode == null) return;
                                  final schoolsForOrg = widget.isSwitchFlow
                                      ? _orgSchoolList
                                          .where((e) =>
                                              e['organizationCode'] ==
                                              _selectedOrgCode)
                                          .toList()
                                      : null;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SchoolSelectionScreen(
                                        selectedOrg: _selectedOrgCode!,
                                        isSwitchFlow: widget.isSwitchFlow,
                                        schoolsForOrg: schoolsForOrg,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: isNextEnabled
                                  ? AppColors.buildPrimaryGradient()
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500,
                                      ],
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                'Continue',
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
