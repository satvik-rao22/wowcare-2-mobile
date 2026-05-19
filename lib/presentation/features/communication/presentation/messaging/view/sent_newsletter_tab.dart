import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/newsletter_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/send_newslatter_list.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class SentNewsLetterTab extends StatefulWidget {
  const SentNewsLetterTab({super.key});

  @override
  State<SentNewsLetterTab> createState() => _SentNewsLetterTabState();
}

class _SentNewsLetterTabState extends State<SentNewsLetterTab> {
  final TextEditingController searchController = TextEditingController();
  late final NewsletterListCubit _newsletterListCubit;
  String? selectedClassroom;
  List<Newsletter> _allNewsletters = <Newsletter>[];
  List<Newsletter> _filteredNewsletters = <Newsletter>[];
  List<String> _allRooms = <String>[];

  @override
  void initState() {
    super.initState();
    _newsletterListCubit = serviceLocator<NewsletterListCubit>()..loadInitial();
    searchController.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchController.removeListener(applyFilters);
    searchController.dispose();
    _newsletterListCubit.close();
    super.dispose();
  }

  Future<void> onRefresh() async {
    await _newsletterListCubit.refresh();
  }

  void _syncFromState(NewsletterListState state) {
    setState(() {
      _allNewsletters = state.newsletters;
      _allRooms = state.newsletters
          .expand((Newsletter n) => n.classroomCodes)
          .map((String c) => c.trim())
          .where((String c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    });
    applyFilters();
  }

  void applyFilters() {
    final String searchText = searchController.text.toLowerCase().trim();
    setState(() {
      _filteredNewsletters = _allNewsletters.where((Newsletter letter) {
        final bool matchesSearch = searchText.isEmpty ||
            letter.title.toLowerCase().contains(searchText);
        final bool matchesClassroom = selectedClassroom == null ||
            selectedClassroom!.isEmpty ||
            letter.classroomCodes.contains(selectedClassroom);
        return matchesSearch && matchesClassroom;
      }).toList();
    });
  }

  Widget _buildSearchBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    icon: SvgPicture.asset(
                      MediaRes.searchIcon,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 40,
                width: 190,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomDropdown(
                  hintText: 'Classroom',
                  items: _allRooms,
                  prependHintAsSelectableItem: true,
                  onSelect: (String? value) {
                    selectedClassroom = value;
                    applyFilters();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewsletterListCubit>.value(
      value: _newsletterListCubit,
      child: BlocConsumer<NewsletterListCubit, NewsletterListState>(
        listener: (BuildContext context, NewsletterListState state) {
          _syncFromState(state);
        },
        builder: (BuildContext context, NewsletterListState state) {
          return CustomRefreshIndicator(
            onRefresh: onRefresh,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: state.isLoading && _allNewsletters.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredNewsletters.isEmpty
                            ? Center(
                                child: Text(
                                  state.errorMessage ?? 'No Sent Newsletters',
                                  style: const TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredNewsletters.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Newsletter letter = _filteredNewsletters[index];
                                  final String sentDate =
                                      DateFormat('MMM dd, yyyy').format(
                                    letter.sentAt ?? letter.createdAt ?? DateTime.now(),
                                  );
                                  final String subtitle =
                                      letter.subtitle.trim().isNotEmpty
                                          ? letter.subtitle
                                          : 'Recipients: ${letter.recipientCount}';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: NewsletterSentListCard(
                                      newsLetter: NewsletterListItemModel(
                                        title: letter.title,
                                        classroom: letter.classroomCodes.isEmpty
                                            ? 'All Classrooms'
                                            : letter.classroomCodes.join(', '),
                                        sentDate: sentDate,
                                        summary: subtitle,
                                      ),
                                      onTap: () {
                                        final String code = letter.code.trim();
                                        if (code.isEmpty) return;
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (BuildContext context) =>
                                                PreviewNewsletterScreen(
                                              newsletterCode: code,
                                              initialNewsletter: letter,
                                            ),
                                          ),
                                        );
                                      },
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
}
