import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class CustomAddNoteButton extends StatelessWidget {
  final VoidCallback onTap;

  const CustomAddNoteButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: AppSurfaces.well(radius: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Add Note",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppPalette.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              // decoration: BoxDecoration(
              //   color: Colors.white,
              //   shape: BoxShape.circle,
              //   border: Border.all(color: const Color(0xFFD1C4E9)),
              // ),
              child: const Icon(Icons.add, size: 22, color: AppPalette.brand),
            ),
          ],
        ),
      ),
    );
  }
}
