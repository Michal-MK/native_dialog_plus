import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/platform_bindings.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/josephabel/native_dialog_plus/FlutterBindings.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.josephabel.native_dialog_plus'),
  swiftOut: 'ios/Classes/FlutterBindings.g.swift',
  dartPackageName: 'native_dialog_plus',
))

/// The presentation style of the dialog.
enum DialogStyle {
  /// Bottom action sheet (CupertinoActionSheet equivalent).
  actionSheet,

  /// Modal alert dialog (CupertinoAlertDialog equivalent).
  alert,
}

/// The visual style of an individual action button.
enum ActionStyle {
  /// Standard button.
  defaultStyle,

  /// Cancel button.
  cancel,

  /// Destructive / delete button.
  destructive,
}

/// A single button in the dialog.
class DialogAction {
  const DialogAction({
    required this.text,
    required this.style,
    required this.enabled,
    this.color,
  });

  final String text;
  final ActionStyle style;
  final bool enabled;

  /// ARGB color for the button text (Flutter's Color.toARGB32()).
  /// Null means the platform default is used.
  final int? color;
}

/// Arguments for showing a native dialog.
class ShowDialogArgs {
  const ShowDialogArgs({
    this.title,
    this.message,
    required this.cancellable,
    required this.style,
    required this.actions,
  });

  final String? title;
  final String? message;
  final bool cancellable;
  final DialogStyle style;
  final List<DialogAction> actions;
}

/// Flutter → Native API.
@HostApi()
abstract class NativeDialogHostApi {
  /// Shows the dialog and returns the index of the tapped action,
  /// or null if the dialog was dismissed without a selection.
  @async
  int? showDialog(ShowDialogArgs args);
}
