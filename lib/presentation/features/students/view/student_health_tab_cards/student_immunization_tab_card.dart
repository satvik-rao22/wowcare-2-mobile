import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';


class StudentImmunizationTabCard extends StatefulWidget {
  const StudentImmunizationTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentImmunizationTabCard> createState() =>
      _StudentImmunizationTabCardState();
}

class _StudentImmunizationTabCardState extends State<StudentImmunizationTabCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Column(
        children: [

          _ImmunizationCard( vaccineName: 'DTaP', isFirstCard: true,),
          SizedBox(height: 20,),
          _ImmunizationCard(vaccineName: 'Hib', isFirstCard: false,),
          SizedBox(height: 20,),
          _ImmunizationCard(vaccineName: 'Hep A', isFirstCard: false,),
        ],
      ),

    );
  }

}

class _ImmunizationCard extends StatefulWidget {
  const _ImmunizationCard({required this.vaccineName, required this.isFirstCard});
  final bool isFirstCard;
  final String vaccineName;

  @override
  State<_ImmunizationCard> createState() => _ImmunizationCardState();
}

class _ImmunizationCardState extends State<_ImmunizationCard> {
  bool isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              // Match staff card styling: radius 12, 1px border.
              borderRadius: BorderRadius.only(
                topRight: widget.isFirstCard ? const Radius.circular(0) : const Radius.circular(12),
                topLeft: const Radius.circular(12),
                bottomLeft: const Radius.circular(12),
                bottomRight: const Radius.circular(12),
              ),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                      ),
                      alignment: Alignment.center,
                      child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Vaccine',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primaryColor.withOpacity(0.5),
                                  fontSize: 14,
                                  letterSpacing: 14 * (-3 / 100),
                                ),
                              ),
                              Text(
                                widget.vaccineName,
                                style: AppTextStyles.value.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),


                    ),
                    if (isExpanded) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.dividerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _dose(doseNo: 1, status: "Completed", doseDate: "May 18, 2025"),
                            _dose(doseNo: 2, status: "Completed", doseDate: "May 18, 2025"),
                            _dose(doseNo: 3, status: "Completed", doseDate: "May 18, 2025"),
                            _dose(doseNo: 4, doseDate: "-"),
                            _dose(doseNo: 5, doseDate: "-"),
                            const SizedBox(height: 20),

                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _dose extends StatelessWidget{
  const _dose({required this.doseNo,this.status, required this.doseDate});
  final String? status;
  final String doseDate;
  final int doseNo;

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dose ${doseNo}',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primaryColor.withOpacity(0.5),
                fontSize: 14,
                letterSpacing: 14 * (-3 / 100),
              ),
            ),
            Row(
              children: [
                if ( status != null)
                  _Chip(
                    label: status!,
                    labelColor: (status!.toLowerCase() == 'completed') ? const Color(0xFF38C820) : Color(0xFFEABA00),
                    color: (status!.toLowerCase() == 'completed') ? const Color(0x1A38C820) : Color(0x1AEABA00),
                  ),
                SizedBox(width: 10,),
                Text(
                  doseDate,
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

  }

}


class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color, this.icon});
  final String label;
  final Color labelColor;
  final Color color;
  final Widget? icon;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.value.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}






