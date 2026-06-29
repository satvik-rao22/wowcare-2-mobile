import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/newsletter/view/parent_newsletter_list_tab.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import '../../../../app/theme/colors.dart';

/// Parent-only newsletters screen (student-scoped API, separate from staff/admin sent list).
class ParentNewsletterScreen extends StatefulWidget {
  const ParentNewsletterScreen({super.key});

  static const String routeName = '/dashboard/parent-newsletter';

  @override
  State<ParentNewsletterScreen> createState() => _ParentNewsletterScreenState();
}

class _ParentNewsletterScreenState extends State<ParentNewsletterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _newsLetterTabController;
  String _trackedChildCode = '';

  @override
  void initState() {
    super.initState();
    _newsLetterTabController = TabController(length: 1, vsync: this);
    _newsLetterTabController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelectedChild();
  }

  void _syncSelectedChild() {
    final parentChild = context.read<ParentChildCubit>();
    if (!parentChild.isLoaded && !parentChild.isLoading) {
      Future.microtask(parentChild.ensureLoaded);
    }
    final nextCode = (parentChild.selectedChild?.code ?? '').trim();
    if (nextCode == _trackedChildCode) return;
    _trackedChildCode = nextCode;
    if (nextCode.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentNewslettersCubit>().loadFirstPage(
        studentCode: nextCode,
      );
    });
  }

  @override
  void dispose() {
    _newsLetterTabController.dispose();
    super.dispose();
  }

  Tab _buildSingleMessagingTab({required String label, required int index}) {
    return Tab(
      child: Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 118),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _newsLetterTabController.index == index
              ? AppColors.classroomStudentTabColor
              : const Color.fromARGB(102, 203, 246, 255),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border.all(
            color: _newsLetterTabController.index == index
                ? AppColors.themeColor
                : Colors.transparent,
            width: 1.25,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 15,
              color: _newsLetterTabController.index == index
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsLatterTabs() {
    final TabBar tabBar = TabBar(
      tabs: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildSingleMessagingTab(label: 'Newsletter', index: 0),
        ),
      ],
      controller: _newsLetterTabController,
      isScrollable: true,
      labelColor: Colors.black,
      unselectedLabelColor: const Color.fromARGB(50, 36, 22, 49),
      tabAlignment: TabAlignment.center,
      indicatorColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 0),
      dividerHeight: 0,
      indicator: const BoxDecoration(),
    );
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [tabBar],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentChildCubit, ParentChildState>(
      builder: (context, state) {
        final selectedCode = (state.selectedChild?.code ?? '').trim();
        if (selectedCode.isNotEmpty && selectedCode != _trackedChildCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _trackedChildCode = selectedCode;
            context.read<StudentNewslettersCubit>().loadFirstPage(
              studentCode: selectedCode,
            );
          });
        }

        return GlobalScaffold(
          hasBackButton: false,
          isParent: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(
                  'Newsletter',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Transform.translate(
                offset: const Offset(0, 5),
                child: _buildNewsLatterTabs(),
              ),
              const SizedBox(height: 14),
              const Expanded(child: ParentNewsletterListTab()),
            ],
          ),
        );
      },
    );
  }
}
