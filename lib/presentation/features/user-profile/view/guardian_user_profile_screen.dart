import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/presentation/features/auth/view/role_selection_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class GuardianUserProfileScreen extends StatefulWidget {
  const GuardianUserProfileScreen({super.key});

  @override
  State<GuardianUserProfileScreen> createState() =>
      _GuardianUserProfileScreenState();
}

class _GuardianUserProfileScreenState extends State<GuardianUserProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _showSwitchProfile = false;

  String _fullName = '';
  String _email = '';
  String _phoneRaw = '';
  String _relation = '';
  String _photoUuid = '';

  File? _previewFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSwitchProfileFlag();
      _loadGuardianFromChildrenApi();
    });
  }

  Future<void> _loadSwitchProfileFlag() async {
    try {
      final storage = serviceLocator<StorageService>();
      final rolesJson = await storage.getString(StorageKeys.roles);
      if (rolesJson == null || rolesJson.trim().isEmpty) return;
      final decoded = jsonDecode(rolesJson);
      if (decoded is! List<dynamic>) return;

      var hasGuardian = false;
      var hasOther = false;
      for (final r in decoded) {
        if (r is! Map) continue;
        final role = (r['role'] ?? '').toString();
        if (roleStringIsGuardianPersona(role)) {
          hasGuardian = true;
        } else if (role.trim().isNotEmpty) {
          hasOther = true;
        }
      }

      if (!mounted) return;
      setState(() {
        _showSwitchProfile =
            decoded.length > 1 || (hasGuardian && hasOther);
      });
    } catch (_) {
      // Keep default false.
    }
  }

  Future<void> _loadGuardianFromChildrenApi() async {
    setState(() => _loading = true);

    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '').trim();
    final schoolCode =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final displayName =
        (await storage.getString(StorageKeys.displayName) ?? '').trim();
    final loginEmail = (await storage.getString(StorageKeys.email) ?? '').trim();

    try {
      final guardianCode = (await resolveGuardianCodeForLoggedInUser()).trim();
      if (guardianCode.isEmpty ||
          schoolCode.isEmpty ||
          userCode.isEmpty) {
        if (!mounted) return;
        setState(() {
          _fullName = displayName;
          _email = loginEmail;
          _phoneRaw = '';
          _relation = '';
          _photoUuid = '';
          _loading = false;
        });
        return;
      }

      final remote = serviceLocator<StudentRemoteDataSource>();
      final rows = await remote.getGuardianChildren(
        guardianCode: guardianCode,
        schoolCode: schoolCode,
        userCode: userCode,
      );

      final parsed = _guardianFromChildrenRows(rows);

      if (!mounted) return;
      setState(() {
        _fullName = parsed.fullName.isNotEmpty ? parsed.fullName : displayName;
        _email = parsed.email.isNotEmpty ? parsed.email : loginEmail;
        _phoneRaw = parsed.phone;
        _relation = parsed.relation;
        _photoUuid = parsed.photoUuid;
        _loading = false;
      });
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!mounted) return;
      setState(() {
        _fullName = displayName;
        _email = loginEmail;
        _loading = false;
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not load guardian profile. Pull to refresh.',
        isError: true,
      );
    }
  }

  String _formatPhoneForDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return CoreUtils.formatPhoneNumber(digits);
  }

  Future<void> _viewStudentProfile() async {
    final parentChild = context.read<ParentChildProvider>();
    if (!parentChild.isLoaded && !parentChild.isLoading) {
      await parentChild.ensureLoaded();
    }
    final selected = parentChild.selectedChild;
    if (selected == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'No child selected. Choose a child from the menu first.',
        isError: true,
      );
      return;
    }

    await context.read<RoleProvider>().refreshAccessFromServer(force: true);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StudentProfileScreen(
          name: selected.name,
          classroom: selected.classroom,
          tags: selected.tags,
          schedule: selected.schedule,
          sibling: const <String, dynamic>{
            'name': [],
            'relation': [],
            'status': [],
          },
          studentCode: selected.code,
          syncWithParentChildSelection: true,
        ),
      ),
    );
  }

  void _switchProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const RoleSelectionScreen(),
      ),
    );
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Profile Photo Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue[600], size: 24),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Use camera to take a new photo',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library, color: Colors.green[600], size: 24),
              ),
              title: const Text(
                'Photo Gallery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Choose from your photo gallery',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_photoUuid.isNotEmpty) ...[
              Divider(color: Colors.grey[200], thickness: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_outline, color: Colors.red[600], size: 24),
                ),
                title: Text(
                  'Delete Current Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
                subtitle: const Text(
                  'Remove your current profile photo',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleProfilePhotoDeletion();
                },
              ),
            ],
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProfilePhotoDeletion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile Photo'),
        content: const Text(
          'Are you sure you want to delete your current profile photo? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    CoreUtils.showTopSnackBar(
      context: context,
      message:
          'Removing a guardian profile photo is not supported in the app yet.',
      isWarning: true,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      setState(() => _previewFile = File(picked.path));
      if (!mounted) return;
      _showPhotoPreviewDialog();
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Error selecting image: $e',
        isError: true,
      );
    }
  }

  void _showPhotoPreviewDialog() {
    final file = _previewFile;
    if (file == null) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Preview Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomCancelButton(
                      cancelButtonLabel: 'Cancel',
                      onPressedCancel: () {
                        Navigator.pop(ctx);
                        setState(() => _previewFile = null);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomConfirmButton(
                      label: 'Save',
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _previewFile = null);
                        final name = p.basename(file.path);
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message:
                              'Selected profile image ($name). Upload is not wired yet.',
                          isSuccess: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _fullName.trim().isNotEmpty ? _fullName.trim() : '-';
    final relation = _relation.trim().isNotEmpty ? _relation.trim() : '-';
    final email = _email.trim().isNotEmpty ? _email.trim() : '-';
    final phone = _phoneRaw.trim().isNotEmpty
        ? _formatPhoneForDisplay(_phoneRaw.trim())
        : '-';

    return GlobalScaffold(
      hasBackButton: true,
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await _loadGuardianFromChildrenApi();
          await _loadSwitchProfileFlag();
          if (mounted) {
            await context.read<ParentChildProvider>().ensureLoaded(force: true);
          }
        },
        child: _loading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: _showMediaSourceDialog,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: DocumentImageWidget(
                                          fileUuid: _photoUuid.isNotEmpty
                                              ? _photoUuid
                                              : name,
                                          name: name != '-' ? name : 'Guardian',
                                          size: 90,
                                          shape: BoxShape.circle,
                                          fit: BoxFit.cover,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _showMediaSourceDialog,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4A4A4A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        relation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomConfirmButton(
                                    label: 'View Student Profile',
                                    onPressed: _viewStudentProfile,
                                  ),
                                ),
                                if (_showSwitchProfile) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomCancelButton(
                                      cancelButtonLabel: 'Switch Profile',
                                      onPressedCancel: _switchProfile,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(89, 120, 247, 1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildProfileInfoItem('Name', name),
                          const SizedBox(height: 16),
                          _buildProfileInfoItem('Email', email),
                          const SizedBox(height: 16),
                          _buildProfileInfoItem('Phone Number', phone),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A4A4A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _GuardianProfileFromChildren {
  const _GuardianProfileFromChildren({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.relation,
    required this.photoUuid,
  });

  final String fullName;
  final String email;
  final String phone;
  final String relation;
  final String photoUuid;
}

_GuardianProfileFromChildren _guardianFromChildrenRows(
  List<Map<String, dynamic>> rows,
) {
  if (rows.isEmpty) {
    return const _GuardianProfileFromChildren(
      fullName: '',
      email: '',
      phone: '',
      relation: '',
      photoUuid: '',
    );
  }

  String fullName = '';
  String email = '';
  String phone = '';
  String relation = '';
  String photoUuid = '';

  for (final row in rows) {
    final merged = _mergeNestedGuardian(row);
    if (fullName.isEmpty) {
      fullName = _fullNameFromMap(merged);
    }
    if (email.isEmpty) {
      email = _pickString(merged, const [
        'guardianEmail',
        'email',
        'contactEmail',
        'primaryEmail',
      ]);
    }
    if (phone.isEmpty) {
      phone = _pickString(merged, const [
        'guardianPhone',
        'guardianPhoneNumber',
        'phoneNumber',
        'phone',
        'mobilePhone',
        'mobile',
      ]);
    }
    if (relation.isEmpty) {
      relation = _pickString(merged, const [
        'relation',
        'relationship',
        'guardianRelation',
        'relationDescription',
        'relationshipDescription',
      ]);
    }
    if (photoUuid.isEmpty) {
      photoUuid = _pickString(merged, const [
        'photoUuid',
        'profilePhotoUuid',
        'guardianPhotoUuid',
        'photoFileUuid',
        'guardianProfilePhotoUuid',
      ]);
    }
    if (fullName.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        relation.isNotEmpty &&
        photoUuid.isNotEmpty) {
      break;
    }
  }

  return _GuardianProfileFromChildren(
    fullName: fullName,
    email: email,
    phone: phone,
    relation: relation,
    photoUuid: photoUuid,
  );
}

Map<String, dynamic> _mergeNestedGuardian(Map<String, dynamic> row) {
  final out = Map<String, dynamic>.from(row);
  final nested = row['guardian'];
  if (nested is Map<String, dynamic>) {
    out.addAll(nested);
  } else if (nested is Map) {
    out.addAll(Map<String, dynamic>.from(nested));
  }
  return out;
}

String _pickString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return '';
}

String _fullNameFromMap(Map<String, dynamic> m) {
  final direct = _pickString(m, const [
    'guardianFullName',
    'fullName',
    'name',
    'guardianName',
  ]);
  if (direct.isNotEmpty) return direct;

  final gf = _pickString(m, const [
    'guardianFirstName',
    'firstName',
  ]);
  final gl = _pickString(m, const [
    'guardianLastName',
    'lastName',
  ]);
  return '$gf $gl'.trim();
}
