import Flutter
import UIKit
import Foundation

// Manages notification observers for receivers
class NotificationObserverManager {
    private var observers: [Int: [NSObjectProtocol]] = [:]

    func addObservers(id: Int, names: [String], center: NotificationCenter, onNotification: @escaping (Notification) -> Void) {
        // Remove existing observers for this receiver ID
        removeObservers(id: id, center: center)

        var newObservers: [NSObjectProtocol] = []
        for name in names {
            let notificationName = NSNotification.Name(name)
            let observer = center.addObserver(
                forName: notificationName,
                object: nil,
                queue: .main
            ) { notification in
                onNotification(notification)
            }
            newObservers.append(observer)
        }
        observers[id] = newObservers
    }

    func removeObservers(id: Int, center: NotificationCenter) {
        if let existingObservers = observers[id] {
            for observer in existingObservers {
                center.removeObserver(observer)
            }
        }
        observers.removeValue(forKey: id)
    }

    func removeAll(center: NotificationCenter) {
        for (_, observerList) in observers {
            for observer in observerList {
                center.removeObserver(observer)
            }
        }
        observers.removeAll()
    }
}

public class SwiftFlutterBroadcastsPlugin: NSObject, FlutterPlugin {
    static var instance: SwiftFlutterBroadcastsPlugin?
    private var methodChannel: FlutterMethodChannel?
    private let notificationManager = NotificationObserverManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "de.kevlatus.flutter_broadcasts",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftFlutterBroadcastsPlugin()
        instance.methodChannel = channel
        SwiftFlutterBroadcastsPlugin.instance = instance
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startReceiver":
            handleStartReceiver(call, result: result)
        case "stopReceiver":
            handleStopReceiver(call, result: result)
        case "sendBroadcast":
            handleSendBroadcast(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleStartReceiver(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let names = args["names"] as? [String] else {
            result(FlutterError(
                code: "1",
                message: "Invalid arguments: id and names are required",
                details: nil
            ))
            return
        }

        notificationManager.addObservers(
            id: id,
            names: names,
            center: NotificationCenter.default
        ) { [weak self] notification in
            self?.handleNotification(notification, receiverId: id)
        }

        result(nil)
    }

    private func handleStopReceiver(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int else {
            result(FlutterError(
                code: "1",
                message: "Invalid arguments: id is required",
                details: nil
            ))
            return
        }

        notificationManager.removeObservers(id: id, center: NotificationCenter.default)
        result(nil)
    }

    private func handleSendBroadcast(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let name = args["name"] as? String else {
            result(FlutterError(
                code: "1",
                message: "Invalid arguments: name is required",
                details: nil
            ))
            return
        }

        let data = args["data"] as? [String: Any] ?? [:]
        let notificationName = NSNotification.Name(name)

        NotificationCenter.default.post(
            name: notificationName,
            object: nil,
            userInfo: data
        )

        result(nil)
    }

    private func handleNotification(_ notification: Notification, receiverId: Int) {
        var data: [String: Any] = [:]

        // Extract userInfo data
        if let userInfo = notification.userInfo {
            for (key, value) in userInfo {
                if let keyString = key as? String {
                    data[keyString] = normalizeValue(value)
                }
            }
        }

        let message: [String: Any?] = [
            "receiverId": receiverId,
            "name": notification.name.rawValue,
            "data": data
        ]

        // Send to Flutter via method channel
        sendBroadcastToFlutter(message)
    }

    // Normalize values to Flutter-compatible types
    private func normalizeValue(_ value: Any) -> Any? {
        if let nsNull = value as? NSNull {
            return nil
        } else if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number
        } else if let array = value as? [Any] {
            return array.map { normalizeValue($0) ?? NSNull() }
        } else if let dict = value as? [AnyHashable: Any] {
            var result: [String: Any] = [:]
            for (key, val) in dict {
                if let keyString = key as? String {
                    result[keyString] = normalizeValue(val) ?? NSNull()
                }
            }
            return result
        } else if let data = value as? Data {
            return data
        } else if let date = value as? Date {
            return Int(date.timeIntervalSince1970 * 1000)
        } else {
            // Fallback: convert to string representation
            return String(describing: value)
        }
    }

    // Send broadcast message to Flutter layer
    func sendBroadcastToFlutter(_ message: [String: Any?]) {
        methodChannel?.invokeMethod("receiveBroadcast", arguments: message)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        notificationManager.removeAll(center: NotificationCenter.default)
        SwiftFlutterBroadcastsPlugin.instance = nil
    }
}
