import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';





class ActivityDailyTab extends StatefulWidget {
  const ActivityDailyTab({super.key});

  static const String routeName = '/activityDailyTab';

  @override
  State<ActivityDailyTab> createState() => _ActivityDailyTabState();
}

class _ActivityDailyTabState extends State<ActivityDailyTab> {
  final TextEditingController _searchController = TextEditingController();


  final List<ActivityItem> activities = const [
    ActivityItem(
      time: "05.00 PM",
      name: "Outdoor",
      description: "Outdoor Activity",
      color: Color(0xFFFFE0B2), // orange
      photoUrl: "https://images.unsplash.com/photo-1570545906912-5b2a3f3c2bab?w=400",
      studentList: ['Kabir Mehta', 'Sara Khan']
    ),
    ActivityItem(
      time: "04.30 PM",
      name: "Learning",
      description: "Drawing Activity",
      color: Color(0xFFB3E5FC), // blue
      photoUrl: "https://images.unsplash.com/photo-1587653915930-8d17f0e7ff5d?w=400",
      studentList: ['Raghav Gupta']
    ),
    ActivityItem(
      time: "04.00 PM",
      name: "Nap",
      description: "Nap Time",
      color: Color(0xFFFFCCBC), // pink
      photoUrl: "https://images.unsplash.com/photo-1603394152748-9625e4419c7a?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta']
    ),
    ActivityItem(
      time: "02.22 PM",
      name: "Meal",
      description: "Lunch (Finished)",
      color: Color(0xFFC8E6C9), // green
      photoUrl: "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta', 'Sara Khan', 'Raghav Gupta', 'Kabir Mehta']
    ),
    ActivityItem(
      time: "01.00 PM",
      name: "Meal",
      description: "Drawing Activity",
      color: Color(0xFFD1C4E9), // purple
      photoUrl: "https://images.unsplash.com/photo-1596461404969-9ae8f10bdd83?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta']
    ),
  ];




  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        Padding(
          padding: ResponsiveSizing.contentPadding(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorderColor),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardColor,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Search student by student/parent name',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CustomClearAllChip(
                          onTap: () {},
                          label: 'Active',
                          //isSelected: true, // make it look active
                        ),
                        const SizedBox(width: 8),
                        CustomClearAllChip(onTap: () {}, label: 'All'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: Padding(
            padding: ResponsiveSizing.contentPadding(context),
            child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    Expanded(
                      child: ListView.builder(

                        padding: const EdgeInsets.only(right: 16),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          final students = activity.studentList ?? [];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: activity.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 4,
                                        height: 2,
                                        color: activity.color,
                                      ),

                                    ],
                                  ),
                                  Container(
                                    width: 100,
                                    height: 4,
                                    color: activity.color,
                                  ),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: activity.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 20,),
                                  SizedBox(
                                    height: 20,
                                    child: Text(
                                      activity.time,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 7,),
                                  Container(
                                    width: 4,
                                    height: 180,
                                    color: activity.color,
                                  ),

                                  const SizedBox(width: 16),

                                  // Activity Card
                                  Expanded(
                                    child: Column(
                                      children: [

                                        const SizedBox(height: 15,),
                                        Container(
                                          height: 140,
                                          margin: const EdgeInsets.only(bottom: 24),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: activity.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: activity.color.withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [

                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: SizedBox(
                                                  width: 122,
                                                  height: 76,
                                                  child: Image.network(
                                                    activity.photoUrl,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        color: Colors.transparent,
                                                        child: const Center(
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 122,
                                                        height: 76,
                                                        color: activity.color.withOpacity(0.25),
                                                        child: Center(
                                                          child: Image.asset(
                                                            'assets/icons/activity-nap-icon.png',
                                                            fit: BoxFit.fill,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: activity.color,
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Text(
                                                              activity.name,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          PopupMenuButton<String>(
                                                            icon: const Icon(Icons.more_horiz, size: 20),
                                                            onSelected: null,
                                                            itemBuilder: (context) => [
                                                                 PopupMenuItem<String>(
                                                                  value: 'edit',
                                                                  child: PopupItem(
                                                                    title: 'Edit',
                                                                  ),
                                                                ),
                                                                 PopupMenuItem<String>(
                                                                  value: 'delete',
                                                                  child: PopupItem(
                                                                    title: 'Delete',

                                                                  ),
                                                                ),

                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),

                                                    SizedBox(
                                                      height: 32,
                                                      child: Stack(
                                                        children: [
                                                          for (int i = 0; i < students.length && i < 4; i++)
                                                            Positioned(
                                                              left: i * 20,
                                                              child: DocumentImageWidget(
                                                                fileUuid: '',
                                                                name: students[i],
                                                                size: 28,
                                                                fontSize: 10,
                                                              ),
                                                            ),

                                                          // Extra count tooltip
                                                          if (students.length > 4)
                                                            Positioned(
                                                              left: 4 * 20, // after 4 avatars
                                                              child: Tooltip(
                                                                message: students.skip(4).join(', '),
                                                                child: DocumentImageWidget(
                                                                  fileUuid: '',
                                                                  name: '+${students.length - 4}',
                                                                  size: 28,
                                                                  fontSize: 10,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    Text(
                                                      activity.description,

                                                      style: TextStyle(
                                                          color: AppColors.primaryColor,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
          ),
        ),


      ],
    );
  }

}

class PopupItem extends StatelessWidget {
  final String title;

  const PopupItem({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }
}

class ActivityItem {
  final String time;
  final String name;
  final String description;
  final Color color;
  final String photoUrl;
  final List<String> studentList;

  const ActivityItem({
    required this.time,
    required this.name,
    required this.description,
    required this.color,
    required this.photoUrl,
    required this.studentList
  });
}