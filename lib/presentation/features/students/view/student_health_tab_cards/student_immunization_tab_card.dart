import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';


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
            //height: isExpanded ? null : 80.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topRight: widget.isFirstCard ? Radius.circular(0) : Radius.circular(8),
                  topLeft:  const Radius.circular(8),
                  bottomLeft: const Radius.circular(8),
                  bottomRight: const Radius.circular(8)
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
                              const Text(
                                'Vaccine',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff573353),
                                  height: 16 / 13,
                                ),
                              ),
                              Text(
                                widget.vaccineName,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff573353),
                                  height: 19 / 14,
                                ),
                              ),
                            ],
                          ),


                    ),
                    if (isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFE9ECEF),
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
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xff573353),
                height: 16 / 13,
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
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                    height: 19 / 14,
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
            style: TextStyle(
              fontFamily: 'Manrope',
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






