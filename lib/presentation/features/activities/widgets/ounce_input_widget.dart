import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class OunceInputWidget extends StatefulWidget {
  const OunceInputWidget({
    super.key,
    this.controller,
    this.isRequired = false,
    this.label = 'Input',
    this.hint,
    this.height,
    this.min = 0.5,
    this.max = 50.0,
    this.onValidChanged,
    this.readOnly = false,
  });
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired;
  final double? height;
  final double min; // min value accepted by the text field
  final double max; // max value accepted by the text field
  final ValueChanged<double?>? onValidChanged;
  final bool readOnly;

  @override
  State<OunceInputWidget> createState() => OunceInputWidgetState();
}

class OunceInputWidgetState extends State<OunceInputWidget> {
  late TextEditingController _controller;
  String? _errorText;
  double? _lastValidValue;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_validate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validate();
    });
  }

  void _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = null;
        _lastValidValue = null;
      });
      widget.onValidChanged?.call(null);
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      setState(() {
        _errorText = 'Invalid input';
        _lastValidValue = null;
      });
      widget.onValidChanged?.call(null);
      return;
    } else if (value < widget.min || value > widget.max) {
      setState(() {
        _errorText = 'Must be between ${widget.min} - ${widget.max} oz';
        _lastValidValue = null;
      });
      widget.onValidChanged?.call(null);
      return;
    } else {
      setState(() {
        _errorText = null;
        _lastValidValue = value;
        widget.onValidChanged?.call(value);
      });
    }
  }

  @override
  void didUpdateWidget(covariant OunceInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min || oldWidget.max != widget.max) {
      _validate();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_validate);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  double? get validValue => _lastValidValue;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = AppTextStyles.activityInputFieldLabel(
      fontSize: responsive.labelFontSize,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: widget.label),
              if (widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: AppTextStyles.activityRequiredMarker,
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: widget.height ?? responsive.inputFieldHeight,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            border: Border.all(color: AppColors.inputBorderColor),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _controller,
            readOnly: widget.readOnly,
            enableInteractiveSelection: !widget.readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              // Was capped at a single decimal digit (^\d*\.?\d?$), so only
              // values like 5.5 could be typed and anything finer (5.25,
              // 5.75, ...) got silently cut off after the first decimal
              // digit — read by users as "only accepts multiples of 0.5".
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
            ],
            decoration: InputDecoration(
              hintText: '${widget.min} - ${widget.max} oz',
              //helperText: '${widget.min} - ${widget.max} oz',
              errorText: _errorText,
              errorMaxLines: 2,
              hintStyle: labelStyle.copyWith(
                color: AppColors.activityMutedGreyColor,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: AppTextStyles.activityInputValueText(
              fontSize: responsive.inputFontSize,
            ),
          ),
        ),
      ],
    );
  }
}
