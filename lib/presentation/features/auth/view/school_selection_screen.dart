import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

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
  bool _isSubmitting = false;
  Map<String, String> _schoolStatuses = const <String, String>{};

  /// Whether the inline option list under the field is showing. The design
  /// picks a school from a list that unfolds in place rather than a modal
  /// popup, so the chosen value and the choices stay on screen together.
  bool _isPickerOpen = false;

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
            return const SkeuScaffold(
              body: Center(
                child: CircularProgressIndicator(color: SkeuColors.teal600),
              ),
            );
          }

          final login = state is AuthLoaded ? state.loginResponse : null;

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
                  final status =
                      _schoolStatuses[(e['schoolCode'] ?? '').trim()];
                  return status == null || status == 'ACTIVE';
                }).toList();
          final schools = schoolEntries
              .map((e) => e['schoolName'] ?? e['schoolCode'] ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          final isLoading =
              state is AuthLoaded &&
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

          return SkeuScaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: SkeuIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: onBack,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),
                          const Center(
                            child: SkeuBrandLockup(
                              markSize: 70,
                              fontSize: 23,
                              careColor: SkeuColors.ink,
                            ),
                          ),
                          const SizedBox(height: 22),
                          // The organisation you came in through, stated as a
                          // small raised pill rather than a heading: it is
                          // context for the choice below, not the choice.
                          Center(child: _buildOrgPill(orgDisplayName)),
                          const SizedBox(height: 22),
                          const SkeuPageHeader(
                            title: 'Select School',
                            subtitle:
                                'Choose the school you want to continue with.',
                          ),
                          const SizedBox(height: 22),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: SkeuProgressBar(value: .35, height: 6),
                            ),
                          SkeuSelectField(
                            value: _selectedSchool,
                            hintText: isLoading
                                ? 'Loading schools...'
                                : (schools.isNotEmpty
                                      ? 'Select school'
                                      : 'No schools found'),
                            icon: Icons.school_outlined,
                            isOpen: _isPickerOpen,
                            enabled: schools.isNotEmpty,
                            onTap: () =>
                                setState(() => _isPickerOpen = !_isPickerOpen),
                          ),
                          if (_isPickerOpen && schoolEntries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SkeuOptionList(
                              children: [
                                for (var i = 0; i < schoolEntries.length; i++)
                                  ..._buildSchoolRow(schoolEntries, i),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SkeuButton(
                      label: 'Next',
                      radius: 18,
                      enabled: isNextEnabled,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleNext(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// One school in the unfolded list, preceded by a hairline for every row but
  /// the first. Tones rotate so a long list of rooms stays scannable.
  List<Widget> _buildSchoolRow(List<Map<String, String>> entries, int i) {
    final entry = entries[i];
    final name = entry['schoolName'] ?? entry['schoolCode'] ?? '';
    final code = entry['schoolCode'] ?? '';
    const tones = [SkeuTone.info, SkeuTone.sun, SkeuTone.pink, SkeuTone.ok];
    return [
      if (i > 0)
        const SkeuDivider(margin: EdgeInsets.symmetric(horizontal: 14)),
      SkeuOptionRow(
        label: name,
        subtitle: code.isNotEmpty && code != name ? code : null,
        selected: name == _selectedSchool,
        leading: SkeuIconTile(
          icon: Icons.apartment_rounded,
          size: 34,
          iconSize: 17,
          radius: 11,
          tone: tones[i % tones.length],
        ),
        onTap: () => setState(() {
          _selectedSchool = name;
          _selectedSchoolCode = code.isNotEmpty ? code : name;
          _isPickerOpen = false;
        }),
      ),
    ];
  }

  /// The organisation chip: a small raised pill carrying the org's name.
  Widget _buildOrgPill(String orgDisplayName) {
    return SkeuPanel(
      radius: SkeuRadius.pill,
      shadows: SkeuElevation.elev1,
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.apartment_rounded,
            size: 16,
            color: SkeuColors.teal700,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              orgDisplayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkeuText.small(
                color: SkeuColors.ink,
                weight: SkeuText.weightHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext(BuildContext context) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    if (_selectedSchool == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }
    final authCubit = context.read<AuthCubit>();
    final schoolCode = _selectedSchoolCode ?? _selectedSchool!;
    try {
      final blockMessage = await authCubit.verifySchoolActiveOrBlockMessage(
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
      // Prefetch profile + permissions + parent-child BEFORE opening Dashboard
      // so UI doesn't lazily trigger guardian/children calls.
      await authCubit.prefetchStaffProfileForOrgAndSchool(
        organizationCode: widget.selectedOrg,
        schoolCode: schoolCode,
      );
      if (!context.mounted) return;
      await context.read<RoleCubit>().refreshAccessFromServer(force: true);
      if (!context.mounted) return;
      context.read<ParentChildCubit>().invalidate();
      await context.read<ParentChildCubit>().ensureLoaded(force: true);
      if (!context.mounted) return;
      context.go(DashboardScreen.routeName);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
