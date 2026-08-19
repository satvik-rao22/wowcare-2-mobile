import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/common/app/providers/profile_photo_provider.dart';
// import 'package:wowcare/core/common/widgets/custom_button_layout.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';

class LogOutModelBottomSheet extends StatefulWidget {
  const LogOutModelBottomSheet({Key? key}) : super(key: key);

  @override
  State<LogOutModelBottomSheet> createState() => _LogOutModelBottomSheetState();
}

class _LogOutModelBottomSheetState extends State<LogOutModelBottomSheet> {
  bool _isLogout = false;

  Future<void> _logout() async {
    setState(() {
      _isLogout = true;
    });
    try {
      // TODO: Re-enable when ProfilePhotoProvider is available
      // context.read<ProfilePhotoProvider>().clearPhoto();

      await context.read<AuthCubit>().logoutSession();

      if (context.mounted) {
        context.read<ParentChildCubit>().invalidate();
      }

      context.go(SignInScreen.routeName);

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
    return SkeuBottomSheet(
      maxHeightFactor: .55,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // A recessed disc holding the illustration: the sheet asks a
          // question, so nothing in it is raised except the two keys.
          Center(
            child: SkeuWell(
              width: 148,
              height: 148,
              radius: SkeuRadius.pill,
              gradient: SkeuSurfaces.pinkSoft,
              insets: SkeuElevation.wellLg,
              padding: const EdgeInsets.all(18),
              // SizedBox.expand so the illustration is bounded by the disc —
              // a well hands its child loose constraints, and an Image would
              // otherwise lay itself out at its full pixel size.
              child: SizedBox.expand(
                child: Image.asset(MediaRes.logout_image, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: SkeuText.title(),
          ),
          const SizedBox(height: 24),
          CustomButtonLayout(
            confirmButtonLabel: 'Yes',
            cancelButtonLabel: 'No',
            onPressedConfirm: _logout,
            onPressedCancel: () => Navigator.pop(context),
            isForm: false,
            isLoading: _isLogout,
          ),
        ],
      ),
    );
  }
}
