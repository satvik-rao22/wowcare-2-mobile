import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/select_flow_header.dart';
import 'package:wowcare/shared/common/widgets/select_step_layout.dart';

class OrganizationSelectionScreen extends StatefulWidget {
  const OrganizationSelectionScreen({super.key});

  @override
  State<OrganizationSelectionScreen> createState() =>
      _OrganizationSelectionScreenState();
}

class _OrganizationSelectionScreenState
    extends State<OrganizationSelectionScreen> {
  String? _selectedOrg;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        // If org/school selection isn't completed, user must login again.
        context.read<AuthCubit>().logout();
        Navigator.pushReplacementNamed(context, SignInScreen.routeName);
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
        if (state is! AuthLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final login = state.loginResponse;
        final orgs = login.roles
            .map((r) => r.organizationCode)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();

        // Preselect first org for better UX
        if (_selectedOrg == null && orgs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedOrg = orgs.first);
          });
        }

        return SelectStepLayout(
          showBackButton: true,
          header: SelectFlowHeader(
            userName: login.displayName.isNotEmpty ? login.displayName : login.email,
            userRole: login.roles.isNotEmpty ? login.roles.first.role : '',
          ),
          title: 'Select Organization',
          selector: CustomDropdown(
            hintText: orgs.isNotEmpty ? orgs.first : 'No organizations',
            items: orgs,
            selectedItem: _selectedOrg,
            onSelect: (value) {
              setState(() {
                _selectedOrg = value;
              });
            },
          ),
          onNext: () {
            if (_selectedOrg == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SchoolSelectionScreen(selectedOrg: _selectedOrg!),
              ),
            );
          },
          isNextEnabled: _selectedOrg != null && orgs.isNotEmpty,
        );
        },
      ),
    );
  }
}
