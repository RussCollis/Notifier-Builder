import Foundation
import AppKit
import UserNotifications

enum LiveExecutionResult {
    case success(String)
    case warning(message: String, showsSettingsButton: Bool)
    case failure(String)
}

class LiveNotificationRunner {
    static let shared = LiveNotificationRunner()
    
    private init() {}
    
    /// Dispatches using the real Jamf Notifier CLI binary on disk if available,
    /// or falls back with clear guidance.
    func runJamfNotifierBinary(config: NotifierConfiguration, completion: @escaping (LiveExecutionResult) -> Void) {
        let binaryPath = config.binaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard FileManager.default.fileExists(atPath: binaryPath) else {
            completion(.failure("Notifier binary not found at '\(binaryPath)'. Install Jamf Notifier or switch mode to 'macOS System Notification'."))
            return
        }
        
        let args = config.buildCommandLineArguments()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binaryPath)
            process.arguments = args
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                let combined = (stdout + "\n" + stderr).trimmingCharacters(in: .whitespacesAndNewlines)
                
                DispatchQueue.main.async {
                    if combined.contains("not yet approved") || combined.contains("Authorisation status") {
                        completion(.warning(
                            message: "Jamf Notifier is installed, but Notifications are not yet enabled for 'Notifier.app' in macOS System Settings. Please toggle permission ON in System Settings or deploy an MDM PPPC profile.",
                            showsSettingsButton: true
                        ))
                    } else if process.terminationStatus == 0 {
                        let msg = combined.isEmpty ? "Jamf Notifier successfully posted the notification!" : combined
                        completion(.success("✓ \(msg)"))
                    } else {
                        completion(.failure("Notifier exited with code \(process.terminationStatus): \(combined)"))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure("Failed to launch Notifier binary: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    /// Posts a guaranteed live notification using macOS UserNotifications + AppleScript
    func postSystemNotification(config: NotifierConfiguration, completion: @escaping (LiveExecutionResult) -> Void) {
        // Audition sound
        if config.sound != .none {
            config.sound.play()
        }
        
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = config.title.isEmpty ? "Notifier Builder" : config.title
        if !config.subtitle.isEmpty {
            content.subtitle = config.subtitle
        }
        content.body = config.message.isEmpty ? "Test Notification" : config.message
        if config.sound != .none {
            content.sound = .default
        }
        
        // Attach the configured buttons as notification actions via a category
        var actions: [UNNotificationAction] = []
        if config.hasButton1 && !config.button1Label.isEmpty {
            actions.append(UNNotificationAction(identifier: "button1", title: config.button1Label, options: [.foreground]))
        }
        if config.hasButton2 && !config.button2Label.isEmpty {
            actions.append(UNNotificationAction(identifier: "button2", title: config.button2Label, options: [.foreground]))
        }
        let categoryID = "notifier-builder-\(UUID().uuidString)"
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: actions,
            intentIdentifiers: [],
            options: config.hasDismissAction ? [.customDismissAction] : []
        )
        content.categoryIdentifier = categoryID
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.setNotificationCategories([category])
        // Reading the categories back ensures registration has completed before posting,
        // otherwise the notification can be delivered without its action buttons.
        center.getNotificationCategories { _ in
            center.add(request) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        // AppleScript notifications cannot show buttons, so only use it as a fallback
                        self.runAppleScriptFallback(config: config, completion: completion)
                    } else {
                        completion(.success("Live notification posted to top-right of screen!"))
                    }
                }
            }
        }
    }
    
    private func runAppleScriptFallback(config: NotifierConfiguration, completion: @escaping (LiveExecutionResult) -> Void) {
        let titleClean = config.title.isEmpty ? "Notifier Builder" : config.title.replacingOccurrences(of: "\"", with: "\\\"")
        let subClean = config.subtitle.replacingOccurrences(of: "\"", with: "\\\"")
        let msgClean = config.message.isEmpty ? "Test Notification" : config.message.replacingOccurrences(of: "\"", with: "\\\"")
        
        var script = "display notification \"\(msgClean)\" with title \"\(titleClean)\""
        if !subClean.isEmpty {
            script += " subtitle \"\(subClean)\""
        }
        if config.sound != .none && !config.effectiveSoundString.isEmpty {
            script += " sound name \"\(config.effectiveSoundString)\""
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var errorInfo: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&errorInfo)
            }
            
            DispatchQueue.main.async {
                if let err = errorInfo {
                    let errMsg = err[NSAppleScript.errorMessage] as? String ?? "AppleScript error"
                    completion(.failure("Error: \(errMsg)"))
                } else {
                    completion(.success("Live notification posted to top-right of screen!"))
                }
            }
        }
    }
    
    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
}
