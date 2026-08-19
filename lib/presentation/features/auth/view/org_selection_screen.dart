import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

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

  /// Whether the inline option list under the field is showing. The design
  /// picks an org from a list that unfolds in place rather than a modal popup,
  /// so the chosen value and the choices stay on screen together.
  bool _isPickerOpen = false;

  String _formatRole(String role) {
    if (role.isEmpty) return '';
    final cleaned = role.toLowerCase().replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always fetch fresh org names from API (no cache)
    if (_hasTriggeredOrgNamesLoad) return;
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is! AuthLoaded) return;
    final orgCodes = (authCubit.state as AuthLoaded).loginResponse.roles
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
    void onBack() {
      if (widget.isSwitchFlow) {
        // When opened as a "switch organisation" flow:
        // - If there's a previous route (e.g. from Dashboard), just pop back.
        // - If this is the root route (e.g. app opened directly into
        //   Select Organization via login-context), exit the app instead
        //   of leaving a blank screen.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
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
      onPopInvokedWithResult: (didPop, _) {
        if (!widget.isSwitchFlow) onBack();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthLoaded) {
            return const SkeuScaffold(
              body: Center(
                child: CircularProgressIndicator(color: SkeuColors.teal600),
              ),
            );
          }

          final login = state.loginResponse;
          final userName = login.displayName.isNotEmpty
              ? login.displayName
              : login.email;
          final rawRole = login.roles.isNotEmpty ? login.roles.first.role : '';
          final userRole = _formatRole(rawRole);

          // Always use roles for org codes; org names from API (no cache)
          final orgCodes = state.loginResponse.roles
              .map((r) => r.organizationCode)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();
          final orgNames = state.orgNames;
          final orgDisplayItems =
              (orgNames.length == orgCodes.length && orgNames.isNotEmpty)
              ? orgNames
              : orgCodes;
          // Hide unresolved items (fallback raw org codes) from dropdown.
          final resolvedOrgCodes = <String>[];
          final resolvedOrgDisplayItems = <String>[];
          for (
            var i = 0;
            i < orgCodes.length && i < orgDisplayItems.length;
            i++
          ) {
            final code = orgCodes[i].trim();
            final display = orgDisplayItems[i].trim();
            final isFallbackCode =
                display.isEmpty ||
                display == code ||
                display.toUpperCase().startsWith('ORG_');
            if (isFallbackCode) continue;
            resolvedOrgCodes.add(code);
            resolvedOrgDisplayItems.add(display);
          }

          final isNextEnabled =
              _selectedOrgCode != null &&
              resolvedOrgCodes.contains(_selectedOrgCode);

          final selectedIndex = _selectedOrgCode == null
              ? -1
              : resolvedOrgCodes.indexOf(_selectedOrgCode!);
          final selectedLabel =
              selectedIndex >= 0 &&
                  selectedIndex < resolvedOrgDisplayItems.length
              ? resolvedOrgDisplayItems[selectedIndex]
              : null;

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
                          _buildIdentityCard(
                            login.userCode,
                            userName,
                            userRole,
                          ),
                          const SizedBox(height: 22),
                          const SkeuPageHeader(
                            title: 'Select Organization',
                            subtitle:
                                'Choose the organization you want to continue with.',
                          ),
                          const SizedBox(height: 22),
                          SkeuSelectField(
                            value: selectedLabel,
                            hintText: resolvedOrgDisplayItems.isNotEmpty
                                ? 'Select organization'
                                : 'No organizations',
                            icon: Icons.apartment_rounded,
                            isOpen: _isPickerOpen,
                            enabled: resolvedOrgDisplayItems.isNotEmpty,
                            onTap: () =>
                                setState(() => _isPickerOpen = !_isPickerOpen),
                          ),
                          if (_isPickerOpen &&
                              resolvedOrgDisplayItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SkeuOptionList(
                              children: [
                                for (
                                  var i = 0;
                                  i < resolvedOrgDisplayItems.length;
                                  i++
                                )
                                  SkeuOptionRow(
                                    label: resolvedOrgDisplayItems[i],
                                    selected:
                                        resolvedOrgCodes[i] == _selectedOrgCode,
                                    leading: SkeuIconTile(
                                      icon: Icons.apartment_rounded,
                                      size: 34,
                                      iconSize: 17,
                                      radius: 11,
                                      tone: i.isEven
                                          ? SkeuTone.info
                                          : SkeuTone.sun,
                                    ),
                                    onTap: () => setState(() {
                                      _selectedOrgCode = resolvedOrgCodes[i];
                                      _isPickerOpen = false;
                                    }),
                                  ),
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
                      onPressed: () async {
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
                      },
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

  /// Who you are signing in as: photo bead, name, role. A raised panel, because
  /// it states a fact rather than offering a choice.
  Widget _buildIdentityCard(String userCode, String userName, String userRole) {
    return SkeuPanel(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeuAvatarFrame(
            size: 54,
            tone: SkeuTone.pink,
            child: DocumentImageWidget(
              fileUuid: userCode,
              name: userName,
              size: 54,
              fontSize: 19,
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkeuText.title(),
                ),
                if (userRole.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(userRole, style: SkeuText.small()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
