
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/common/widgets/profile_show_widget.dart';

class ProfileMenuHeader extends StatefulWidget {
  const ProfileMenuHeader({super.key});

  @override
  State<ProfileMenuHeader> createState() => _ProfileMenuHeaderState();
}

class _ProfileMenuHeaderState extends State<ProfileMenuHeader> {

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selected profile image')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: DocumentImageWidget(
            fileUuid: 'Anna Smith',
            name: 'Anna Smith',
            size: 70,
            fontSize: 24,
            statusColor: const Color(0xFF00B115),
          ),
        ),
        const SizedBox(width: 8,),
        Expanded(
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anna Smith',
                style: TextStyle(
                  color: Color(0xFF573353),
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 5),
              Text(
                'Admin',
                style: TextStyle(
                  color: Color(0xFF573353),
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}