
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/string_utils.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class ProfileMenuHeader extends StatefulWidget {
  const ProfileMenuHeader({super.key});

  @override
  State<ProfileMenuHeader> createState() => _ProfileMenuHeaderState();
}

class _ProfileMenuHeaderState extends State<ProfileMenuHeader> {

  final ImagePicker _picker = ImagePicker();
  String _displayName = '';
  String _persona = '';

  @override
  void initState() {
    super.initState();
    _loadUserSummary();
  }

  Future<void> _loadUserSummary() async {
    try {
      final storage = serviceLocator<StorageService>();
      final name =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      String persona = '';

      // Prefer staffType from storage (from staff profile API); fallback to roles
      String staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim();
      if (staffType.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(staffType);
      }
      if (persona.isEmpty) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.isNotEmpty) {
          try {
            final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
            if (roles.isNotEmpty) {
              final first = roles.first as Map<String, dynamic>;
              final roleCode = (first['role'] ?? '').toString().toUpperCase();
              persona = StringUtils.staffTypeToDisplayRole(roleCode);
            }
          } catch (_) {}
        }
      }

      if (!mounted) return;
      setState(() {
        _displayName = name.isNotEmpty ? name : '-';
        _persona = persona.isNotEmpty ? persona : '-';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = '-';
        _persona = '-';
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected profile image',
        isSuccess: true,
      );
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: DocumentImageWidget(
            fileUuid: _displayName.isNotEmpty ? _displayName : 'User',
            name: _displayName.isNotEmpty ? _displayName : 'User',
            size: 48,
            fontSize: 18,
            statusColor: const Color(0xFF00B115),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName.isNotEmpty ? _displayName : '-',
                style: const TextStyle(
                  color: Color(0xFF573353),
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _persona.isNotEmpty ? _persona : '-',
                style: const TextStyle(
                  color: Color(0xFF573353),
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}