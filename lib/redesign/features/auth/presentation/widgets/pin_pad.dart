import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/widgets/pin_key.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';

/// The kiosk's 3 by 4 pad: nine digits, a gap, zero, and backspace.
///
/// The empty tenth slot is deliberate. It keeps zero centred under the 8 and
/// backspace under the 9, which is where a thumb expects them.
class PinPad extends StatelessWidget {
  const PinPad({
    required this.onDigit,
    required this.onBackspace,
    this.padding = AuthSizes.padGridPad,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final EdgeInsetsGeometry padding;

  static const List<String> _digits = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      spacing: AuthSizes.padGap,
      children: <Widget>[
        for (int row = 0; row < 3; row++)
          _Row(
            children: <Widget>[
              for (int col = 0; col < 3; col++)
                _key(label: _digits[row * 3 + col]),
            ],
          ),
        _Row(
          children: <Widget>[
            const SizedBox.shrink(),
            _key(label: '0'),
            SizedBox(
              height: AuthSizes.padKeyHeight,
              child: PinKey(
                icon: AppIcons.backspace,
                semanticLabel: AuthStrings.backspace,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _key({required String label}) => SizedBox(
    height: AuthSizes.padKeyHeight,
    child: PinKey(label: label, onTap: () => onDigit(label)),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AuthSizes.padGap,
    children: <Widget>[
      for (final child in children) Expanded(child: child),
    ],
  );
}
