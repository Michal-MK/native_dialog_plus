import Flutter
import UIKit

public class SwiftNativeDialogPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftNativeDialogPlusPlugin()
    NativeDialogHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  private var rootViewController: UIViewController? {
    return UIApplication.shared.keyWindow?.rootViewController
  }

  private func uiColor(fromARGB argb: Int64) -> UIColor {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red   = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >>  8) & 0xFF) / 255.0
    let blue  = CGFloat( argb        & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension SwiftNativeDialogPlusPlugin: NativeDialogHostApi {
  func showDialog(
    args: ShowDialogArgs,
    completion: @escaping (Result<Int64?, Error>) -> Void
  ) {
    guard let controller = rootViewController else {
      completion(.failure(PigeonError(
        code: "UNAVAILABLE",
        message: "Native alert is unavailable",
        details: nil
      )))
      return
    }

    var alertStyle: UIAlertController.Style
    switch args.style {
    case .actionSheet:
      // .actionSheet is not supported on iPadOS since 13.2
      alertStyle = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
    case .alert:
      alertStyle = .alert
    }

    let alert = UIAlertController(
      title: args.title,
      message: args.message,
      preferredStyle: alertStyle
    )

    for (index, action) in args.actions.enumerated() {
      let uiStyle: UIAlertAction.Style
      switch action.style {
      case .defaultStyle: uiStyle = .default
      case .cancel:       uiStyle = .cancel
      case .destructive:  uiStyle = .destructive
      }

      let alertAction = UIAlertAction(title: action.text, style: uiStyle) { _ in
        completion(.success(Int64(index)))
      }
      alertAction.isEnabled = action.enabled

      if let colorValue = action.color {
        alertAction.setValue(uiColor(fromARGB: colorValue), forKey: "titleTextColor")
      }

      alert.addAction(alertAction)
    }

    controller.present(alert, animated: true)
  }
}
