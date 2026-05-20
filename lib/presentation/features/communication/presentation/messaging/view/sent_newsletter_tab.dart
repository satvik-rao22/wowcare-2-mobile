import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/cubit/newsletter_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/preview_newsletter_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/send_newslatter_list.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class SentNewsLetterTab extends StatefulWidget {
  const SentNewsLetterTab({super.key});

  @override
  State<SentNewsLetterTab> createState() => _SentNewsLetterTabState();
}

class _SentNewsLetterTabState extends State<SentNewsLetterTab> {
  final TextEditingController searchController = TextEditingController();
  late final NewsletterListCubit _newsletterListCubit;
  late final ClassroomCubit _classroomCubit;
  String? selectedClassroomName;
  List<Newsletter> _allNewsletters = <Newsletter>[];
  List<Newsletter> _filteredNewsletters = <Newsletter>[];

  @override
  void initState() {
    super.initState();
    _newsletterListCubit = serviceLocator<NewsletterListCubit>()..loadInitial();
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(
        force: true,
        applyAttendanceStaffScope: true,
      );
    searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    _newsletterListCubit.close();
    _classroomCubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait<void>([
      _newsletterListCubit.refresh(),
      _classroomCubit.loadActiveClassrooms(
        force: true,
        applyAttendanceStaffScope: true,
      ),
    ]);
  }

  void _syncFromState(NewsletterListState state) {
    setState(() {
      _allNewsletters = state.newsletters;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final String searchText = searchController.text.toLowerCase().trim();
    final String? selectedCode = _selectedClassroomCode();

    setState(() {
      _filteredNewsletters = _allNewsletters.where((Newsletter letter) {
        final bool matchesSearch = searchText.isEmpty ||
            letter.title.toLowerCase().contains(searchText);
        final bool matchesClassroom = selectedCode == null ||
            selectedCode.isEmpty ||
            letter.classroomCodes
                .map((String c) => c.trim())
                .contains(selectedCode);
        return matchesSearch && matchesClassroom;
      }).toList();
    });
  }

  String? _selectedClassroomCode() {
    final String? name = selectedClassroomName;
    if (name == null || name.isEmpty) return null;
    final ClassroomState s = _classroomCubit.state;
    for (final c in s.classrooms) {
      if (c.name.trim() == name.trim()) return c.code.trim();
    }
    return null;
  }

  Map<String, String> _classroomNameByCode(ClassroomState s) {
    return <String, String>{
      for (final c in s.classrooms) c.code.trim(): c.name.trim(),
    };
  }

  List<String> _classroomNameOptions(ClassroomState s) {
    final List<String> names = s.classrooms
        .map((c) => c.name.trim())
        .where((String n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  String _classroomDisplayForLetter(
    Newsletter letter,
    Map<String, String> nameByCode,
  ) {
    if (letter.classroomCodes.isEmpty) return 'All Classrooms';
    final List<String> labels = letter.classroomCodes
        .map((String c) => c.trim())
        .where((String c) => c.isNotEmpty)
        .map((String c) => nameByCode[c] ?? c)
        .toList();
    return labels.isEmpty ? 'All Classrooms' : labels.join(', ');
  }

  Widget _buildSearchAndFilterBox(ClassroomState classroomState) {
    final List<String> roomNames = _classroomNameOptions(classroomState);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomSearchBar(
              controller: searchController,
              hintText: 'Search',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomDropdown(
              hintText: 'Classroom',
              items: roomNames,
              prependHintAsSelectableItem: true,
              fieldHeight: 44,
              onSelect: (String? value) {
                selectedClassroomName = value;
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NewsletterListCubit>.value(value: _newsletterListCubit),
        BlocProvider<ClassroomCubit>.value(value: _classroomCubit),
      ],
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (BuildContext context, ClassroomState classroomState) {
          final Map<String, String> nameByCode =
              _classroomNameByCode(classroomState);
          return BlocConsumer<NewsletterListCubit, NewsletterListState>(
            listener: (BuildContext context, NewsletterListState state) {
              _syncFromState(state);
            },
            builder: (BuildContext context, NewsletterListState state) {
              return CustomRefreshIndicator(
                onRefresh: _onRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      _buildSearchAndFilterBox(classroomState),
                      const SizedBox(height: 12),
                      Expanded(
                        child: state.isLoading && _allNewsletters.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: PrimaryCircularLoader()),
                                ],
                              )
                            : _filteredNewsletters.isEmpty
                                ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight,
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Text(
                                                state.errorMessage ??
                                                    'No Sent Newsletters',
                                                style: const TextStyle(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: _filteredNewsletters.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final Newsletter letter =
                                          _filteredNewsletters[index];
                                      final String sentDate =
                                          DateFormat('MMM dd, yyyy').format(
                                        letter.sentAt ??
                                            letter.createdAt ??
                                            DateTime.now(),
                                      );
                                      final String subtitle =
                                          letter.subtitle.trim().isNotEmpty
                                              ? letter.subtitle
                                              : 'Recipients: ${letter.recipientCount}';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: NewsletterSentListCard(
                                          newsLetter: NewsletterListItemModel(
                                            title: letter.title,
                                            classroom:
                                                _classroomDisplayForLetter(
                                              letter,
                                              nameByCode,
                                            ),
                                            sentDate: sentDate,
                                            summary: subtitle,
                                          ),
                                          onTap: () {
                                            final String code =
                                                letter.code.trim();
                                            if (code.isEmpty) return;
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder:
                                                    (BuildContext context) =>
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
          );
        },
      ),
    );
  }
}
