import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';

/// The first screen after boot while both presentation layers coexist.
///
/// Two keys: **New Design** hands the tree to the redesign, **Old Design**
/// hands it to the existing app exactly as it ships today. Nothing is
/// persisted; the choice is made on every launch so a reviewer can flip
/// between the two without reinstalling.
///
/// This is a launcher, not part of either design, so it is deliberately plain
/// and self-contained: it does not read the redesign's theme or the old app's
/// providers, so neither tree is inflated until it is chosen.
class DesignChooser extends StatefulWidget {
  const DesignChooser({
    required this.newDesign,
    required this.oldDesign,
    super.key,
  });

  /// Built when the reviewer picks New Design.
  final WidgetBuilder newDesign;

  /// Built when the reviewer picks Old Design.
  final WidgetBuilder oldDesign;

  @override
  State<DesignChooser> createState() => _DesignChooserState();
}

enum _Choice { newDesign, oldDesign }

class _DesignChooserState extends State<DesignChooser> {
  _Choice? _choice;

  @override
  Widget build(BuildContext context) {
    switch (_choice) {
      case _Choice.newDesign:
        return Builder(builder: widget.newDesign);
      case _Choice.oldDesign:
        return Builder(builder: widget.oldDesign);
      case null:
        return _ChooserApp(onChoose: (c) => setState(() => _choice = c));
    }
  }
}

class _ChooserApp extends StatelessWidget {
  const _ChooserApp({required this.onChoose});

  final ValueChanged<_Choice> onChoose;

  static const Color _ground = Color(0xFFFBF8F2);
  static const Color _ink = Color(0xFF0A1C5D);
  static const Color _ink3 = Color(0xFF8A93B2);
  static const Color _pink = Color(0xFFE01B5D);
  static const Color _pinkRim = Color(0xFFA10F45);
  static const Color _card = Color(0xFFFBFCFF);
  static const Color _keyRim = Color(0xFFCFD8EC);
  static const Color _warmWhite = Color(0xFFFFFAF2);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _ground,
        fontFamily: 'Poppins',
        splashFactory: NoSplash.splashFactory,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.launcherPrompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink3,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                _Key(
                  label: AppStrings.launcherNewDesign,
                  face: _pink,
                  rim: _pinkRim,
                  ink: _warmWhite,
                  onTap: () => onChoose(_Choice.newDesign),
                ),
                const SizedBox(height: 16),
                _Key(
                  label: AppStrings.launcherOldDesign,
                  face: _card,
                  rim: _keyRim,
                  ink: _ink,
                  onTap: () => onChoose(_Choice.oldDesign),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A rimmed key that sinks onto its rim when pressed.
class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.face,
    required this.rim,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color face;
  final Color rim;
  final Color ink;
  final VoidCallback onTap;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const double rimHeight = 4;
    final double sink = _down ? rimHeight - 1 : 0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, sink, 0),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.face,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x170A1C5D)),
          boxShadow: [
            BoxShadow(
              color: widget.rim,
              offset: Offset(0, rimHeight - sink),
            ),
          ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
