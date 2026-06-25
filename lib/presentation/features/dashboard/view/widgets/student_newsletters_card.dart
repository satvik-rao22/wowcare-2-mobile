import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_newsletter_screen.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_entity_mapper.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class StudentNewslettersCard extends StatefulWidget {
  const StudentNewslettersCard({super.key});

  @override
  State<StudentNewslettersCard> createState() => _StudentNewslettersCardState();
}

class _StudentNewslettersCardState extends State<StudentNewslettersCard>
    with AutomaticKeepAliveClientMixin {
  bool _minimized = false;
  String _selectedChildCode = '';

  static const List<Color> _newsletterAccentColors = <Color>[
    Color(0xFFFFD54F),
    Color(0xFF80CBC4),
    Color(0xFFEF9A9A),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFCE93D8),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentChildProvider = Provider.of<ParentChildCubit>(context);
    final nextCode = (parentChildProvider.selectedChild?.code ?? '').trim();
    if (nextCode != _selectedChildCode) {
      _selectedChildCode = nextCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<StudentNewslettersCubit>().loadFirstPage(
          studentCode: nextCode,
        );
      });
    }
  }

  Future<void> _refresh() async {
    final code = _selectedChildCode.trim();
    if (code.isEmpty) return;
    await context.read<StudentNewslettersCubit>().loadFirstPage(
      studentCode: code,
      forceRefresh: true,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardCardHeader(
              title: 'Newsletter',
              showRedirect: true,
              onRedirect: () => context.go(ParentNewsletterScreen.routeName),
              minimized: _minimized,
              onToggle: () => setState(() => _minimized = !_minimized),
            ),
            if (!_minimized) ...[
              const SizedBox(height: 8),
              BlocBuilder<StudentNewslettersCubit, StudentNewslettersState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status ||
                    prev.items != curr.items ||
                    prev.errorMessage != curr.errorMessage,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: StudentAttendanceCardShimmer(),
                    );
                  }

                  if (state.isError && state.items.isEmpty) {
                    return _ErrorState(
                      message: state.errorMessage.isEmpty
                          ? 'Failed to load newsletters'
                          : state.errorMessage,
                      onRetry: _refresh,
                    );
                  }

                  final items = state.items;
                  if (items.isEmpty) {
                    return _EmptyState(onRefresh: _refresh);
                  }

                  // Preserve original mock design density: show the first 3 rows.
                  final visible = items.length > 3
                      ? items.sublist(0, 3)
                      : items;

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final accentColor =
                          _newsletterAccentColors[index %
                              _newsletterAccentColors.length];
                      final selectedChild = Provider.of<ParentChildCubit>(
                        context,
                      ).selectedChild;
                      final classroomName =
                          (selectedChild?.primaryClassroomName ??
                                  selectedChild?.classroom ??
                                  '')
                              .toString()
                              .trim();
                      return _NewsletterRow(
                        item: visible[index],
                        accentColor: accentColor,
                        classroomName: classroomName.isEmpty
                            ? '-'
                            : classroomName,
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsletterRow extends StatelessWidget {
  const _NewsletterRow({
    required this.item,
    required this.accentColor,
    required this.classroomName,
  });

  final NewsletterEntity item;
  final Color accentColor;
  final String classroomName;

  String _formatCreatedAt(DateTime? createdAt) {
    if (createdAt == null) return '-';
    return DateUtilsNew.formatToReadableDate(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final createdByName = item.createdByName.trim().isEmpty
        ? '-'
        : item.createdByName.trim();
    // final recipientCount = item.recipientCount;

    return InkWell(
      onTap: () {
        final code = item.code.trim();
        if (code.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PreviewNewsletterScreen(
              newsletterCode: code,
              initialNewsletter: mapNewsletterEntityToNewsletter(item),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NewsletterThumbnail(
              assetCode: item.assetCode,
              accentColor: accentColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(label: 'Created by', value: createdByName),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          _formatCreatedAt(item.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Icon(
                      //       Icons.remove_red_eye_outlined,
                      //       size: 14,
                      //       color: Colors.grey[600],
                      //     ),
                      //     const SizedBox(width: 4),
                      //     Text(
                      //       '$recipientCount',
                      //       maxLines: 1,
                      //       overflow: TextOverflow.ellipsis,
                      //       style: TextStyle(
                      //         color: Colors.grey[600],
                      //         fontSize: 13,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _MetaRow(label: 'Classroom', value: classroomName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsletterThumbnail extends StatelessWidget {
  const _NewsletterThumbnail({
    required this.assetCode,
    required this.accentColor,
  });

  final String? assetCode;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = assetCode != null && assetCode!.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 75,
        height: 75,
        child: hasImage
            ? DocumentImageWidget(
                fileUuid: '',
                mediaAssetCode: assetCode,
                name: '',
                size: 75,
                fontSize: 0,
                disableProfileLookupFallback: true,
                disableAttendanceStatusLookup: true,
              )
            : Container(
                color: accentColor.withValues(alpha: 0.18),
                child: Icon(
                  Icons.article_outlined,
                  color: accentColor,
                  size: 32,
                ),
              ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Force bounded width so flex children never see unbounded constraints
    // when the card is hosted in slivers / reorderable lists.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No newsletters found',
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
