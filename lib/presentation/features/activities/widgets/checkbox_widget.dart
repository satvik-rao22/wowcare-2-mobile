import 'package:flutter/cupertino.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';

class CheckboxWidget extends StatefulWidget {
  const CheckboxWidget({super.key, this.isEditable = true, required this.label, this.isChecked = true, this.onChecked});
  final bool isEditable;
  final String label;
  final bool isChecked;
  final ValueChanged<bool>? onChecked;

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

/// Kept as a minimal StatefulWidget purely to own and dispose the
/// [ValueNotifier] below (Mandate 2: UI micro-state that belongs to one
/// widget uses ValueNotifier + ValueListenableBuilder, not setState — but the
/// notifier itself still needs a State to be created/disposed in).
class _CheckboxWidgetState extends State<CheckboxWidget> {
  late final ValueNotifier<bool> _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = ValueNotifier<bool>(widget.isChecked);
  }

  @override
  void dispose() {
    _isChecked.dispose();
    super.dispose();
  }

  void _handleChanged(bool? value) {
    final newValue = value ?? false;
    _isChecked.value = newValue;
    widget.onChecked?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final double opacity = widget.isEditable ? 1.0 : 0.2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: opacity,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isChecked,
            builder: (_, checked, __) => CustomCheckbox(
              value: checked,
              borderColor: AppColors.themeColor,
              onChanged: widget.isEditable ? _handleChanged : null,
            ),
          ),
        ),
        const SizedBox(width: 2,),
        GestureDetector(
          onTap: widget.isEditable ? () => _handleChanged(!_isChecked.value) : null,
          child: Text(
            widget.label,
            style: AppTextStyles.activityStrongLabel,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
