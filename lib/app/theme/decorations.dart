import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class ContainerDecorations {
  const ContainerDecorations._(); // Private constructor to prevent instantiation

  static BoxDecoration decoration0 = BoxDecoration(
    borderRadius: BorderRadius.circular(200),
    color: AppColors.transparent, // Solid background color
    border: Border.all(color: AppColors.black),
  );

  static const BoxDecoration decoration1 = BoxDecoration(
    color: AppColors.greenAccentColor, // Solid background color
    borderRadius: BorderRadius.all(
      Radius.circular(16.0),
    ), // More rounded corners
    boxShadow: [
      BoxShadow(
        color: AppColors.grey, // Gray shadow
        blurRadius: 8.0, // Stronger blur
        offset: Offset(2, 4), // Bigger offset
      ),
    ],
  );

  static BoxDecoration decoration2 = BoxDecoration(
    gradient: const LinearGradient(
      colors: [AppColors.orangeColor, AppColors.deepOrangeColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ), // Vertical gradient
    borderRadius: const BorderRadius.all(
      Radius.circular(20.0),
    ), // More pronounced rounded corners
    border: Border.all(
      color: AppColors.orange, // Border color
      width: 3.0, // Border width
    ),
  );

  static const BoxDecoration decoration3 = BoxDecoration(
    shape: BoxShape.circle, // Circular shape
    gradient: RadialGradient(
      colors: [AppColors.purple, AppColors.deepPurpleAccentColor],
      center: Alignment.center,
      radius: 0.8,
    ), // Radial gradient
    boxShadow: [
      BoxShadow(
        color: AppColors.black45Color, // Darker shadow
        blurRadius: 10.0, // Strong blur for inner shadow effect
        offset: Offset(0, 0), // Centered shadow
      ),
    ],
  );

  static BoxDecoration decoration4 = BoxDecoration(
    color: AppColors.white, // Plain background
    border: Border.all(
      width: 4.0,
      color: AppColors.blue, // Border color
    ),
    gradient: const LinearGradient(
      colors: [AppColors.teal, AppColors.cyanAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Diagonal gradient background
    borderRadius: const BorderRadius.all(Radius.circular(10.0)), // Less rounded
  );

  static const BoxDecoration decoration5 = BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.yellow, AppColors.redAccent, AppColors.pinkAccent],
      stops: [0.3, 0.6, 1.0], // Striped effect using multiple colors
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(18.0)),
    boxShadow: [
      BoxShadow(
        color: AppColors.black12, // Light shadow
        blurRadius: 4.0,
        offset: Offset(1, 3),
      ),
    ],
  );

  static const BoxDecoration decoration6 = BoxDecoration(
    color: AppColors.transparent, // No background color
    gradient: LinearGradient(
      colors: [AppColors.pinkAccent, AppColors.amber],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ), // Vertical gradient
    border: Border.fromBorderSide(
      BorderSide(
        color: AppColors.grey,
        width: 2.0,
        style: BorderStyle
            .solid, // Dashed not directly supported, create using dashed path painting
      ),
    ),
    borderRadius: BorderRadius.all(Radius.circular(25.0)),
  );

  static InputDecoration dropdownDecoration = InputDecoration(
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: AppColors.black, // Default border color
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: AppColors.blue, // Border color when focused
        width: 2.0,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: AppColors.red, // Border color when there is an error
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: AppColors.red, // Focused error border color
        width: 2.0,
      ),
    ),
  );
}

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;

  const GradientBorderContainer({
    Key? key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}
