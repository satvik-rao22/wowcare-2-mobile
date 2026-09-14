import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/extensions/string_ext.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

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
  // UI-local selection + in-flight state, never read outside this screen —
  // ValueNotifier rather than setState so only the dropdown/button subtree
  // rebuilds, not the whole screen (Mandate 2). _schoolStatuses stays a
  // plain field + setState: it's sourced from an API, which per Mandate 2
  // belongs in cubit state — promoting it there is a larger, separate change
  // (AuthCubit's state shape is shared well beyond this screen), so this one
  // call is left as the smallest correct compromise rather than mislabelling
  // API data as local UI state.
  final _selectedSchool = ValueNotifier<String?>(null);
  final _selectedSchoolCode = ValueNotifier<String?>(null);
  final _isSubmitting = ValueNotifier<bool>(false);
  bool _hasTriggeredLoad = false;
  Map<String, String> _schoolStatuses = const <String, String>{};

  @override
  void dispose() {
    _selectedSchool.dispose();
    _selectedSchoolCode.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always fetch fresh school names from API (no cache)
    if (!_hasTriggeredLoad) {
      _hasTriggeredLoad = true;
      context.read<AuthCubit>().loadSchoolsForOrg(widget.selectedOrg);
      _loadSchoolStatuses();
    }
  }

  // Live backend statuses (not the post-login `/users/details` cache, which
  // may not exist yet this early in the login flow) so PENDING schools can
  // be hidden from this picker. Unknown/missing status is treated as active.
  Future<void> _loadSchoolStatuses() async {
    final statuses = await context.read<AuthCubit>().fetchSchoolStatusesForOrg(
      widget.selectedOrg,
    );
    if (!mounted || statuses.isEmpty) return;
    setState(() => _schoolStatuses = statuses);
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
        context.go(
          '/org-selection',
          extra: <String, dynamic>{'isSwitchFlow': true},
        );
        return;
      }
      context.read<AuthCubit>().logout();
      context.go(SignInScreen.routeName);
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
          final userRole = rawRole.toDisplayRole;

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

          final List<Map<String, String>> allSchoolEntries =
              widget.schoolsForOrg != null
                  ? widget.schoolsForOrg!
                  : (state is AuthLoaded
                      ? (state.schoolsByOrg[widget.selectedOrg] ?? const [])
                      : const <Map<String, String>>[]);
          // Hide schools that are not yet ACTIVE (e.g. still PENDING
          // approval) from the picker.
          final schoolEntries = _schoolStatuses.isEmpty
              ? allSchoolEntries
              : allSchoolEntries.where((e) {
                  final status = _schoolStatuses[(e['schoolCode'] ?? '').trim()];
                  return status == null || status == 'ACTIVE';
                }).toList();
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
                                    color: AppColors.cardColor,
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
                                          fontFamily: Fonts.manrope,
                                          fontSize: screenHeight * 0.022,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.authAccentTextColor,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text(
                                        userRole,
                                        style: TextStyle(
                                          fontFamily: Fonts.manrope,
                                          fontSize: screenHeight * 0.016,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.authSecondaryTextColor,
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
                                  fontFamily: Fonts.manrope,
                                  fontSize: screenHeight * 0.02,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.authAccentTextColor,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select your School',
                                  style: TextStyle(
                                    fontFamily: Fonts.manrope,
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
                                  "Choose the school you want to continue with.",
                                  style: TextStyle(
                                    fontFamily: Fonts.manrope,
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
                              if (isLoading)
                                Padding(
                                  padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                                  child: const LinearProgressIndicator(),
                                ),
                              ValueListenableBuilder<String?>(
                                valueListenable: _selectedSchool,
                                builder: (context, selectedSchool, _) =>
                                    CustomDropdown(
                                  hintText: isLoading
                                      ? 'Loading schools...'
                                      : (schools.isNotEmpty
                                          ? 'Select school'
                                          : 'No schools found'),
                                  items: schools,
                                  selectedItem: selectedSchool,
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
                                      AppColors.authAccentTextColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  selectedTextStyle: TextStyle(
                                    fontFamily: Fonts.manrope,
                                    fontSize: screenHeight * 0.022,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.authPrimaryTextColor,
                                  ),
                                  popupItemTextStyle: TextStyle(
                                    fontFamily: Fonts.manrope,
                                    fontSize: screenHeight * 0.02,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.authPrimaryTextColor,
                                  ),
                                  onSelect: (value) {
                                    _selectedSchool.value = value;
                                    if (value != null && schoolEntries.isNotEmpty) {
                                      final entry = schoolEntries.firstWhere(
                                        (e) =>
                                            (e['schoolName'] ?? e['schoolCode']) ==
                                            value,
                                        orElse: () => <String, String>{},
                                      );
                                      _selectedSchoolCode.value =
                                          entry['schoolCode'] ?? entry['schoolName'];
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
                      child: ListenableBuilder(
                        listenable:
                            Listenable.merge([_selectedSchool, _isSubmitting]),
                        builder: (context, _) {
                          final selectedSchool = _selectedSchool.value;
                          final isSubmitting = _isSubmitting.value;
                          final isNextEnabled =
                              selectedSchool != null && schools.isNotEmpty;
                          return CustomButtonLayout(
                            confirmButtonLabel: 'Next',
                            showCancelButton: false,
                            isForm: false,
                            isLoading: isSubmitting,
                            onPressedConfirm: isNextEnabled
                                ? () async {
                                    if (_isSubmitting.value) return;
                                    _isSubmitting.value = true;
                                    final schoolName = _selectedSchool.value;
                                    if (schoolName == null) {
                                      _isSubmitting.value = false;
                                      return;
                                    }
                                    final authCubit = context.read<AuthCubit>();
                                    final schoolCode =
                                        _selectedSchoolCode.value ?? schoolName;
                                    try {
                                      final blockMessage = await authCubit
                                          .verifySchoolActiveOrBlockMessage(
                                        organizationCode: widget.selectedOrg,
                                        schoolCode: schoolCode,
                                      );
                                      if (blockMessage != null) {
                                        if (!context.mounted) return;
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: blockMessage,
                                          isError: true,
                                        );
                                        return;
                                      }
                                      await authCubit.updateLoginContext(
                                        lastLoginOrganizationCode:
                                            widget.selectedOrg,
                                        lastLoginSchoolCode: schoolCode,
                                      );
                                      if (widget.isSwitchFlow) {
                                        await authCubit.setSelectedOrgAndSchool(
                                          organizationCode: widget.selectedOrg,
                                          schoolCode: schoolCode,
                                          schoolName: schoolName,
                                        );
                                      } else {
                                        await authCubit.completeLogin(
                                          selectedOrgCode: widget.selectedOrg,
                                          selectedSchoolName: schoolName,
                                          selectedSchoolCode:
                                              _selectedSchoolCode.value,
                                        );
                                      }
                                      // Prefetch profile + permissions + parent-child
                                      // BEFORE opening Dashboard so UI doesn't lazily
                                      // trigger guardian/children calls.
                                      await authCubit
                                          .prefetchStaffProfileForOrgAndSchool(
                                        organizationCode: widget.selectedOrg,
                                        schoolCode: schoolCode,
                                      );
                                      if (!context.mounted) return;
                                      await context
                                          .read<RoleCubit>()
                                          .refreshAccessFromServer(force: true);
                                      if (!context.mounted) return;
                                      context
                                          .read<ParentChildCubit>()
                                          .invalidate();
                                      await context
                                          .read<ParentChildCubit>()
                                          .ensureLoaded(force: true);
                                      if (!context.mounted) return;
                                      context.go(DashboardScreen.routeName);
                                    } finally {
                                      if (mounted) {
                                        _isSubmitting.value = false;
                                      }
                                    }
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
