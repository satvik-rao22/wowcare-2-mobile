import 'package:flutter/material.dart';

import 'colors.dart';

class ContainerDecorations {
  const ContainerDecorations._(); // Private constructor to prevent instantiation

  static BoxDecoration decoration0 = BoxDecoration(
    borderRadius: BorderRadius.circular(200),
    color: Colors.transparent, // Solid background color
    border: Border.all(color: Colors.black),
  );

  static const BoxDecoration decoration1 = BoxDecoration(
    color: Colors.greenAccent, // Solid background color
    borderRadius: BorderRadius.all(
      Radius.circular(16.0),
    ), // More rounded corners
    boxShadow: [
      BoxShadow(
        color: Colors.grey, // Gray shadow
        blurRadius: 8.0, // Stronger blur
        offset: Offset(2, 4), // Bigger offset
      ),
    ],
  );

  static BoxDecoration decoration2 = BoxDecoration(
    gradient: const LinearGradient(
      colors: [Colors.orange, Colors.deepOrange],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ), // Vertical gradient
    borderRadius: const BorderRadius.all(
      Radius.circular(20.0),
    ), // More pronounced rounded corners
    border: Border.all(
      color: Colors.orangeAccent, // Border color
      width: 3.0, // Border width
    ),
  );

  static const BoxDecoration decoration3 = BoxDecoration(
    shape: BoxShape.circle, // Circular shape
    gradient: RadialGradient(
      colors: [Colors.purple, Colors.deepPurpleAccent],
      center: Alignment.center,
      radius: 0.8,
    ), // Radial gradient
    boxShadow: [
      BoxShadow(
        color: Colors.black45, // Darker shadow
        blurRadius: 10.0, // Strong blur for inner shadow effect
        offset: Offset(0, 0), // Centered shadow
      ),
    ],
  );

  static BoxDecoration decoration4 = BoxDecoration(
    color: Colors.white, // Plain background
    border: Border.all(
      width: 4.0,
      color: Colors.blue, // Border color
    ),
    gradient: const LinearGradient(
      colors: [Colors.teal, Colors.cyanAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Diagonal gradient background
    borderRadius: const BorderRadius.all(Radius.circular(10.0)), // Less rounded
  );

  static const BoxDecoration decoration5 = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.yellow, Colors.redAccent, Colors.pinkAccent],
      stops: [0.3, 0.6, 1.0], // Striped effect using multiple colors
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(18.0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black12, // Light shadow
        blurRadius: 4.0,
        offset: Offset(1, 3),
      ),
    ],
  );

  static const BoxDecoration decoration6 = BoxDecoration(
    color: Colors.transparent, // No background color
    gradient: LinearGradient(
      colors: [Colors.pinkAccent, Colors.amber],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ), // Vertical gradient
    border: Border.fromBorderSide(
      BorderSide(
        color: Colors.grey,
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
        color: Colors.black, // Default border color
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: Colors.blue, // Border color when focused
        width: 2.0,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: Colors.red, // Border color when there is an error
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: const BorderSide(
        color: Colors.red, // Focused error border color
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}
