

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class OunceInputWidget extends StatefulWidget {
  const OunceInputWidget({super.key, this.controller, this.isRequired = false, this.label = 'Input', this.hint , this.height, this.min = 0.5, this.max = 50.0, this.onValidChanged});
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired ;
  final double? height;
  final double min; // min value accepted by the text field
  final double max; // max value accepted by the text field
  final ValueChanged<double?>? onValidChanged;

  @override
  State<OunceInputWidget> createState() => OunceInputWidgetState();
}

class OunceInputWidgetState extends State<OunceInputWidget> {
  late TextEditingController _controller;
  String? _errorText;
  double? _lastValidValue;

  @override
  void initState(){
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_validate);
  }

  void _validate(){
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText =  null;
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
    } else if (value < widget.min || value > widget.max){
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
    if(oldWidget.min != widget.min || oldWidget.max != widget.max) {
      _validate();
    }
  }

  @override
  void dispose(){
    _controller.removeListener(_validate);
    if(widget.controller == null) _controller.dispose();
    super.dispose();
  }

  double? get validValue => _lastValidValue;


  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: "Manrope",
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: widget.label),
              if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: widget.height ?? responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d?$'))
            ],
            decoration: InputDecoration(
              hintText: '${widget.min} - ${widget.max} oz',
              //helperText: '${widget.min} - ${widget.max} oz',
              errorText: _errorText,
              errorMaxLines: 2,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }
}
