import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../app/theme/media_res.dart';
import '../../../../../../shared/common/views/filter_screen.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';

class StaffMessagingTab extends StatefulWidget {
  const StaffMessagingTab({super.key, this.isStaffMessaging = true});
  final bool isStaffMessaging;

  static const String routeName = '/staffMessagingTab';

  @override
  State<StaffMessagingTab> createState() => _StaffMessagingTabState();
}

class _StaffMessagingTabState extends State<StaffMessagingTab> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, List<String>> _currentFilters = {};
  bool _showUnread = false;

  final List<Map<String, dynamic>> staffList = [
    {
      'name': 'Natasha White',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 1,
      'classroom': '1-Blue D',
      'designation': 'Lead Teacher',
      'status': 'Active'
    },
    {
      'name': 'Eddie Barnes',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Morning check-in done. All good here.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '2-Red A',
      'designation': 'Lead Teacher',
      'status': 'Active'
    },
    {
      'name': 'Lara Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/68.jpg',
      'dateTime': DateTime(2026, 1, 19, 14, 45),
      'message': 'The activity report is ready for review.',
      'isSigned': false,
      'isFavorite': true,
      'unreadCount': 3,
      'classroom': '1-Blue D',
      'designation': 'Lead Teacher',
      'status': 'Active'
    },
    {
      'name': 'Michael Chen',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'dateTime': DateTime(2026, 1, 18, 16, 15),
      'message': 'Need approval on tomorrow’s schedule.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'dateTime': DateTime(2026, 1, 15, 11, 20),
      'message': 'Parent meeting notes uploaded.',
      'isSigned': false,
      'isFavorite': false,
      'unreadCount': 7,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },{
      'name': 'Natasha White',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 1,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },
    {
      'name': 'Eddie Barnes',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Morning check-in done. All good here.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },
    {
      'name': 'Lara Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/68.jpg',
      'dateTime': DateTime(2026, 1, 19, 14, 45),
      'message': 'The activity report is ready for review.',
      'isSigned': false,
      'isFavorite': true,
      'unreadCount': 3,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },
    {
      'name': 'Michael Chen',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'dateTime': DateTime(2026, 1, 18, 16, 15),
      'message': 'Need approval on tomorrow’s schedule.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'dateTime': DateTime(2026, 1, 15, 11, 20),
      'message': 'Parent meeting notes uploaded.',
      'isSigned': false,
      'isFavorite': false,
      'unreadCount': 7,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming'
    },

  ];
  // final List<Map<String, dynamic>> parentList = [
  //   {
  //     'name': 'Ajay Sundaram',
  //     'avatar': 'https://randomuser.me/api/portraits/boys/45.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': false,
  //     'unreadCount': 1,
  //     'classroom': '2-Green B',
  //     'status': 'Upcoming',
  //     'tags': ['5 Days', 'Full Day', 'Photo Permission', 'Boy'],
  //   },
  //   {
  //     'name': 'Chaitanya Bhave',
  //     'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': false,
  //     'unreadCount': 1,
  //     'classroom': '1-Yellow A',
  //     'status': 'Active',
  //     'tags': ['Full Day', 'Vegetarian', 'Boy'],
  //   },
  //   {
  //     'name': 'Riken Mehta',
  //     'avatar': 'https://randomuser.me/api/portraits/boys/12.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': false,
  //     'unreadCount': 1,
  //     'classroom': '3-Purple C',
  //     'status': 'Active',
  //     'tags': ['5 Days', 'Medication', 'Allergy', 'Boy'],
  //   },
  //   {
  //     'name': 'Thomas Edison',
  //     'avatar': 'https://randomuser.me/api/portraits/boys/88.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': true,
  //     'unreadCount': 0,
  //     'classroom': '4-Blue D',
  //     'status': 'Active',
  //     'tags': ['Half Day', 'Pickup Authorized', 'Boy'],
  //   },
  //   {
  //     'name': 'Olivia Gonsalves',
  //     'avatar': 'https://randomuser.me/api/portraits/girls/23.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': false,
  //     'unreadCount': 0,
  //     'classroom': '2-Red A',
  //     'status': 'Active',
  //     'tags': ['5 Days', 'Full Day', 'Girl', 'First Aid'],
  //   },
  //   {
  //     'name': 'Satya Vani Kanumuri',
  //     'avatar': 'https://randomuser.me/api/portraits/women/51.jpg',
  //     'dateTime': DateTime(2026, 2, 4, 13, 30),
  //     'message': 'Oh, hello! All perfectly.',
  //     'isSigned': true,
  //     'isFavorite': true,
  //     'unreadCount': 0,
  //     'classroom': '1-Blue D',
  //     'status': 'Active',
  //     'tags': ['Full Day', 'Photo Permission', 'Vegetarian', 'Girl'],
  //   },
  // ];
  final List<Map<String, dynamic>> parentList = [
    {
      'name': 'Ajay Sundaram',
      'avatar': 'https://randomuser.me/api/portraits/boys/45.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '2-Green B',
      'status': 'Upcoming',
      'tags': ['5 Days', 'Full Day', 'Photo Permission', 'Boy'],
      'staffList': ['Eddie Barnes', 'John Doe', 'Priya Sharma', 'Mr. Kumar'],
      'parents': ['Nitin Sundaram', 'Radha Sundaram'],
      'privateModeParents': ['Nitin Sundaram', 'Radha Sundaram'],
    },
    {
      'name': 'Chaitanya Bhave',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '1-Yellow A',
      'status': 'Active',
      'tags': ['Full Day', 'Vegetarian', 'Boy'],
      'staffList': ['Eddie Barnes', 'Sarah Lee', 'Mr. Patel'],
      'parents': ['Vikas Bhave', 'Sneha Bhave'],
      'privateModeParents': [],
    },
    {
      'name': 'Riken Mehta',
      'avatar': 'https://randomuser.me/api/portraits/boys/12.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '3-Purple C',
      'status': 'Active',
      'tags': ['5 Days', 'Medication', 'Allergy', 'Boy'],
      'staffList': ['John Doe', 'Priya Sharma', 'Ms. Gupta'],
      'parents': ['Rakesh Mehta', 'Pooja Mehta'],
      'privateModeParents': ['Pooja Mehta'],
    },
    {
      'name': 'Thomas Edison',
      'avatar': 'https://randomuser.me/api/portraits/boys/88.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 0,
      'classroom': '4-Blue D',
      'status': 'Active',
      'tags': ['Half Day', 'Pickup Authorized', 'Boy'],
      'staffList': ['Eddie Barnes', 'Sarah Lee', 'Mr. Kumar'],
      'parents': ['James Edison', 'Mary Edison'],
      'privateModeParents': [],
    },
    {
      'name': 'Olivia Gonsalves',
      'avatar': 'https://randomuser.me/api/portraits/girls/23.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '2-Red A',
      'status': 'Active',
      'tags': ['5 Days', 'Full Day', 'Girl', 'First Aid'],
      'staffList': ['Priya Sharma', 'Ms. Gupta', 'Mr. Patel'],
      'parents': ['Antonio Gonsalves', 'Maria Gonsalves'],
      'privateModeParents': [],
    },
    {
      'name': 'Satya Vani Kanumuri',
      'avatar': 'https://randomuser.me/api/portraits/women/51.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 0,
      'classroom': '1-Blue D',
      'status': 'Active',
      'tags': ['Full Day', 'Photo Permission', 'Vegetarian', 'Girl'],
      'staffList': ['Eddie Barnes', 'John Doe', 'Sarah Lee'],
      'parents': ['Ravi Kanumuri', 'Lakshmi Kanumuri'],
      'privateModeParents': [],
    },
  ];
  late List<Map<String, dynamic>> _filteredList;


  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(messageDate).inDays;

    final timeStr = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    if (difference == 0) {
      return "Today | $timeStr";
    } else if (difference == 1) {
      return "Yesterday | $timeStr";
    } else if (difference < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return "${days[dateTime.weekday - 1]} | $timeStr";
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} | $timeStr";
    }
  }

  void _applyFilters(){
    final query = _searchController.text.trim().toLowerCase();
    final unfilteredList = widget.isStaffMessaging ? staffList: parentList;
    setState(() {
      _filteredList = unfilteredList.where((person) {
        final name = (person['name'] as String).toLowerCase();
        if(query.isNotEmpty && !name.contains(query)){
          return false;
        }
        bool matches = true;

        widget.isStaffMessaging ?
        _currentFilters.forEach((filterKey, selectedValues){
          if(selectedValues.isEmpty) return;
          switch (filterKey){
            case 'Classroom':
              if(!selectedValues.contains(person['classroom'])) matches = false;
              break;
            case 'Status':
              if(!selectedValues.contains(person['status'])) matches = false;
              break;
            case  'Designation':
              if(!selectedValues.contains(person['designation'])) matches = false;
              break;
            case 'Unread':
              final showUnreadOnly = selectedValues.contains('true');
              final hasUnread = (person['unreadCount'] as num? ?? 0) > 0;
              if (showUnreadOnly && !hasUnread){
                matches = false;
              }
              break;
          }
        }) :
        _currentFilters.forEach((filterKey, selectedValues){
          if(selectedValues.isEmpty) return;
          switch (filterKey){
            case 'Classroom':
              if(!selectedValues.contains(person['classroom'])) matches = false;
              break;
            case 'Status':
              if(!selectedValues.contains(person['status'])) matches = false;
              break;
            case  'Tags':
              if(!selectedValues.every((selectedTag) => person['tags'].contains(selectedTag))) matches = false;
              break;
            case 'Unread':
              final showUnreadOnly = selectedValues.contains('true');
              final hasUnread = (person['unreadCount'] as num? ?? 0) > 0;
              if (showUnreadOnly && !hasUnread){
                matches = false;
              }
              break;
          }
        })
        ;
        return matches;
      }).toList();
    });

  }

  void _clearAllFilters(){
    setState(() {
      _currentFilters.clear();
      _showUnread = false;
      _currentFilters['Unread'] = [];
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  void initState(){
    super.initState();
    _applyFilters();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose(){
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: const SizedBox(height: 15,),),
        // search bar and filter icon as well as clear all button and unread messages toggle
        SliverToBoxAdapter(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0x33B1AFE9),
                      ),
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: widget.isStaffMessaging ? 'Search Staff' : 'Search student',
                        searchBarColor: WidgetStatePropertyAll(Colors.transparent),
                        borderColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => widget.isStaffMessaging ? FilterScreen(
                                sections: [
                                  FilerSection(
                                      label: 'Classroom',
                                      hintText: 'Select classroom',
                                      items: ['1-Blue D', '3-Orange-D', '2-Red A'],
                                      initialSelected: _currentFilters['Classroom'] ?? [],
                                      isMultiSelectDropDown: true
                                  ),
                                  FilerSection(
                                    label: 'Status',
                                    hintText: 'Select status',
                                    items: ['Active', 'Upcoming'],
                                    initialSelected: _currentFilters['Status'] ?? [],
                                    isSingleSelect: true
                                  ),
                                  FilerSection(
                                      label: 'Designation',
                                      hintText: 'Select designation',
                                      items:  [
                                        'Kiosk',
                                        'Director',
                                        'Assistant Director',
                                        'Admin',
                                        'Lead Teacher',
                                        'Associate Teacher',
                                        'Assistant Teacher',
                                        'Owner',
                                        'Floater'
                                      ],
                                      isMultiSelectDropDown: true,
                                      initialSelected: _currentFilters['Designation'] ?? []
                                  ),

                                ],
                                onApply: (filters) {
                                  setState(() {
                                    _currentFilters = filters;
                                  });
                                  _applyFilters();

                                }
                            ) : FilterScreen(
                                sections: [
                                  FilerSection(
                                      label: 'Classroom',
                                      hintText: 'Select classroom',
                                      items: ['1-Blue D', '3-Orange-D', '2-Red A'],
                                      initialSelected: _currentFilters['Classroom'] ?? [],
                                      isMultiSelectDropDown: true
                                  ),
                                  FilerSection(
                                      label: 'Status',
                                      hintText: 'Select status',
                                      items: ['Active', 'Upcoming'],
                                      initialSelected: _currentFilters['Status'] ?? [],
                                      isSingleSelect: true
                                  ),
                                  FilerSection(
                                    label: 'Tags',
                                    hintText: 'Select tags',
                                    items: [
                                      '5 Days',
                                      'Full Day',
                                      'Photo Permission',
                                      'Vegetarian',
                                      'First Aid',
                                      'Allergy',
                                      'Pickup Authorized',
                                      'Medication',
                                      'Half Day',
                                      'Boy',
                                      'Girl',
                                    ],
                                    initialSelected: _currentFilters['Tags'] ?? [],
                                    isMultiSelectDropDown: false,
                                  ),

                                ],
                                onApply: (filters) {
                                  setState(() {
                                    _currentFilters = filters;
                                  });
                                  _applyFilters();

                                }
                            ),
                          ),
                        );
                        if (!mounted) return;
                        if (result is Map) {
                          // TODO: apply filters to list
                          setState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: CustomToggle(
                      label: 'Show Only Unread',
                      isToggled: _showUnread,
                      onToggle: (v) {
                        setState(() {
                          _showUnread = v;
                          _currentFilters['Unread'] = v ? ['true'] : [];
                        });
                        _applyFilters();
                      }
                      //onToggle: (v) => setState(() => _showUnread = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: CustomClearAllChip(onTap: () { _clearAllFilters(); },),
                  ),

              ],)
            ],
          ),
        ),
        // SliverToBoxAdapter(
        //     child: Column(
        //       children: [
        //         Row(
        //           children: [
        //             Expanded(
        //                 child: CustomSearchBar(
        //                     controller: _searchController, hintText: 'Search Staff',
        //                     searchBarColor: WidgetStatePropertyAll(Color(0xB1AFE933)),
        //                     borderColor: Colors.transparent,
        //                 )
        //             ),
        //           ],
        //         )
        //       ],
        //     )
        // ),

        SliverToBoxAdapter(child: const SizedBox(height: 15)),

        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              //final person = widget.isStaffMessaging ? staffList[index] : parentList[index];
              final person = _filteredList[index];
              return InkWell(
                onTap: (){
                  widget.isStaffMessaging ?
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaffMessagingThread(staffInfo: person))) :
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ParentMessagingThread(parentInfo: person)));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        DocumentImageWidget(
                          fileUuid: person['avatar'],
                          name: person['name'],
                          size: 45,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:  person['isSigned']
                                  ? const Color.fromRGBO(0, 177, 21, 1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: person['isSigned'] ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),

                          ),
                        ),

                      ],
                    ),
                    title: CustomTextWidget(
                      text: person['name'],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    subtitle: Text(
                      person['message'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0x8041414E)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Color(0x8041414E),
                            ),
                            const SizedBox(width: 4,),
                            Text(
                              person['dateTime'] != null
                                  ? _formatMessageTime(person['dateTime'] as DateTime)
                                  : '—',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0x8041414E)
                                //color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (person['unreadCount'] != null && person['unreadCount'] > 0)
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              person['unreadCount'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              );
            },
            //childCount: widget.isStaffMessaging ? staffList.length : parentList.length,
            childCount: _filteredList.length,
          ),
        ),
      ],
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //
  //
  //   return Column(
  //     children: [
  //       Container(
  //         height: 200,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //         ),
  //       ),
  //       const SizedBox(height: 10,),
  //       Expanded(
  //         child: ListView.builder(
  //           itemCount: staffList.length,
  //           itemBuilder: (context, index) {
  //             final staff = staffList[index];
  //
  //             return Container(
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(8),
  //                 color: Colors.white,
  //                 border: Border(
  //                   bottom: BorderSide(
  //                     color: const Color(0xFFE9ECEF),
  //                     width: 1
  //                   )
  //                 )
  //               ),
  //               child: ListTile(
  //                 contentPadding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 8,
  //                 ),
  //                 leading: Stack(
  //                   children: [
  //                     DocumentImageWidget(
  //                       fileUuid: staff['avatar'],
  //                       name: staff['name'],
  //                       size: 45,
  //                     ),
  //                     Positioned(
  //                       right: 0,
  //                       top: 0,
  //                       child: Container(
  //                         width: 12,
  //                         height: 12,
  //                         decoration: BoxDecoration(
  //                           color:  staff['isSigned']
  //                               ? const Color.fromRGBO(0, 177, 21, 1)
  //                               : Colors.transparent,
  //                           shape: BoxShape.circle,
  //                           border: Border.all(
  //                             color: staff['isSigned'] ? Colors.white : Colors.transparent,
  //                             width: 2,
  //                           ),
  //                         ),
  //
  //                       ),
  //                     ),
  //
  //                   ],
  //                 ),
  //                 // leading: Stack(
  //                 //   children: [
  //                 //     CircleAvatar(
  //                 //       radius: 28,
  //                 //       backgroundImage: NetworkImage(staff['avatar']),
  //                 //     ),
  //                 //     if (staff['isOnline'])
  //                 //       Positioned(
  //                 //         right: 0,
  //                 //         bottom: 0,
  //                 //         child: Container(
  //                 //           width: 14,
  //                 //           height: 14,
  //                 //           decoration: BoxDecoration(
  //                 //             color: Colors.green,
  //                 //             shape: BoxShape.circle,
  //                 //             border: Border.all(color: Colors.white, width: 2.5),
  //                 //           ),
  //                 //         ),
  //                 //       ),
  //                 //   ],
  //                 // ),
  //                 title: CustomTextWidget(
  //                   text: staff['name'],
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 16,
  //                 ),
  //                 subtitle: Text(
  //                   staff['message'],
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                   style: TextStyle(color: Color(0x8041414E)),
  //                 ),
  //                 trailing: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   crossAxisAlignment: CrossAxisAlignment.end,
  //                   children: [
  //                     Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Icon(
  //                           Icons.access_time,
  //                           color: Color(0x8041414E),
  //                         ),
  //                         const SizedBox(width: 4,),
  //                         Text(
  //                           staff['dateTime'] != null
  //                               ? _formatMessageTime(staff['dateTime'] as DateTime)
  //                               : '—',
  //                           style: TextStyle(
  //                             fontSize: 12,
  //                             color: Color(0x8041414E)
  //                             //color: Colors.grey[600],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 4),
  //                     if (staff['unreadCount'] != null && staff['unreadCount'] > 0)
  //                       Container(
  //                         width: 20,
  //                         height: 20,
  //                         alignment: Alignment.center,
  //                         decoration: const BoxDecoration(
  //                           color: Colors.red,
  //                           shape: BoxShape.circle,
  //                         ),
  //                         child: Text(
  //                           staff['unreadCount'].toString(),
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 11,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       )
  //                     // if (staff['isFavorite'])
  //                     //   const Icon(
  //                     //     Icons.star,
  //                     //     color: Colors.amber,
  //                     //     size: 20,
  //                     //   ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
