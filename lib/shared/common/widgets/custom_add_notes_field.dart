// import 'package:flutter/material.dart';

// class CustomAddNoteButton extends StatelessWidget {
//   final VoidCallback onTap;

//   const CustomAddNoteButton({super.key, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF8F7FA), // light lavender/gray background
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFEDE9F0)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               "Add Note",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF4B2E4C),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(4),
//               // decoration: BoxDecoration(
//               //   color: Colors.white,
//               //   shape: BoxShape.circle,
//               //   border: Border.all(color: const Color(0xFFD1C4E9)),
//               // ),
//               child: const Icon(Icons.add, size: 22, color: Color(0xFF6B4E9E)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class CustomAddNoteButton extends StatefulWidget {
  final Function(String value)? onSubmitted;

  const CustomAddNoteButton({super.key, this.onSubmitted});

  @override
  State<CustomAddNoteButton> createState() => _CustomAddNoteButtonState();
}

class _CustomAddNoteButtonState extends State<CustomAddNoteButton> {
  bool isEditing = false;
  final TextEditingController _controller = TextEditingController();

  void _handleSubmit() {
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(_controller.text);
    }
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isEditing
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE9F0)),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: "Enter note...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
          )
        : GestureDetector(
            onTap: () {
              setState(() {
                isEditing = true;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE9F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Add Note",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B2E4C),
                    ),
                  ),
                  Icon(Icons.add, size: 22, color: Color(0xFF6B4E9E)),
                ],
              ),
            ),
          );
  }
}
