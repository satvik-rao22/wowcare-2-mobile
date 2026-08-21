import 'package:flutter/cupertino.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';

class CheckboxWidget extends StatefulWidget {
  const CheckboxWidget({
    super.key,
    this.isEditable = true,
    required this.label,
    this.isChecked = true,
    this.onChecked,
  });
  final bool isEditable;
  final String label;
  final bool isChecked;
  final ValueChanged<bool>? onChecked;

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.isChecked;
  }

  void _handleChanged(bool? value) {
    final newValue = value ?? false;
    setState(() {
      _isChecked = newValue;
    });
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
          child: CustomCheckbox(
            value: _isChecked,
            borderColor: AppColors.themeColor,
            onChanged: widget.isEditable ? _handleChanged : null,
            // onChanged: widget.isEditable ?(v) {
            //   final newVal = v ?? false;
            //   setState(() {
            //     _isChecked = newVal;
            //   });
            // } : null,
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: widget.isEditable ? () => _handleChanged(!_isChecked) : null,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
