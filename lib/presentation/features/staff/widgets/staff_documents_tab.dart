import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/staff/view/add_document_screen.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_document_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import 'package:wowcare/app/di/di.dart';

class StaffDocumentsTab extends StatefulWidget {
  const StaffDocumentsTab({
    super.key,
    required this.staffCode,
  });

  final String staffCode;

  @override
  State<StaffDocumentsTab> createState() => _StaffDocumentsTabState();
}

class _StaffDocumentsTabState extends State<StaffDocumentsTab> {
  bool _showExpired = false;
  late final StaffDocumentsListCubit _documentsListCubit;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _documentsListCubit = serviceLocator<StaffDocumentsListCubit>()
      ..loadInitial(widget.staffCode, expired: _showExpired ? true : null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _documentsListCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffDocumentsListCubit>.value(
      value: _documentsListCubit,
      child: Scaffold(
          body: BlocBuilder<StaffDocumentsListCubit, StaffDocumentsListState>(
            builder: (context, state) {
              if (state.isLoading && state.documents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Use documents directly from API - no frontend filtering
              final documents = state.documents;

              return CustomRefreshIndicator(
                onRefresh: () async {
                  await _documentsListCubit.refresh(
                    widget.staffCode,
                    expired: _showExpired ? true : null,
                  );
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Only trigger on actual scroll updates, not on initial layout
                    if (notification is ScrollUpdateNotification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                        final state = _documentsListCubit.state;
                        if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
                          _documentsListCubit.loadNextPage(
                            widget.staffCode,
                            expired: _showExpired ? true : null,
                          );
                        }
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white,
                          ),
          child: CustomToggle(
            label: 'Show Expired Documents',
            isToggled: _showExpired,
            onToggle: (v) {
              setState(() => _showExpired = v);
              // Call API with the new filter
              _documentsListCubit.refresh(
                widget.staffCode,
                expired: v ? true : null,
              );
            },
          ),
                        ),
                        const SizedBox(height: 16),
                        if (documents.isEmpty)
                          Text(
                            _showExpired ? 'No expired documents found' : 'No documents found',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 16,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: documents.length,
                            itemBuilder: (context, i) {
                              final doc = documents[i];
                              final expiryDate = DateFormat('yyyy-MM-dd').parse(doc.expiryDate);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ExpansionTile(
                                  title: Text(
                                    doc.documentName,
                                    style: const TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const SizedBox.shrink(),
                                  backgroundColor: Colors.white,
                                  collapsedBackgroundColor: Colors.white,
                                  collapsedShape: RoundedRectangleBorder(
                                    side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: AppColors.primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  children: [
                                    Divider(color: AppColors.primaryColor.withOpacity(0.1)),
                                    const SizedBox(height: 16),
                                    _DocRow(label: 'Document Type', text: doc.documentType),
                                    const SizedBox(height: 16),
                                    _DocRow(
                                      label: 'Expiry Date',
                                      text: DateFormat('MMM dd, yyyy').format(expiryDate),
                                    ),
                                    const SizedBox(height: 16),
                                    _DocRow(label: 'Document', text: doc.documentName, trailingIcon: Icons.insert_drive_file_outlined),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (state.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: PrimaryCircularLoader(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            },
          ),
          floatingActionButton: GradientAddButton(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider<StaffDocumentCubit>(
                    create: (_) => serviceLocator<StaffDocumentCubit>(),
                    child: AddDocumentScreen(
                      staffCode: widget.staffCode,
                    ),
                  ),
                ),
              ).then((result) {
                // Refresh documents list after successfully adding a new document
                // Cache is already invalidated in repository, so this will fetch fresh data
                if (result == true && mounted) {
                  _documentsListCubit.refresh(
                    widget.staffCode,
                    expired: _showExpired ? true : null,
                  );
                }
              });
            },
            size: 50.0,
            iconSize: 28.0,
            borderRadius: 12.0,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
    );
  }
}


class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.text, this.trailingIcon});
  final String label;
  final String text;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              letterSpacing: 14 * (-3 / 100),
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (trailingIcon == null)
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          SvgPicture.asset(
            MediaRes.documents_drawer_Icon,
            height: 20,
            // colorFilter: const ColorFilter.mode(AppColors.themeColor, BlendMode.srcIn),
          ),
      ],
    );
  }
}

