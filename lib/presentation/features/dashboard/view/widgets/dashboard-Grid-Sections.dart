import 'package:flutter/material.dart';

class DashboardGridSection extends StatelessWidget {
  const DashboardGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.035,
        vertical: width * 0.03,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Welcome Text
          Text(
            'Welcome {User Name}',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: width < 500 ? 18 : 20,

              color: const Color(0xff5A315B),
              height: 1,
            ),
          ),

          SizedBox(height: width * 0.04),

          /// Heading
          Text(
            'Need your attention',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: width < 500 ? 16 : 18,

              color: const Color(0xff5A315B),
              height: 1,
            ),
          ),

          SizedBox(height: width * 0.05),

          /// GRID
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dashboardItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,

              /// spacing exactly like design
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,

              /// FIXED DESIGN HEIGHT LOOK
              ///
              /// 144 x 77
              /// aspect ratio = 144 / 77 = 1.87
              ///
              /// this keeps same card height on all devices
              childAspectRatio: 1.87,
            ),
            itemBuilder: (context, index) {
              return DashboardGridCard(item: dashboardItems[index]);
            },
          ),

          SizedBox(height: width * 0.04),

          /// Show More
          Row(
            children: [
              Text(
                'Show More',
                style: TextStyle(
                  fontSize: width < 500 ? 20 : 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(width: width * 0.015),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: width < 500 ? 30 : 36,
                color: const Color(0xff5972F3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardGridCard extends StatelessWidget {
  final DashboardItem item;

  const DashboardGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffD9D9D9), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP SECTION
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT NUMBER / ICON
                  Text(
                    item.leadingText,
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.18,
                      fontWeight: FontWeight.w700,
                      color: item.leadingColor,
                      height: 1,
                    ),
                  ),

                  SizedBox(width: constraints.maxWidth * 0.04),

                  /// TITLE
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: constraints.maxWidth * 0.10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff6C6C78),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              /// BOTTOM BADGE / VALUE
              item.isAmount
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.badgeText,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: constraints.maxWidth * 0.16,
                            fontWeight: FontWeight.w700,
                            color: item.badgeColor,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.06,
                          vertical: constraints.maxHeight * 0.06,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.badgeText,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.085,
                              fontWeight: FontWeight.w500,
                              color: item.badgeColor,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class DashboardItem {
  final String title;
  final String leadingText;
  final String badgeText;

  final Color leadingColor;
  final Color badgeColor;
  final Color badgeBackground;

  final bool isAmount;

  DashboardItem({
    required this.title,
    required this.leadingText,
    required this.badgeText,
    required this.leadingColor,
    required this.badgeColor,
    required this.badgeBackground,
    this.isAmount = false,
  });
}

final List<DashboardItem> dashboardItems = [
  DashboardItem(
    title: 'Classrooms',
    leadingText: '3',
    badgeText: 'Not in Ratio',
    leadingColor: const Color(0xff4B61D1),
    badgeColor: Colors.red,
    badgeBackground: const Color(0xffF9EAEA),
  ),

  DashboardItem(
    title: 'Classroom Shifts',
    leadingText: '2',
    badgeText: 'Need Attention',
    leadingColor: const Color(0xff4B61D1),
    badgeColor: Colors.red,
    badgeBackground: const Color(0xffF9EAEA),
  ),

  DashboardItem(
    title: 'Incidents',
    leadingText: '3',
    badgeText: 'Pending Approval',
    leadingColor: const Color(0xffF28C28),
    badgeColor: const Color(0xffF28C28),
    badgeBackground: const Color(0xffFBF4E8),
  ),

  DashboardItem(
    title: 'Total Outstanding',
    leadingText: '\$',
    badgeText: '\$5000 (5%)',
    leadingColor: Colors.red,
    badgeColor: const Color(0xff5972F3),
    badgeBackground: const Color(0xffF9EAEA),
    isAmount: true,
  ),
];
