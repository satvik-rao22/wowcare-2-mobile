import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';


class StudentAboutTabCard extends StatefulWidget {
  const StudentAboutTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;

  @override
  State<StudentAboutTabCard> createState() =>
      _StudentAboutTabCardState();
}

class _StudentAboutTabCardState extends State<StudentAboutTabCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Field(label: 'Name', value: widget.name),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.buildPrimaryGradient(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Status',
              value: null,
              trailing: _buildStatusChip('A'),
            ),
            const SizedBox(height: 16),
            _Field(label: 'Classroom', value: widget.classroom),
            const SizedBox(height: 16),
            _Field(label: 'Tags', value:null, trailing: _tags(tags: widget.tags,),),
            const SizedBox(height: 16),
            _Field(
              label: 'Birth Date',
              value: 'Oct 29, 2001'),
            const SizedBox(height: 16),
            _Field(label: 'Notes', value: "- -"),
            const SizedBox(height: 16),
            _Field(
              label: 'Address',
              value: ('12, East Dunstable road, Nashua, NH, USA,\n03062'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final label = status == 'A'
        ? 'Active'
        : status == 'I'
        ? 'Inactive'
        : status == 'Upcoming'
        ? 'Upcoming'
        : 'Active';
    final labelColor = status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 1)
        : status == 'Upcoming'
        ? const Color.fromARGB(255, 238, 223, 8)
        : const Color.fromRGBO(250, 65, 65, 1);
    final bgColor = status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 0.1)
        : status == 'Upcoming'
        ? const Color.fromARGB(255, 242, 238, 176)
        : const Color.fromRGBO(250, 65, 65, 0.1);
    final icon = status == 'A'
        ? SvgPicture.asset(MediaRes.checkMarkIcon, height: 18)
        : null;

    return _Chip(label: label, labelColor: labelColor, color: bgColor, icon: icon);
  }



}



class _Field extends StatelessWidget {
  const _Field({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        if (trailing == null)
          Text(
            value ?? '- -',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: Color(0xff573353),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          trailing!,
      ],
    );
  }
}

class _tags extends StatelessWidget{
  const _tags({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context){
    final tagList = tags.isEmpty ?  ['5 days', 'Full day', 'Allergies', 'Medication'] : tags;
    return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (tagList.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x4DB1AFE9),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  tagList[0],
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF4B5B7A),
                  ),
                ),
              ),
            if (tagList.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x66CBF6FF),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  tagList[1],
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF4B5B7A),
                  ),
                ),
              ),
            if (tagList.length > 2)
              Tooltip(
                message: tagList
                    .skip(2)
                    .join(', '),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x66D9FFCB),
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${tagList.length - 2}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1B237E),
                      height: 15 / 12,
                    ),
                  ),
                ),
              ),
            Tooltip(
              message: 'Edit tags',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mode_edit_outline_outlined,
                  color: const Color(0xFFCECECE),
                ),
              ),
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







