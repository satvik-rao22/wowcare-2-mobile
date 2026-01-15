import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/utils/responsive_helper.dart';
import 'edit_user_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, this.userName = 'Anna Smith', this.userPersona = 'Admin', this.userEmail = 'Annasmith@gmail.com', this.userPhoneNo = '(567) 303-2234', this.userAddress = '12, Main St. Nashua, NH'});
  final String userName;
  final String userPersona;
  final String userEmail;
  final String userPhoneNo;
  final String userAddress;

  static const String routeName = '/userProfile';

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final responsive = ResponsiveHelper(context);
    return GlobalScaffold(
        hasBackButton: true,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Card(
                margin: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
                                        fileUuid: widget.userName,
                                        name: widget.userName, // hardcoded for now
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
                                      Text(
                                        widget.userName, // hardcoded for now
                                        style: const TextStyle(
                                          color: const Color(0xFF573353),
                                          fontFamily: 'Manrope',
                                          fontSize: 23,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.03 * 23,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        widget.userPersona,
                                        style: const TextStyle(
                                          color: const Color(0xFF573353),
                                          fontFamily: 'Manrope',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.03 * 23,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                    child: const Text(
                                      'Switch Profile',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6C7FD8),
                                        height: 16 / 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                    child: Text(
                                      widget.userPersona == 'Admin' ?'View Admin Profile' :  widget.userPersona == 'Parent' ? "View Child's Profile" : 'View Staff Profile', // or view staff profile depending on persona
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 16 / 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
              Card(
                margin: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                color: Colors.white,
                elevation: 2,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Profile',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  color: Color(0xff573353),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.03 * 16,
                                ),
                              ),
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
                              const Text(
                                'Name',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff573353),
                                  height: 16 / 13,
                                ),
                              ),
                              Text(
                                widget.userName,
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
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff573353),
                                  height: 16 / 13,
                                ),
                              ),
                              Text(
                                widget.userEmail,
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
                          const SizedBox(height: 16),
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
                                widget.userPhoneNo,
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
                          const SizedBox(height: 16),
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
                                widget.userAddress,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff573353),
                                  height: 19 / 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.verticalSpacing),

                        ],
                      ),
                    ),
                  ],

                ),
              )
            ],
          ),
        )
    );
  }
}
