import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class CustomCurvedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final ScrollController scrollController;
  final VoidCallback onScrollToTop;
  final VoidCallback onScrollToBottom;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleNotifications;
  final bool showNotifications;
  final List<Widget> actions;

  const CustomCurvedAppBar({
    super.key,
    required this.title,
    required this.scrollController,
    this.onScrollToTop = _defaultScrollToTop,
    this.onScrollToBottom = _defaultScrollToBottom,
    this.onToggleTheme = _defaultToggleTheme,
    this.onToggleNotifications = _defaultToggleNotifications,
    this.showNotifications = true,
    this.actions = const [],
  });

  static void _defaultScrollToTop() {}
  static void _defaultScrollToBottom() {}
  static void _defaultToggleTheme() {}
  static void _defaultToggleNotifications() {}

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CurvedAppBarClipper(),
      child: Container(
        color: const Color.fromRGBO(252, 241, 251, 0).withValues(alpha: 1),
        child: AppBar(
          title: GestureDetector(
            onTap: _toggleScrollPosition,
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor:
              AppColors.transparent, // Keep transparent for curved effect
          elevation: 0,
          actions: actions,
        ),
      ),
    );
  }

  void _toggleScrollPosition() {
    if (scrollController.offset == scrollController.position.minScrollExtent) {
      onScrollToBottom();
    } else if (scrollController.offset ==
        scrollController.position.maxScrollExtent) {
      onScrollToTop();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class CurvedAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(0, size.height, size.width * 0.2, size.height);
    path.lineTo(size.width * 0.8, size.height);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
