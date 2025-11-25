import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

import '../../../../../shared/common/widgets/custom_toggle.dart';


class StudentDocumentsTab extends StatefulWidget {
  const StudentDocumentsTab({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentDocumentsTab> createState() =>
      _StudentDocumentsTabState();
}

class _StudentDocumentsTabState extends State<StudentDocumentsTab> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10,),
        CustomSectionCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomToggle(
                key: ValueKey(false),
                label: '',
                isToggled: false,
                onToggle: (v) => setState(() {
                  // _searchController.clear();
                  // _isToggled = v;
                }),
              ),
              SizedBox(width: 10),
              Expanded(
                child: const Text(
                  "Show Expired Documents",
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                    height: 19 / 14,
                  ),
                ),
              ),

            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _DocumentCard(documentName: "Project_Proposal_ABC_Corp_2025", documentType: 'Registration Forms', expiryDate: 'Nov 29 ,2025'),
                SizedBox(height: 20,),
                _DocumentCard(documentName: "Annual_Report_2025_Financial_Performance", documentType: 'Registration Forms', expiryDate: 'Nov 29 ,2025'),
                SizedBox(height: 20,),
                _DocumentCard(documentName: "Machine_Learning_Paper_Results_2025", documentType: 'Registration Forms', expiryDate: 'Nov 29 ,2025'),
              ],
            ),

          ),
        ),
      ],
    );
  }

}

class _DocumentCard extends StatefulWidget {
  const _DocumentCard({required this.documentName, required this.documentType, required this.expiryDate});
  final String documentName;
  final String documentType;
  final String expiryDate;

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
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
                  topRight: const Radius.circular(8),
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
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.documentName,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff573353),
                                height: 19 / 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Document Type',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                    letterSpacing: -0.03 * 12,
                                  ),
                                ),
                                Text(
                                  widget.documentType,
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
                                  'Expiry Date',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                    letterSpacing: -0.03 * 12,
                                  ),
                                ),
                                Text(
                                  widget.expiryDate,
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
                                  'Document',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                    letterSpacing: -0.03 * 12,
                                  ),
                                ),
                                IconButton(
                                    onPressed: (){},
                                    iconSize: 24,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(maxWidth: 24, maxHeight: 24),
                                    icon: Icon(
                                      Icons.photo_outlined,
                                      color: const Color(0xFF6C7FD8),
                                    ),
                                )
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


class CustomSectionCard extends StatelessWidget {
  const CustomSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.backgroundColor,
    this.minHeight,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? AppColors.cardColor,
      ),
      child: child,
    );
  }
}





