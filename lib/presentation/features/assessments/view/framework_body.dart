import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_access.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/age_group_manager_sheet.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_confirm_dialog.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_option_sheet.dart';
import 'package:wowcare/presentation/features/assessments/widgets/entrance.dart';
import 'package:wowcare/presentation/features/assessments/widgets/parameter_form_sheets.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Parameters tab — browse/manage the Domain → Subdomain → Milestone hierarchy.
/// Staff see it read-only (a banner explains why); admins get add/edit/
/// deactivate and age-group assignment, plus an Age Groups card for managing
/// the school's bands. The level shown is driven by the
/// [domainId]/[subdomainId] drill-state owned by the shell.
class FrameworkBody extends StatelessWidget {
  const FrameworkBody({
    super.key,
    required this.domainId,
    required this.subdomainId,
    required this.onOpenDomain,
    required this.onOpenSubdomain,
  });

  final String? domainId;
  final String? subdomainId;
  final ValueChanged<String> onOpenDomain;
  final ValueChanged<String> onOpenSubdomain;

  @override
  Widget build(BuildContext context) {
    final canManage =
        AssessmentAccess.canManageParameters(context.watch<RoleCubit>());
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        if (subdomainId != null && domainId != null) {
          return _MilestoneList(
            domain: state.domainById(domainId!),
            subdomainId: subdomainId!,
            canManage: canManage,
          );
        }
        if (domainId != null) {
          return _SubdomainList(
            domain: state.domainById(domainId!),
            canManage: canManage,
            onOpenSubdomain: onOpenSubdomain,
          );
        }
        return _DomainList(
          domains: state.activeDomains,
          canManage: canManage,
          onOpenDomain: onOpenDomain,
        );
      },
    );
  }
}

// ------------------------------------------------------------- domains level

class _DomainList extends StatelessWidget {
  const _DomainList({
    required this.domains,
    required this.canManage,
    required this.onOpenDomain,
  });

  final List<AssessmentDomain> domains;
  final bool canManage;
  final ValueChanged<String> onOpenDomain;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
      children: [
        if (!canManage) const _ReadOnlyBanner(),
        _AgeGroupsCard(canManage: canManage),
        if (domains.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text('No domains defined yet.',
                  style: TextStyle(color: AssessmentUi.inkMuted)),
            ),
          )
        else
          ...domains.asMap().entries.map((e) {
            final d = e.value;
            return Entrance(
              index: e.key,
              child: _EntityCard(
                color: AssessmentUi.domainColor(d.id),
                icon: Icons.account_tree_rounded,
                title: d.name,
                badges: [
                  '${d.activeSubdomains.length} subdomains',
                  '${d.activeMilestoneCount} milestones',
                ],
                canManage: canManage,
                onTap: () => onOpenDomain(d.id),
                onMenu: () =>
                    FrameworkActions.openMenu(context, kind: 'domain', domain: d),
              ),
            );
          }),
      ],
    );
  }
}

// --------------------------------------------------------- subdomains level

class _SubdomainList extends StatelessWidget {
  const _SubdomainList({
    required this.domain,
    required this.canManage,
    required this.onOpenSubdomain,
  });

  final AssessmentDomain? domain;
  final bool canManage;
  final ValueChanged<String> onOpenSubdomain;

  @override
  Widget build(BuildContext context) {
    final d = domain;
    if (d == null) {
      return const Center(child: Text('Domain not found.'));
    }
    final subs = d.activeSubdomains;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        if (d.description.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: AssessmentUi.softSurface(radius: 16),
            child: Text(
              d.description,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: Color(0xFF574F66),
              ),
            ),
          ),
        if (subs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No subdomains yet.',
                  style: TextStyle(color: AssessmentUi.inkMuted)),
            ),
          )
        else
          ...subs.asMap().entries.map((e) {
            final s = e.value;
            return Entrance(
              index: e.key,
              child: _EntityCard(
                color: AssessmentUi.domainColor(d.id),
                icon: Icons.segment_rounded,
                title: s.name,
                badges: ['${s.activeMilestones.length} milestones'],
                canManage: canManage,
                onTap: () => onOpenSubdomain(s.id),
                onMenu: () => FrameworkActions.openMenu(context,
                    kind: 'subdomain', subdomain: s, domain: d),
              ),
            );
          }),
      ],
    );
  }
}

// --------------------------------------------------------- milestones level

