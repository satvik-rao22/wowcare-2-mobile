import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/string_utils.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/utils/responsive_helper.dart';
import 'edit_user_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    this.userName = 'Anna Smith',
    this.userPersona = 'Admin',
    this.userEmail = 'Annasmith@gmail.com',
    this.userPhoneNo = '(567) 303-2234',
    this.userAddress = '12, Main St. Nashua, NH',
    this.staffCode,
  });
  final String userName;
  final String userPersona;
  final String userEmail;
  final String userPhoneNo;
  final String userAddress;
  /// Optional staffCode for the logged-in staff user. When provided,
  /// this screen will load profile details via GET `/api/v1/staff/{staffCode}/profile`.
  final String? staffCode;

  static const String routeName = '/userProfile';

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  StaffProfile? _profile;
  bool _isLoadingProfile = false;
  String _loginDisplayName = '';
  String _loginEmail = '';
  String _loginPersona = '';

  @override
  void initState() {
    super.initState();
    // Load profile for logged-in user.
    // If staffCode is provided, use it; otherwise resolve staffCode from cached login info.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProfileLoad();
    });
  }

  Future<void> _initProfileLoad() async {
    // Preload login-based user summary (name, email, persona) from storage
    try {
      final storage = serviceLocator<StorageService>();
      _loginDisplayName =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      _loginEmail = (await storage.getString(StorageKeys.email) ?? '').trim();

      final rolesJson =
          await storage.getString(StorageKeys.roles); // JSON array from login
      String persona = '';
      if (rolesJson != null && rolesJson.isNotEmpty) {
        try {
          final List<dynamic> roles =
              (jsonDecode(rolesJson) as List<dynamic>);
          if (roles.isNotEmpty) {
            final first = roles.first as Map<String, dynamic>;
            final roleCode = (first['role'] ?? '').toString();
            persona = StringUtils.staffTypeToDisplayRole(roleCode);
          }
        } catch (_) {}
      }
      _loginPersona = persona;
    } catch (_) {}

    final direct = (widget.staffCode ?? '').trim();
    if (direct.isNotEmpty) {
      await _loadStaffProfile(direct);
      return;
    }

    final resolved = await _resolveLoggedInStaffCode();
    if (!mounted) return;
    if (resolved.isNotEmpty) {
      await _loadStaffProfile(resolved);
    }
  }

  /// Attempts to resolve staffCode for the logged-in user.
  /// Uses `/api/v1/staff/code` with stored `userCode`, `organizationCode` and `schoolCode`
  /// to resolve the staffCode for the currently logged-in user.
  Future<String> _resolveLoggedInStaffCode() async {
    try {
      final storage = serviceLocator<StorageService>();
      final repo = serviceLocator<StaffRepository>();

      // Ensure cached staffCode, if any, belongs to the currently logged-in user.
      final currentUserCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();
      final cachedStaffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          currentUserCode.isNotEmpty &&
          cachedStaffUser == currentUserCode) {
        // Cache is valid for this user.
        return cachedStaffCode;
      } else {
        // Cached value belongs to another user or is invalid – clear it.
        await storage.remove(StorageKeys.staffCode);
        await storage.remove(StorageKeys.staffCodeUser);
      }

      final organizationCode =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (currentUserCode.isEmpty ||
          organizationCode.isEmpty ||
          schoolCode.isEmpty) {
        return '';
      }

      // Ask backend directly for staffCode for this user.
      final resolvedCode = await repo.getStaffCodeForUser(
        userCode: currentUserCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );

      final code = (resolvedCode ?? '').trim();
      if (code.isNotEmpty) {
        await storage.saveString(StorageKeys.staffCode, code);
        await storage.saveString(StorageKeys.staffCodeUser, currentUserCode);
      }

      return code;
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadStaffProfile(String staffCode) async {
    setState(() => _isLoadingProfile = true);
    try {
      final repo = serviceLocator<StaffRepository>();
      final profile = await repo.getStaffProfile(staffCode: staffCode);
      if (!mounted) return;
      // Cache staffType for ProfileMenuHeader (3-dot menu role display)
      if (profile.staffType.isNotEmpty) {
        final storage = serviceLocator<StorageService>();
        await storage.saveString(StorageKeys.staffType, profile.staffType);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final responsive = ResponsiveHelper(context);
    final String displayName =
        _profile?.fullName.isNotEmpty == true
            ? _profile!.fullName
            : (_loginDisplayName.isNotEmpty ? _loginDisplayName : '-');
    final String displayEmail =
        _profile?.email.isNotEmpty == true
            ? _profile!.email
            : (_loginEmail.isNotEmpty ? _loginEmail : '-');
    final String displayPhone =
        _profile?.phoneNumber.isNotEmpty == true ? _profile!.phoneNumber : '-';
    final String displayAddress =
        _profile?.address.formattedAddress.isNotEmpty == true
            ? _profile!.address.formattedAddress
            : '-';
    final String roleDisplay = _profile != null
        ? StringUtils.staffTypeToDisplayRole(_profile!.staffType)
        : _loginPersona;
    final String displayPersona =
        roleDisplay.isNotEmpty ? roleDisplay : '-';

    return GlobalScaffold(
        hasBackButton: true,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Top profile header (name + role) with 4px horizontal gap
              Card(
                margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                color: Colors.white,
                elevation: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 24 : 16,
                              vertical: 10,
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      DocumentImageWidget(
                                        fileUuid: displayName.isNotEmpty ? displayName : 'User',
                                        name: displayName.isNotEmpty ? displayName : 'User',
                                        size: 90,
                                        fontSize: 24,
                                        statusColor: const Color(0xFF00B115),
                                      ),
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              gradient:
                                              AppColors.buildPrimaryGradient(),
                                              borderRadius: BorderRadius.circular(
                                                14,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10,),
                                      CustomTextWidget(
                                        text: displayName,
                                        fontSize: 23,
                                      ),
                                      // Text(
                                      //   widget.userName, // hardcoded for now
                                      //   style: const TextStyle(
                                      //     color: const Color(0xFF573353),
                                      //     fontFamily: 'Manrope',
                                      //     fontSize: 23,
                                      //     fontWeight: FontWeight.w600,
                                      //     letterSpacing: -0.03 * 23,
                                      //   ),
                                      //   maxLines: 2,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
                                      const SizedBox(height: 5),
                                      CustomTextWidget(
                                        text: displayPersona,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      // Text(
                                      //   widget.userPersona,
                                      //   style: const TextStyle(
                                      //     color: const Color(0xFF573353),
                                      //     fontFamily: 'Manrope',
                                      //     fontSize: 15,
                                      //     fontWeight: FontWeight.w400,
                                      //     letterSpacing: -0.03 * 23,
                                      //   ),
                                      //   maxLines: 2,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF6C7FD8),
                                      ),
                                      alignment: Alignment.center,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: CustomTextWidget(
                                      text: 'Switch Profile',
                                      textStyle:  TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6C7FD8),
                                        height: 16 / 16,
                                      ),
                                      maxLines: 1,
                                    ),
                                    // child: const Text(
                                    //   'Switch Profile',
                                    //   style: TextStyle(
                                    //     fontFamily: 'Manrope',
                                    //     fontSize: 16,
                                    //     fontWeight: FontWeight.w700,
                                    //     color: Color(0xFF6C7FD8),
                                    //     height: 16 / 16,
                                    //   ),
                                    //   maxLines: 1,
                                    //   overflow: TextOverflow.ellipsis,
                                    // ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient:
                                    AppColors.buildPrimaryGradient(),
                                  ),
                                  child: TextButton(
                                    onPressed: () {

                                    },
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                      alignment: Alignment.center
                                    ),
                                    child: CustomTextWidget(
                                      text: displayPersona == 'Admin'
                                          ? 'View Admin Profile'
                                          : displayPersona == 'Parent'
                                              ? "View Child's Profile"
                                              : 'View Staff Profile',
                                      textStyle: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 16 / 16,
                                      ),
                                      maxLines: 1,
                                    ),
                                    // child: Text(
                                    //   widget.userPersona == 'Admin' ?'View Admin Profile' :  widget.userPersona == 'Parent' ? "View Child's Profile" : 'View Staff Profile', // or view staff profile depending on persona
                                    //   style: const TextStyle(
                                    //     fontFamily: 'Manrope',
                                    //     fontSize: 16,
                                    //     fontWeight: FontWeight.w700,
                                    //     color: Colors.white,
                                    //     height: 16 / 16,
                                    //   ),
                                    //   maxLines: 1,
                                    //   overflow: TextOverflow.ellipsis,
                                    // ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),


                  ],
                ),
              ),
              //const SizedBox(height: 15,),
              // "My Profile" card with 4px gap from screen edge and gradient border
              Container(
                margin: const EdgeInsets.fromLTRB(4, 20, 4, 20),
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          if (_isLoadingProfile)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6C7FD8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomTextWidget(
                                text: 'My Profile',
                                fontSize: 16,
                              ),
                              // Text(
                              //   'My Profile',
                              //   style: const TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 16,
                              //     color: Color(0xff573353),
                              //     fontWeight: FontWeight.w600,
                              //     letterSpacing: -0.03 * 16,
                              //   ),
                              // ),
                              GestureDetector(
                                onTap: () {
                                  final parts = widget.userName.trim().split(' ');
                                  final initialFirstName = parts.isNotEmpty ? parts.first : '';
                                  final initialLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                                  final initialEmail = widget.userEmail;
                                  final initialPhoneNo = widget.userPhoneNo;
                                  final initialAddress = widget.userAddress;
                                  final role = widget.userPersona;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditUserProfileScreen(
                                        initialFirstName: initialFirstName,
                                        initialLastName: initialLastName,
                                        initialEmail: initialEmail,
                                        initialPhoneNo: initialPhoneNo,
                                        initialAddressLine2: initialAddress,
                                        role: role,
                                        initialStreet: '',
                                        initialCity: '',
                                        initialState: 'New Hampshire',
                                        initialCountry: 'United States',
                                        initialZipCode: '',
                                        signInPin: '5769', // hard coded for now
                                      ),
                                    ),
                                  );
                                },
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomTextWidget(
                                text: 'Name',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 16 / 13,
                              ),
                              // const Text(
                              //   'Name',
                              //   style: TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 13,
                              //     fontWeight: FontWeight.w400,
                              //     color: Color(0xff573353),
                              //     height: 16 / 13,
                              //   ),
                              // ),
                              CustomTextWidget(
                                text: displayName,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 19 / 14,
                              ),
                              // Text(
                              //   widget.userName,
                              //   style: const TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.w500,
                              //     color: Color(0xff573353),
                              //     height: 19 / 14,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomTextWidget(
                                text: 'Email',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 16 / 13,
                              ),
                              // const Text(
                              //   'Email',
                              //   style: TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 13,
                              //     fontWeight: FontWeight.w400,
                              //     color: Color(0xff573353),
                              //     height: 16 / 13,
                              //   ),
                              // ),
                              CustomTextWidget(
                                text: displayEmail,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 19 / 14,
                              ),
                              // Text(
                              //   widget.userEmail,
                              //   style: const TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.w500,
                              //     color: Color(0xff573353),
                              //     height: 19 / 14,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomTextWidget(
                                text: 'Phone Number',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 16 / 13,
                              ),
                              // const Text(
                              //   'Phone Number',
                              //   style: TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 13,
                              //     fontWeight: FontWeight.w400,
                              //     color: Color(0xff573353),
                              //     height: 16 / 13,
                              //   ),
                              // ),
                              CustomTextWidget(
                                text: displayPhone,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 19 / 14,
                              ),
                              // Text(
                              //   widget.userPhoneNo,
                              //   style: const TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.w500,
                              //     color: Color(0xff573353),
                              //     height: 19 / 14,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomTextWidget(
                                text: 'Address',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 16 / 13,
                              ),
                              // const Text(
                              //   'Address',
                              //   style: TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 13,
                              //     fontWeight: FontWeight.w400,
                              //     color: Color(0xff573353),
                              //     height: 16 / 13,
                              //   ),
                              // ),
                              CustomTextWidget(
                                text: displayAddress,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 19 / 14,
                              ),
                              // Text(
                              //   widget.userAddress,
                              //   style: const TextStyle(
                              //     fontFamily: 'Manrope',
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.w500,
                              //     color: Color(0xff573353),
                              //     height: 19 / 14,
                              //   ),
                              //   maxLines: 2,
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                            ],
                          ),
                          SizedBox(height: responsive.verticalSpacing),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
    );
  }
}
