import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/src/core/extentions/context_extentions.dart';

import '../../res/colors.dart';
import '../../res/media_res.dart';
import '../../util/core_utils.dart';
import 'custom_button_layout.dart';

class LogOutModelBottomSheet extends StatefulWidget {
  const LogOutModelBottomSheet({Key? key}) : super(key: key);

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
      // context.read<ProfilePhotoProvider>().clearPhoto();

      Navigator.pushNamedAndRemoveUntil(
        context,
        ('/sign-in'),
        ModalRoute.withName('/first-screen'),
      );

      CoreUtils.showTopSnackBar(
        context: context,
        isError: false,
        isWarning: false,
        isSuccess: true,
        isAdjust: false,
        message: 'You are logged out successfully',
      );
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        isError: true,
        isWarning: false,
        isSuccess: false,
        isAdjust: false,
        message: 'Logout failed. Please try again.',
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
          height: context.height * 0.4,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  MediaRes.logout_image,
                  height: bottomSheetHeight * 0.4,
                ),
              ),
              SizedBox(height: bottomSheetHeight * 0.04),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  color: AppColors.primaryColor,
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
                    : CustomButtonLayout(
                        isForm: false,
                        confirmButtonLabel: 'Yes',
                        cancelButtonLabel: 'No',
                        onPressedConfirm: _logout,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