class _MilestoneList extends StatelessWidget {
  const _MilestoneList({
    required this.domain,
    required this.subdomainId,
    required this.canManage,
  });

  final AssessmentDomain? domain;
  final String subdomainId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final d = domain;
    final subs =
        d?.subdomains.where((s) => s.id == subdomainId).toList() ?? const [];
    if (d == null || subs.isEmpty) {
      return const Center(child: Text('Subdomain not found.'));
    }
    final sub = subs.first;
    final milestones = sub.activeMilestones;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        if (milestones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No milestones yet.',
                  style: TextStyle(color: AssessmentUi.inkMuted)),
            ),
          )
        else
          ...milestones.asMap().entries.map((e) => Entrance(
                index: e.key,
                child: _MilestoneCard(
                  milestone: e.value,
                  canManage: canManage,
                  ageGroupName: (id) =>
                      context.read<AssessmentsCubit>().state.ageGroupById(id)?.name ??
                      id,
                  onMenu: () => FrameworkActions.openMenu(context,
                      kind: 'milestone', milestone: e.value, domain: d),
                ),
              )),
      ],
    );
  }
}

// --------------------------------------------------------------- shared cards

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final palette = AssessmentUi.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: palette.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Read-only — you can view the parameters you assess against.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: palette.brandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entry card for managing the school's age bands — the assignment scope for
/// every parameter below it. Admins manage; staff view.
class _AgeGroupsCard extends StatelessWidget {
  const _AgeGroupsCard({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final palette = AssessmentUi.palette;
    final groups = context
        .watch<AssessmentsCubit>()
        .state
        .activeAgeGroups;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AssessmentUi.softSurface(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AgeGroupManagerSheet.show(context, canManage: canManage),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.child_care_rounded,
                      size: 22, color: palette.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Age Groups',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AssessmentUi.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        groups.isEmpty
                            ? 'No bands defined yet'
                            : '${groups.length} bands · '
                                '${groups.map((g) => g.rangeLabel).join(' · ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AssessmentUi.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  canManage ? Icons.tune_rounded : Icons.chevron_right_rounded,
                  size: 20,
                  color: canManage ? palette.brand : const Color(0xFFC0BACD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.badges,
    required this.canManage,
    required this.onTap,
    required this.onMenu,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<String> badges;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AssessmentUi.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badges
                            .map((b) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AssessmentUi.palette.brandSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AssessmentUi.palette.brand,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  _MenuButton(onMenu: onMenu)
                else
                  const Icon(Icons.chevron_right_rounded,
                      size: 22, color: Color(0xFFC0BACD)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.canManage,
    required this.ageGroupName,
    required this.onMenu,
  });

  final AssessmentMilestone milestone;
  final bool canManage;
  final String Function(String id) ageGroupName;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final ageGroups = milestone.assignedAgeGroups;
    final palette = AssessmentUi.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: AssessmentUi.softSurface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AssessmentUi.ink,
                      ),
                    ),
                    if (milestone.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          milestone.description,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: AssessmentUi.inkMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (canManage) _MenuButton(onMenu: onMenu),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (ageGroups.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 11, color: Color(0xFFB91C1C)),
                      SizedBox(width: 4),
                      Text(
                        'No age groups assigned',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...ageGroups.map((id) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.chipBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: palette.chipBorder),
                      ),
                      child: Text(
                        ageGroupName(id),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: palette.chipFg,
                        ),
                      ),
                    )),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onMenu,
      borderRadius: BorderRadius.circular(10),
      child: const SizedBox(
        width: 34,
        height: 34,
        child: Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFFB7B1C4)),
      ),
    );
  }
}

