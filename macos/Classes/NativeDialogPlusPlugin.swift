import Cocoa
import FlutterMacOS

public class NativeDialogPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NativeDialogPlusPlugin()
    NativeDialogHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  private func nsColor(fromARGB argb: Int64) -> NSColor {
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red   = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >>  8) & 0xFF) / 255.0
    let blue  = CGFloat( argb        & 0xFF) / 255.0
    return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
  }
}

extension NativeDialogPlusPlugin: NativeDialogHostApi {
  func showDialog(
    args: ShowDialogArgs,
    completion: @escaping (Result<Int64?, Error>) -> Void
  ) {
    guard let window = NSApplication.shared.windows.first else {
      completion(.failure(PigeonError(
        code: "UNAVAILABLE",
        message: "Native alert is unavailable",
        details: nil
      )))
      return
    }

    let alert = NSAlert()
    alert.messageText = args.title ?? ""
    alert.informativeText = args.message ?? ""

    for (index, action) in args.actions.enumerated() {
      alert.addButton(withTitle: action.text)
      let button = alert.buttons[index]
      button.isEnabled = action.enabled

      if #available(macOS 11.0, *) {
        button.hasDestructiveAction = action.style == .destructive
      }

      if let colorValue = action.color {
        let color = nsColor(fromARGB: colorValue)
        button.attributedTitle = NSAttributedString(
          string: action.text,
          attributes: [.foregroundColor: color]
        )
      }
    }

    alert.beginSheetModal(for: window) { response in
      let index = Int(response.rawValue) - Int(NSApplication.ModalResponse.alertFirstButtonReturn.rawValue)
      completion(.success(Int64(index)))
    }
  }
}
