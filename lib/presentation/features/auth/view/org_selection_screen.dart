import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/extensions/string_ext.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:wowcare/core/theme/app_icon.dart';

class OrganizationSelectionScreen extends StatefulWidget {
  const OrganizationSelectionScreen({super.key, this.isSwitchFlow = false});

  final bool isSwitchFlow;

  @override
  State<OrganizationSelectionScreen> createState() =>
      _OrganizationSelectionScreenState();
}

class _OrganizationSelectionScreenState
    extends State<OrganizationSelectionScreen> {
  // Local UI selection only (never read outside this screen), so this is a
  // ValueNotifier rather than cubit state — only the dropdown and the Next
  // button rebuild on selection, not the whole screen (Mandate 2).
  final _selectedOrgCode = ValueNotifier<String?>(null);
  bool _hasTriggeredOrgNamesLoad = false;

  @override
  void dispose() {
    _selectedOrgCode.dispose();
    super.dispose();
  }

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
        // When opened as a "switch organisation" flow:
        // - If there's a previous route (e.g. from Dashboard), just pop back.
        // - If this is the root route (e.g. app opened directly into
        //   Select Organization via login-context), exit the app instead
        //   of leaving a blank screen.
        if (context.canPop()) {
          context.pop();
        } else {
          SystemNavigator.pop();
        }
      } else {
        context.read<AuthCubit>().logout();
        context.go(SignInScreen.routeName);
      }
    }

    return PopScope(
      canPop: widget.isSwitchFlow,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
          final rawRole =
              login.roles.isNotEmpty ? login.roles.first.role : '';
          final userRole = rawRole.toDisplayRole;

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
          // Hide unresolved items (fallback raw org codes) from dropdown.
          final resolvedOrgCodes = <String>[];
          final resolvedOrgDisplayItems = <String>[];
          for (var i = 0; i < orgCodes.length && i < orgDisplayItems.length; i++) {
            final code = orgCodes[i].trim();
            final display = orgDisplayItems[i].trim();
            final isFallbackCode =
                display.isEmpty || display == code || display.toUpperCase().startsWith('ORG_');
            if (isFallbackCode) continue;
            resolvedOrgCodes.add(code);
            resolvedOrgDisplayItems.add(display);
          }

          return Scaffold(
            body: Container(
              color: AppColors.cardColor,
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
                            color: AppColors.authPrimaryTextColor,
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
                              Text(
                                  'WowCare',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.03,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.themeColor,
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
                                          fontFamily: AppFonts.body,
                                          fontSize: screenHeight * 0.022,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.authAccentTextColor,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text(
                                        userRole,
                                        style: TextStyle(
                                          fontFamily: AppFonts.body,
                                          fontSize: screenHeight * 0.016,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.authSecondaryTextColor,
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
                                    fontFamily: AppFonts.body,
                                    fontSize: screenHeight * 0.022,
                                    height: 2 / 6,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.authPrimaryTextColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Choose the organization you want to continue with.",
                                  style: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: screenHeight * 0.016,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.authPrimaryTextColor,
                                    height: 22 / 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: AppColors.authDividerColor,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              ValueListenableBuilder<String?>(
                                valueListenable: _selectedOrgCode,
                                builder: (context, selectedOrgCode, _) =>
                                    CustomDropdown(
                                  hintText: resolvedOrgDisplayItems.isNotEmpty
                                      ? 'Select organization'
                                      : 'No organizations',
                                  items: resolvedOrgDisplayItems,
                                  selectedItem: () {
                                    if (selectedOrgCode == null) return null;
                                    final index = resolvedOrgCodes
                                        .indexOf(selectedOrgCode);
                                    if (index != -1 &&
                                        index < resolvedOrgDisplayItems.length) {
                                      return resolvedOrgDisplayItems[index];
                                    }
                                    return null;
                                  }(),
                                  height: screenHeight * 0.06,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  leadingIcon: AppIcon(
                                    MediaRes.homeIcon,
                                    height: screenHeight * 0.022,
                                    width: screenHeight * 0.022,
                                    color: AppColors.authAccentTextColor,
                                  ),
                                  selectedTextStyle: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: screenHeight * 0.022,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.authPrimaryTextColor,
                                  ),
                                  popupItemTextStyle: TextStyle(
                                    fontFamily: AppFonts.body,
                                    fontSize: screenHeight * 0.02,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.authPrimaryTextColor,
                                  ),
                                  onSelect: (value) {
                                    if (value == null) {
                                      _selectedOrgCode.value = null;
                                    } else {
                                      final index = resolvedOrgDisplayItems
                                          .indexOf(value);
                                      if (index != -1 &&
                                          index < resolvedOrgCodes.length) {
                                        _selectedOrgCode.value =
                                            resolvedOrgCodes[index];
                                      }
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _selectedOrgCode,
                        builder: (context, selectedOrgCode, _) {
                          final isNextEnabled = selectedOrgCode != null &&
                              resolvedOrgCodes.contains(selectedOrgCode);
                          return CustomButtonLayout(
                            confirmButtonLabel: 'Next',
                            showCancelButton: false,
                            isForm: false,
                            onPressedConfirm: isNextEnabled
                                ? () async {
                                    final authCubit = context.read<AuthCubit>();
                                    await authCubit.updateLoginContext(
                                      lastLoginOrganizationCode: selectedOrgCode,
                                      lastLoginSchoolCode: null,
                                    );
                                    if (!context.mounted) return;
                                    // Always pass null so school selection
                                    // fetches fresh from API.
                                    context.push(
                                      AppRoutes.schoolSelection,
                                      extra: {
                                        'selectedOrg': selectedOrgCode,
                                        'isSwitchFlow': widget.isSwitchFlow,
                                        'schoolsForOrg': null,
                                        'orgFromLoginContext':
                                            !widget.isSwitchFlow,
                                      },
                                    );
                                  }
                                : null,
                          );
                        },
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
