import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';



class StudentHealthTabCard extends StatefulWidget {
  const StudentHealthTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentHealthTabCard> createState() =>
      _StudentHealthTabCardState();
}

class _StudentHealthTabCardState extends State<StudentHealthTabCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,

        child:
          _HealthCard(allergies: "No allergies", medication: 'No medication', dietRestrictions: "Can not eat candy"),



    );
  }

}

class _HealthCard extends StatelessWidget{
  const _HealthCard({required this.allergies, required this.medication, required this.dietRestrictions});
  final String allergies;
  final String? medication;
  final String? dietRestrictions;

  @override
  Widget build(BuildContext context) {

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight:  const Radius.circular(8),
              bottomLeft: const Radius.circular(8),
              bottomRight: const Radius.circular(8)
          ),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Allergies',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        allergies,
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Medication',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        medication!,
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Diet Restrictions',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        dietRestrictions!,
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
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ],

        ),
      ),
    );

  }

}
















