import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The bar under the Notes tab (7c): an attach key, the well you type into,
/// and the pink send key.
///
/// It owns its own text, and hands the finished line up on send. The send key
/// is the screen's one action while this tab is open.
class NoteComposer extends StatefulWidget {
  const NoteComposer({required this.onSend, this.onAttach, super.key});

  final ValueChanged<String> onSend;
  final VoidCallback? onAttach;

  @override
  State<NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends State<NoteComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: ClassroomsSizes.composerPad.copyWith(
        bottom: ClassroomsSizes.composerPad.bottom + context.safeArea.bottom,
      ),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.barLine)),
      ),
      child: Row(
        spacing: ClassroomsSizes.composerGap,
        children: <Widget>[
          IconKey(
            icon: AppIcons.plus,
            semanticLabel: ClassroomsStrings.attachToNote,
            onTap: widget.onAttach,
          ),
          Expanded(
            child: SurfaceBox(
              surface: AppSurfaces.field(c),
              padding: AppSizes.searchPad,
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                cursorColor: c.pink,
                style: ClassroomsTextStyles.composer.copyWith(color: c.ink),
                decoration: InputDecoration.collapsed(
                  hintText: ClassroomsStrings.writeNote,
                  hintStyle: ClassroomsTextStyles.composer.copyWith(
                    color: c.ink3,
                  ),
                ),
              ),
            ),
          ),
          _SendKey(onTap: _send),
        ],
      ),
    );
  }
}

/// The pink square that posts the note.
class _SendKey extends StatelessWidget {
  const _SendKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: ClassroomsStrings.sendNote,
      child: Pressable.key(
        onTap: onTap,
        child: Container(
          width: ClassroomsSizes.composerSendKey,
          height: ClassroomsSizes.composerSendKey,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.pink,
            borderRadius: AppRadii.innerR,
          ),
          child: Icon(
            AppIcons.send,
            size: ClassroomsSizes.composerGlyph,
            color: c.onPink,
          ),
        ),
      ),
    );
  }
}
