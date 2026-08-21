import 'package:flutter/material.dart';

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
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FA), // light lavender/gray background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE9F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Add Note",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B2E4C),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              // decoration: BoxDecoration(
              //   color: AppColors.white,
              //   shape: BoxShape.circle,
              //   border: Border.all(color: const Color(0xFFD1C4E9)),
              // ),
              child: const Icon(Icons.add, size: 22, color: Color(0xFF6B4E9E)),
            ),
          ],
        ),
      ),
    );
  }
}
