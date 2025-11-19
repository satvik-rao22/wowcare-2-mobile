import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';


class StudentFamilyTabCard extends StatefulWidget {
  const StudentFamilyTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentFamilyTabCard> createState() =>
      _StudentFamilyTabCardState();
}

class _StudentFamilyTabCardState extends State<StudentFamilyTabCard> {

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
          _FamilyCard(name: "Parent name", relation: 'Father', email: "father@mai.com",),
          SizedBox(height: 20,),
          _FamilyCard(name: "Parent name", relation: 'Mother', email: "mother@mai.com",)
        ],
      ),

    );
  }

}

class _FamilyCard extends StatelessWidget{
  const _FamilyCard({required this.name, this.relation, this.email});
  final String name;
  final String? relation;
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
          height: 80,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DocumentImageWidget(
                fileUuid: '',
                name: name,
                size: 45,
              ),
              SizedBox(width: isTablet ? 16 : 9),
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
            )
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
                        'Relation',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        relation!,
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
                        'Phone Number',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        "(986) 027-1627",
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
                        'Sign-in Pin',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff573353),
                          height: 16 / 13,
                        ),
                      ),
                      Text(
                        '263630',
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
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF6C7FD8),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  8,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C7FD8),
                                height: 16 / 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient:
                            AppColors.buildPrimaryGradient(),
                          ),
                          child: TextButton(
                            onPressed: () {

                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 16 / 16,
                              ),
                            ),
                          ),
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
