/// Orchestrates the framework write flows (add/edit/deactivate/assign) against
/// the cubit. Kept here so the shell's FAB/back-bar actions and the per-row
/// menus share one implementation.
abstract final class FrameworkActions {
  const FrameworkActions._();

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AssessmentUi.ink,
      ));
  }

  static Future<void> addDomain(BuildContext context) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await DomainFormSheet.show(context,
        ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveDomain(result);
    if (context.mounted) _toast(context, ok ? 'Domain added' : 'Save failed');
  }

  static Future<void> editDomain(
      BuildContext context, AssessmentDomain domain) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await DomainFormSheet.show(context,
        initial: domain, ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveDomain(result);
    if (context.mounted) _toast(context, ok ? 'Changes saved' : 'Save failed');
  }

  static Future<void> addSubdomain(BuildContext context,
      {required String domainId}) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await SubdomainFormSheet.show(context,
        domainId: domainId, ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveSubdomain(result);
    if (context.mounted) _toast(context, ok ? 'Subdomain added' : 'Save failed');
  }

  static Future<void> editSubdomain(BuildContext context,
      {required String domainId, required AssessmentSubdomain subdomain}) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await SubdomainFormSheet.show(context,
        domainId: domainId,
        initial: subdomain,
        ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveSubdomain(result);
    if (context.mounted) _toast(context, ok ? 'Changes saved' : 'Save failed');
  }

  static Future<void> addMilestone(BuildContext context,
      {required String domainId, required String subdomainId}) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await MilestoneFormSheet.show(context,
        domainId: domainId,
        subdomainId: subdomainId,
        ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveMilestone(result);
    if (context.mounted) _toast(context, ok ? 'Milestone added' : 'Save failed');
  }

  static Future<void> editMilestone(BuildContext context,
      {required AssessmentMilestone milestone}) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await MilestoneFormSheet.show(context,
        domainId: milestone.domainId,
        subdomainId: milestone.subdomainId,
        initial: milestone,
        ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.saveMilestone(result);
    if (context.mounted) _toast(context, ok ? 'Changes saved' : 'Save failed');
  }

  static Future<void> assignAgeGroups(
      BuildContext context, AssessmentMilestone milestone) async {
    final cubit = context.read<AssessmentsCubit>();
    final result = await AgeGroupAssignmentSheet.show(context,
        milestone: milestone, ageGroups: cubit.state.activeAgeGroups);
    if (result == null || !context.mounted) return;
    final ok = await cubit.updateMilestoneAgeGroups(milestone.id, result);
    if (context.mounted) {
      _toast(context, ok ? 'Assignment saved' : 'Save failed');
    }
  }

  static Future<void> openMenu(
    BuildContext context, {
    required String kind,
    AssessmentDomain? domain,
    AssessmentSubdomain? subdomain,
    AssessmentMilestone? milestone,
  }) async {
    final name = milestone?.name ?? subdomain?.name ?? domain?.name ?? '';
    final selection = await AssessmentOptionSheet.show<String>(
      context,
      title: name,
      options: [
        if (kind == 'milestone')
          const AssessmentOption(
            value: 'assign',
            title: 'Assign age groups',
            icon: Icons.child_care_rounded,
          ),
        const AssessmentOption(
          value: 'edit',
          title: 'Edit',
          icon: Icons.edit_outlined,
        ),
        const AssessmentOption(
          value: 'deactivate',
          title: 'Deactivate',
          icon: Icons.delete_outline_rounded,
          destructive: true,
        ),
      ],
    );
    if (selection == null || !context.mounted) return;
    switch (selection) {
      case 'assign':
        if (milestone != null) await assignAgeGroups(context, milestone);
        break;
      case 'edit':
        if (kind == 'domain' && domain != null) {
          await editDomain(context, domain);
        } else if (kind == 'subdomain' && subdomain != null) {
          await editSubdomain(context,
              domainId: subdomain.domainId, subdomain: subdomain);
        } else if (milestone != null) {
          await editMilestone(context, milestone: milestone);
        }
        break;
      case 'deactivate':
        await _confirmDeactivate(context,
            kind: kind, domain: domain, subdomain: subdomain, milestone: milestone);
        break;
    }
  }

  static Future<void> _confirmDeactivate(
    BuildContext context, {
    required String kind,
    AssessmentDomain? domain,
    AssessmentSubdomain? subdomain,
    AssessmentMilestone? milestone,
  }) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Deactivate $kind?',
      message: 'It will be hidden from active views. Historical assessment '
          'data is preserved.',
      confirmLabel: 'Deactivate',
    );
    if (!confirmed || !context.mounted) return;
    final cubit = context.read<AssessmentsCubit>();
    bool ok = false;
    if (kind == 'domain' && domain != null) {
      ok = await cubit.deactivateDomain(domain.id);
    } else if (kind == 'subdomain' && subdomain != null) {
      ok = await cubit.deactivateSubdomain(subdomain.id);
    } else if (milestone != null) {
      ok = await cubit.deactivateMilestone(milestone.id);
    }
    if (context.mounted) {
      _toast(context,
          ok ? '${kind[0].toUpperCase()}${kind.substring(1)} deactivated' : 'Failed');
    }
  }
}
