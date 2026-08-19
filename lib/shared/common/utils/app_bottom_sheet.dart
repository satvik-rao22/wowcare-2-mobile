import 'package:flutter/material.dart';

class AppBottomSheet {
  /// A centralized wrapper for `showModalBottomSheet` that automatically handles
  /// Android/iOS safe areas at the bottom of the screen (e.g., gesture navigation bars,
  /// home indicators).
  ///
  /// This wrapper ensures that the bottom sheet respects the system insets
  /// without causing double-padding when the keyboard is opened.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    String? barrierLabel,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    bool useSafeArea = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: backgroundColor,
      barrierLabel: barrierLabel,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          bottom: true,
          left: false,
          right: false,
          maintainBottomViewPadding: false,
          child: builder(ctx),
        );
      },
    );
  }
}
