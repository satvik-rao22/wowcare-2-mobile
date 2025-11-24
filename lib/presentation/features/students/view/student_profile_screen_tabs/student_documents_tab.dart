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
                _DocumentCard(documentName: "Project_Proposal_ABC_Corp_2025", documentType: 'something', expiryDate: 'something'),
                SizedBox(height: 20,),
                _DocumentCard(documentName: "Project_Proposal_ABC_Corp_2025", documentType: 'something', expiryDate: 'something'),
                SizedBox(height: 20,),
                _DocumentCard(documentName: "Project_Proposal_ABC_Corp_2025", documentType: 'something', expiryDate: 'something'),
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
                          Text(
                            widget.documentName,
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
                            Text("something"),
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





