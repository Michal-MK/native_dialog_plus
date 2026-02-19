import 'dart:async';
import 'package:flutter/services.dart';

import 'src/platform_bindings.g.dart';

/// DTO for a dialog action button.
class NativeDialogPlusAction {
  /// Text displayed on the button.
  final String text;

  /// Visual style of the button.
  final NativeDialogPlusActionStyle style;

  /// Callback invoked when the user taps the button.
  /// If null, the button is rendered as disabled.
  final VoidCallback? onPressed;

  /// Optional color for the button text. Null uses the platform default.
  final Color? color;

  NativeDialogPlusAction({
    required this.text,
    this.style = NativeDialogPlusActionStyle.defaultStyle,
    this.onPressed,
    this.color,
  });

  bool get enabled => onPressed != null;

  DialogAction _toMessage() => DialogAction(
        text: text,
        style: switch (style) {
          NativeDialogPlusActionStyle.defaultStyle => ActionStyle.defaultStyle,
          NativeDialogPlusActionStyle.cancel => ActionStyle.cancel,
          NativeDialogPlusActionStyle.destructive => ActionStyle.destructive,
        },
        enabled: enabled,
        color: color?.toARGB32(),
      );
}

/// Enum mapping for the [UIAlertController.Style](https://developer.apple.com/documentation/uikit/uialertcontroller/style)
enum NativeDialogPlusStyle {
  /// An action sheet displayed by the view controller that presented it.
  /// Is the native equivalent to [CupertinoActionSheet](https://api.flutter.dev/flutter/cupertino/CupertinoActionSheet-class.html)
  actionSheet,

  /// An alert displayed modally for the app.
  /// Is the native equivalent to [CupertinoAlertDialog](https://api.flutter.dev/flutter/cupertino/CupertinoAlertDialog-class.html)
  alert,
}

/// Enum mapping for the [UIAlertAction.Style](https://developer.apple.com/documentation/uikit/uialertaction/style)
enum NativeDialogPlusActionStyle {
  /// Apply the default style to the action's button.
  defaultStyle,

  /// Apply a style that indicates the action cancels the operation and leaves things unchanged.
  cancel,

  /// Apply a style that indicates the action might change or delete data.
  destructive,
}

class NativeDialogPlus {
  static final _api = NativeDialogHostApi();

  /// Title of the dialog
  final String? title;

  /// Main content of the dialog
  final String? message;

  final bool cancellable;

  /// Style of the dialog, which determines if it is the native equivalent to a [CupertinoAlertDialog](https://api.flutter.dev/flutter/cupertino/CupertinoAlertDialog-class.html) or [CupertinoActionSheet](https://api.flutter.dev/flutter/cupertino/CupertinoActionSheet-class.html)
  final NativeDialogPlusStyle style;

  /// List of actions that the dialog has.
  /// Please note that if there is no action, the user cannot close the dialog unless he closes the whole app.
  /// The same also applies when all actions are disabled (`onPressed` is null)
  /// **IMPORTANT**
  /// Android is limited to the maximum of 3 actions one of each NativeDialogPlusActionStyle style
  /// therefore its limited to one defaultStyle, cancel and destructive each, the order of the actions in the list does not change the position in the dialog.
  final List<NativeDialogPlusAction> actions;

  NativeDialogPlus({
    this.title,
    this.message,
    this.cancellable = false,
    this.style = NativeDialogPlusStyle.alert,
    required this.actions,
  });

  /// Shows the native dialog and calls the specific `onPressed` handler of the tapped action.
  Future<void> show() async {
    final result = await _api.showDialog(ShowDialogArgs(
      title: title,
      message: message,
      cancellable: cancellable,
      style: style == NativeDialogPlusStyle.actionSheet
          ? DialogStyle.actionSheet
          : DialogStyle.alert,
      actions: [for (final a in actions) a._toMessage()],
    ));
    if (result == null) return;
    final action = actions[result];
    if (!action.enabled || action.onPressed == null) return;
    action.onPressed!();
  }
}
