import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';


class StudentPhysicianTabCard extends StatefulWidget {
  const StudentPhysicianTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentPhysicianTabCard> createState() =>
      _StudentPhysicianTabCardState();
}

class _StudentPhysicianTabCardState extends State<StudentPhysicianTabCard> {

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
          _PhysicianCard(name: "Dr. Sanjay Verma", address: 'Nashua,New Hampshire', email: "doctor00@mail.com",),
          SizedBox(height: 20,),
          _PhysicianCard(name: "Dr. Marry Dsouza", address: 'Nashua,New Hampshire', email: "doctor01@mail.com",)
        ],
      ),

    );
  }

}

class _PhysicianCard extends StatelessWidget{
  const _PhysicianCard({required this.name, required this.address, this.email});
  final String name;
  final String? address;
  final String? email;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff573353),
                        height: 19 / 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "(986) 027-1627",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff573353),
                      height: 19 / 14,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFE9ECEF),
            ),
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
                        'Email ID',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        email!,
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
                        'Address',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        address!,
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
















