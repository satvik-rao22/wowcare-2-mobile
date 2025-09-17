import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/common/app/providers/profile_photo_provider.dart';
// import 'package:wowcare/core/common/widgets/custom_button_layout.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomSheetHeight = constraints.maxHeight;

        return Container(
          height: MediaQuery.of(context).size.height * 0.4, // context.height * 0.4,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  MediaRes.logoutImage, // MediaRes.logout_image,
                  height: bottomSheetHeight * 0.4,
                ),
              ),
              SizedBox(height: bottomSheetHeight * 0.04),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  color: AppColors.themeColor, // AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: bottomSheetHeight * 0.04),
              Container(
                height: bottomSheetHeight * 0.1,
                alignment: Alignment.center,
                child: _isLogout
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.themeColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    // TODO: Re-enable when CustomButtonLayout is available
                    // : CustomButtonLayout(
                    //     isForm: false,
                    //     confirmButtonLabel: 'Yes',
                    //     cancelButtonLabel: 'No',
                    //     onPressedConfirm: _logout,
                    //   ),
              ),
            ],
          ),
        );
      },
    );
  }
}