import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/common/app/providers/profile_photo_provider.dart';
// import 'package:wowcare/core/common/widgets/custom_button_layout.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
// import 'package:wowcare/core/util/core_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogOutModelBottomSheet extends StatefulWidget {
  const LogOutModelBottomSheet({
    Key? key,
  }) : super(key: key);

  @override
  State<LogOutModelBottomSheet> createState() => _LogOutModelBottomSheetState();
}

class _LogOutModelBottomSheetState extends State<LogOutModelBottomSheet> {
  bool _isLogout = false;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLogout = true;
    });
    prefs.remove('accessToken');
    try {
      // TODO: Re-enable when ProfilePhotoProvider is available
      // context.read<ProfilePhotoProvider>().clearPhoto();

      Navigator.pushNamedAndRemoveUntil(
        context,
        ('/sign-in'),
        ModalRoute.withName('/first-screen'),
      );

      // TODO: Re-enable when CoreUtils is available
      // CoreUtils.showTopSnackBar(
      //   context: context,
      //   isError: false,
      //   isWarning: false,
      //   isSuccess: true,
      //   isAdjust: false,
      //   message: 'You are logged out successfully',
      // );
      
      // Temporary snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are logged out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // TODO: Re-enable when CoreUtils is available
      // CoreUtils.showTopSnackBar(
      //   context: context,
      //   isError: true,
      //   isWarning: false,
      //   isSuccess: false,
      //   isAdjust: false,
      //   message: 'Logout failed. Please try again.',
      // );

      // Temporary snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLogout = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.45,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image/GIF at the top - flexible size
          Flexible(
            child: SizedBox(
              height: 150,
              child: Image.asset(
                MediaRes.logout_image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.themeColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _isLogout
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                )
              : CustomButtonLayout(
                  confirmButtonLabel: 'Yes',
                  cancelButtonLabel: 'No',
                  onPressedConfirm: _logout,
                  onPressedCancel: () => Navigator.pop(context),
                  isForm: false,
                ),
        ],
      ),
    );
  }
}