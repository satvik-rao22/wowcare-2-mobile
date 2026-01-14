import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/select_flow_header.dart';
import 'package:wowcare/shared/common/widgets/select_step_layout.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({
    super.key,
    required this.selectedOrg,
  });

  final String selectedOrg;

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  String? _selectedSchool;

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
        final schools = state.schoolsByOrg[widget.selectedOrg] ?? const <String>[];
        final isLoading = state.isPrefetchingSchools && schools.isEmpty;

        // Preselect first school for better UX
        if (_selectedSchool == null && schools.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedSchool = schools.first);
          });
        }

        return SelectStepLayout(
          showBackButton: true,
          header: SelectFlowHeader(
            userName: login.displayName.isNotEmpty ? login.displayName : login.email,
            userRole: login.roles.isNotEmpty ? login.roles.first.role : '',
          ),
          subtitle: widget.selectedOrg,
          title: 'Select your School',
          selector: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
              CustomDropdown(
                hintText: isLoading
                    ? 'Loading schools...'
                    : (schools.isNotEmpty ? schools.first : 'No schools found'),
                items: schools,
                selectedItem: _selectedSchool,
                onSelect: (value) {
                  setState(() {
                    _selectedSchool = value;
                  });
                },
              ),
            ],
          ),
          onNext: () {
            if (_selectedSchool == null) return;
            // Mark login completed only after org + school selection
            context.read<AuthCubit>().completeLogin(
                  selectedOrgCode: widget.selectedOrg,
                  selectedSchoolName: _selectedSchool!,
                );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
          },
          isNextEnabled: _selectedSchool != null && schools.isNotEmpty,
        );
        },
      ),
    );
  }
}
