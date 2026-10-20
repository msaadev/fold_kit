import Flutter
import UIKit

/// Streams the iPhone Duo fold (reserved `.division` regions) and hinge status to Dart.
public class FoldKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var view: UIView?
  private var hinge: UIInteraction?
  private var boundsObservation: NSKeyValueObservation?
  private var status = "unknown"
  private var angle: Double?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(name: "fold_kit/fold", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(FoldKitPlugin())
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    DispatchQueue.main.async { self.attach() }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    detach()
    sink = nil
    return nil
  }

  private func attach() {
    guard let root = Self.flutterView() else { return }
    view = root
    // Bounds change on rotation, Split View and display switches; the hinge handler alone misses some of them.
    boundsObservation = root.layer.observe(\.bounds, options: [.new]) { [weak self] _, _ in
      DispatchQueue.main.async { self?.send() }
    }
    addHingeInteraction(to: root)
    send()
  }

  private func detach() {
    boundsObservation = nil
    if let hinge, let view { view.removeInteraction(hinge) }
    hinge = nil
    view = nil
  }

  private func addHingeInteraction(to root: UIView) {
#if canImport(UIKit, _version: 9127.0.85)
    if #available(iOS 27.1, *) {
      let interaction = UIHingeInteraction { [weak self] _, update in
        guard let self else { return }
        switch update.hinge?.status {
        case .closed: self.status = "closed"
        case .partiallyOpen: self.status = "partiallyOpen"
        case .fullyOpen: self.status = "fullyOpen"
        default: self.status = "unknown"
        }
        // UIHinge.angle is in radians; Dart expects degrees. Fully open is pinned to 180 like Triangle Calculator.
        self.angle = update.hinge.map { $0.status == .fullyOpen ? 180 : Double($0.angle) * 180 / .pi }
        self.send()
      }
      root.addInteraction(interaction)
      hinge = interaction
    }
#endif
  }

  private func send() {
    guard let sink, let view else { return }
    sink([
      "status": status,
      "angle": angle as Any,
      "folds": Self.folds(in: view),
      "model": Self.model,
    ])
  }

  private static func folds(in view: UIView) -> [[String: Double]] {
#if canImport(UIKit, _version: 9127.0.85)
    if #available(iOS 27.1, *) {
      return view.reservedRegions(kind: .division)
        .filter { $0.isActive && $0.frame.width > 0 && $0.frame.height > 0 }
        .map { ["x": $0.frame.minX, "y": $0.frame.minY, "width": $0.frame.width, "height": $0.frame.height] }
    }
#endif
    return []
  }

  // e.g. "iPhone19,4"; the simulator reports the device it simulates.
  private static let model: String = {
    if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
      return simulated
    }
    var info = utsname()
    uname(&info)
    return withUnsafeBytes(of: &info.machine) { bytes in
      String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
    }
  }()

  private static func flutterView() -> UIView? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first
    return window?.rootViewController?.view
  }
}
