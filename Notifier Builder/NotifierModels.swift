import Foundation
import AppKit

// MARK: - Enums & Options

/// Notification display style supported by Notifier
enum NotificationType: String, CaseIterable, Identifiable {
    case alert = "alert"
    case banner = "banner"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alert: return "Alert (Persistent)"
        case .banner: return "Banner (Temporary)"
        }
    }
    
    var subtitleDescription: String {
        switch self {
        case .alert: return "Remains on screen until user dismisses or clicks an action button"
        case .banner: return "Appears briefly at top-right and auto-dismisses after a few seconds"
        }
    }
}

/// Notification removal flag
enum RemoveMode: String, CaseIterable, Identifiable {
    case none = "none"
    case prior = "prior"
    case all = "all"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "Don't Remove (Post New)"
        case .prior: return "Remove Prior (--remove prior)"
        case .all: return "Remove All (--remove all)"
        }
    }
}

/// Common macOS system sounds supported by Notifier
enum SoundOption: String, CaseIterable, Identifiable {
    case none = "none"
    case defaultSound = "default"
    case basso = "Basso"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case glass = "Glass"
    case hero = "Hero"
    case morse = "Morse"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case tink = "Tink"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .defaultSound: return "Standard Default Sound"
        case .none: return "No Sound"
        case .custom: return "Custom Sound Name..."
        default: return rawValue
        }
    }
    
    func play() {
        if self == .none { return }
        if self == .defaultSound {
            NSSound(named: "Glass")?.play()
        } else {
            NSSound(named: rawValue)?.play()
        }
    }
}

/// Preset icon styles for previewing and rebranding
enum PresetIcon: String, CaseIterable, Identifiable {
    case jamf = "Jamf Notifier"
    case warning = "Warning Alert"
    case security = "Security Shield"
    case update = "Software Update"
    case restart = "System Restart"
    case settings = "System Settings"
    case bell = "Notification Bell"
    case terminal = "Terminal Script"
    case custom = "Custom Image Path"
    
    var id: String { rawValue }
    
    var systemSymbol: String {
        switch self {
        case .jamf: return "app.badge.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .security: return "shield.lefthalf.filled.badge.checkmark"
        case .update: return "arrow.triangle.2.circlepath.circle.fill"
        case .restart: return "power.circle.fill"
        case .settings: return "gearshape.fill"
        case .bell: return "bell.badge.fill"
        case .terminal: return "terminal.fill"
        case .custom: return "photo.fill"
        }
    }
    
    var defaultRebrandPath: String {
        switch self {
        case .jamf: return "/Applications/Utilities/Notifier.app/Contents/Resources/AppIcon.icns"
        case .warning: return "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
        case .security: return "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SecurityAgent.icns"
        case .update: return "/System/Library/CoreServices/Software Update.app/Contents/Resources/AppIcon.icns"
        case .restart: return "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ErasingIcon.icns"
        case .settings: return "/System/Applications/System Settings.app/Contents/Resources/AppIcon.icns"
        case .bell: return "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarInfo.icns"
        case .terminal: return "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns"
        case .custom: return ""
        }
    }
}

// MARK: - Notifier Configuration Model

struct NotifierConfiguration: Equatable {
    var binaryPath: String = "/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier"
    var type: NotificationType = .alert
    var title: String = "Jamf Notifier"
    var subtitle: String = "Action Required"
    var message: String = "A required software update is ready to install on your Mac."
    
    // Primary Button
    var hasButton1: Bool = true
    var button1Label: String = "Install Now"
    var button1Action: String = "https://company.jamfcloud.com"
    
    // Secondary Button
    var hasButton2: Bool = true
    var button2Label: String = "Later"
    var button2Action: String = "logout"
    
    // Message Body Click Action
    var hasMessageAction: Bool = false
    var messageAction: String = "https://company.jamfcloud.com/help"
    
    // Dismiss Action (X button)
    var hasDismissAction: Bool = false
    var dismissAction: String = "/usr/bin/logger 'Notification dismissed by user'"
    
    // Sound
    var sound: SoundOption = .none
    var customSoundName: String = ""
    
    // Icon & Rebrand
    var selectedIcon: PresetIcon = .jamf
    var customRebrandPath: String = ""
    var enableRebrand: Bool = false
    var applyIconWorkaround: Bool = false
    
    // Removal & Verbose
    var removeMode: RemoveMode = .none
    var verbose: Bool = false
    
    // MARK: - Validation
    
    var effectiveSoundString: String {
        switch sound {
        case .none: return ""
        case .defaultSound: return "default"
        case .custom: return customSoundName.trimmingCharacters(in: .whitespacesAndNewlines)
        default: return sound.rawValue
        }
    }
    
    var effectiveRebrandPath: String {
        if selectedIcon == .custom {
            return customRebrandPath.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedIcon.defaultRebrandPath
    }
    
    var warnings: [String] {
        var issues: [String] = []
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && removeMode != .all {
            issues.append("Message is empty: Notifier requires a message body unless '--remove all' is used.")
        }
        if hasButton2 && !hasButton1 {
            issues.append("Secondary button is enabled without a primary button. Notifier requires '--messagebutton' if '--messagebutton2' is used.")
        }
        if hasButton1 && button1Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Primary button label is empty.")
        }
        if hasButton2 && button2Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Secondary button label is empty.")
        }
        
        let checkAction: (String, String) -> Void = { action, name in
            let trimmed = action.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed != "logout" && !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") && !trimmed.hasPrefix("/") {
                issues.append("\(name) '\(trimmed)' does not appear to be 'logout', a URL, or an absolute path (e.g. '/usr/bin/open').")
            }
        }
        
        if hasButton1 && !button1Action.isEmpty {
            checkAction(button1Action, "Button 1 action")
        }
        if hasButton2 && !button2Action.isEmpty {
            checkAction(button2Action, "Button 2 action")
        }
        if hasMessageAction && !messageAction.isEmpty {
            checkAction(messageAction, "Message body action")
        }
        if hasDismissAction && !dismissAction.isEmpty {
            checkAction(dismissAction, "Dismiss action")
        }
        if includesRebrand {
            let ext = (effectiveRebrandPath as NSString).pathExtension.lowercased()
            if ext != "png" && ext != "icns" {
                issues.append("Rebrand image should be a PNG or ICNS file.")
            }
        }
        return issues
    }
    
    // MARK: - Command Generation
    
    /// Builds raw arguments array suitable for Process() execution
    public func buildCommandLineArguments() -> [String] {
        var args: [String] = ["--type", type.rawValue]
        
        if removeMode == .all {
            args.append(contentsOf: ["--remove", "all"])
            if verbose { args.append("--verbose") }
            return args
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            args.append(contentsOf: ["--title", trimmedTitle])
        }
        
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSubtitle.isEmpty {
            args.append(contentsOf: ["--subtitle", trimmedSubtitle])
        }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            args.append(contentsOf: ["--message", trimmedMessage])
        }
        
        if hasButton1 && !button1Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(contentsOf: ["--messagebutton", button1Label.trimmingCharacters(in: .whitespacesAndNewlines)])
            if !button1Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                args.append(contentsOf: ["--messagebuttonaction", button1Action.trimmingCharacters(in: .whitespacesAndNewlines)])
            }
        }
        
        if hasButton1 && hasButton2 && !button2Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(contentsOf: ["--messagebutton2", button2Label.trimmingCharacters(in: .whitespacesAndNewlines)])
            if !button2Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                args.append(contentsOf: ["--messagebutton2action", button2Action.trimmingCharacters(in: .whitespacesAndNewlines)])
            }
        }
        
        if hasMessageAction && !messageAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(contentsOf: ["--messageaction", messageAction.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
        
        if hasDismissAction && !dismissAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args.append(contentsOf: ["--messagedismissaction", dismissAction.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
        
        let soundStr = effectiveSoundString
        if !soundStr.isEmpty {
            args.append(contentsOf: ["--sound", soundStr])
        }
        
        if removeMode == .prior {
            args.append(contentsOf: ["--remove", "prior"])
        }
        
        if verbose {
            args.append("--verbose")
        }
        
        return args
    }

    /// Generates a single-line shell command. When rebranding, the root-only
    /// `--rebrand` call is chained ahead of the notification command.
    func generateCommandLine() -> String {
        guard let rebrand = rebrandCommand(useSudo: true) else { return notificationCommandLine() }
        guard let workaround = iconWorkaround(useSudo: true) else { return "\(rebrand); \(notificationCommandLine())" }
        return "\(rebrand); \(workaround.singleLine); \(notificationCommandLine())"
    }
    
    /// Generates a readable multiline bash script format with backslashes
    func generateMultilineScript() -> String {
        guard let rebrand = rebrandCommand(useSudo: true) else { return notificationMultilineScript() }
        guard let workaround = iconWorkaround(useSudo: true) else { return "\(rebrand)\n\n\(notificationMultilineScript())" }
        return "\(rebrand)\n\n\(workaround.multiline)\n\n\(notificationMultilineScript())"
    }
    
    /// Notifier 4.x applies `--rebrand` and then exits without posting a notification,
    /// so rebranding must be issued as its own command (as root) before the notification.
    var includesRebrand: Bool {
        enableRebrand && !effectiveRebrandPath.isEmpty
    }
    
    /// Builds the standalone `--rebrand` command, or nil when rebranding is disabled.
    func rebrandCommand(useSudo: Bool) -> String? {
        guard includesRebrand else { return nil }
        var parts: [String] = []
        if useSudo { parts.append("/usr/bin/sudo") }
        parts.append(quotedExecutable)
        parts.append("--rebrand \"\(escapeForBash(effectiveRebrandPath))\"")
        if verbose { parts.append("--verbose") }
        return parts.joined(separator: " ")
    }
    
    /// Workaround for Notifier issue #34: from macOS 26.4, notifications ignore the Finder
    /// custom icon that `--rebrand` sets, because the helper apps declare `CFBundleIconName`
    /// (an asset catalog icon), which takes priority. For each helper this writes the image
    /// into `AppIcon.icns`, deletes `CFBundleIconName` so that `.icns` is used, ad-hoc re-signs
    /// the helper to reseal the modified bundle, and re-registers it with Launch Services.
    /// It then restarts the notification daemons so the new icon is picked up.
    func iconWorkaround(useSudo: Bool) -> (singleLine: String, multiline: String)? {
        guard includesRebrand && applyIconWorkaround else { return nil }
        let sudo = useSudo ? "/usr/bin/sudo " : ""
        let icon = escapeForBash(effectiveRebrandPath)
        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        
        let header = "for helper in \"\(escapeForBash(helpersDirectory))\"/*.app; do"
        // sips can't write ICNS above 512px, so the image is scaled to fit (-Z 512)
        let body = [
            "\(sudo)/usr/bin/sips -s format icns -Z 512 \"\(icon)\" --out \"$helper/Contents/Resources/AppIcon.icns\" >/dev/null",
            "\(sudo)/usr/libexec/PlistBuddy -c \"Delete :CFBundleIconName\" \"$helper/Contents/Info.plist\" 2>/dev/null",
            "\(sudo)/usr/bin/codesign --force --sign - --preserve-metadata=entitlements,flags,runtime \"$helper\"",
            "\(sudo)\(lsregister) -f \"$helper\""
        ]
        let restart = "\(sudo)/usr/bin/killall usernoted NotificationCenter 2>/dev/null"
        
        let singleLine = "\(header) \(body.joined(separator: "; ")); done; \(restart)"
        let multiline = ([
            "# Workaround for macOS 26.4+ ignoring rebranded icons (Notifier issue #34)",
            header
        ] + body.map { "    \($0)" } + ["done", restart]).joined(separator: "\n")
        return (singleLine, multiline)
    }
    
    /// Folder holding Notifier's Alerts and Notifications helper apps
    private var helpersDirectory: String {
        let exec = binaryPath.isEmpty ? "/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier" : binaryPath
        if let range = exec.range(of: "/Contents/MacOS/") {
            return String(exec[..<range.lowerBound]) + "/Contents/Helpers"
        }
        return "/Applications/Utilities/Notifier.app/Contents/Helpers"
    }
    
    private var quotedExecutable: String {
        let exec = binaryPath.isEmpty ? "/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier" : binaryPath
        return exec.contains(" ") ? "\"\(exec)\"" : exec
    }
    
    /// Single-line notification command, excluding `--rebrand`
    private func notificationCommandLine() -> String {
        var parts: [String] = []
        let exec = binaryPath.isEmpty ? "/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier" : binaryPath
        parts.append(exec.contains(" ") ? "\"\(exec)\"" : exec)
        
        parts.append("--type \(type.rawValue)")
        
        if removeMode == .all {
            parts.append("--remove all")
            if verbose { parts.append("--verbose") }
            return parts.joined(separator: " ")
        }
        
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--title \"\(escapeForBash(title))\"")
        }
        
        if !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--subtitle \"\(escapeForBash(subtitle))\"")
        }
        
        if !message.isEmpty {
            parts.append("--message \"\(escapeForBash(message))\"")
        }
        
        if hasButton1 && !button1Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--messagebutton \"\(escapeForBash(button1Label))\"")
            if !button1Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("--messagebuttonaction \"\(escapeForBash(button1Action))\"")
            }
        }
        
        if hasButton1 && hasButton2 && !button2Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--messagebutton2 \"\(escapeForBash(button2Label))\"")
            if !button2Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("--messagebutton2action \"\(escapeForBash(button2Action))\"")
            }
        }
        
        if hasMessageAction && !messageAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--messageaction \"\(escapeForBash(messageAction))\"")
        }
        
        if hasDismissAction && !dismissAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("--messagedismissaction \"\(escapeForBash(dismissAction))\"")
        }
        
        let soundStr = effectiveSoundString
        if !soundStr.isEmpty {
            parts.append("--sound \"\(escapeForBash(soundStr))\"")
        }
        
        if removeMode == .prior {
            parts.append("--remove prior")
        }
        
        if verbose {
            parts.append("--verbose")
        }
        
        return parts.joined(separator: " ")
    }
    
    /// Multiline notification command, excluding `--rebrand`
    private func notificationMultilineScript() -> String {
        var lines: [String] = []
        let exec = binaryPath.isEmpty ? "/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier" : binaryPath
        let execLine = exec.contains(" ") ? "\"\(exec)\"" : exec
        lines.append("\(execLine) \\")
        lines.append("    --type \(type.rawValue) \\")
        
        if removeMode == .all {
            lines.append("    --remove all" + (verbose ? " \\" : ""))
            if verbose { lines.append("    --verbose") }
            return lines.joined(separator: "\n")
        }
        
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --title \"\(escapeForBash(title))\" \\")
        }
        if !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --subtitle \"\(escapeForBash(subtitle))\" \\")
        }
        if !message.isEmpty {
            lines.append("    --message \"\(escapeForBash(message))\" \\")
        }
        if hasButton1 && !button1Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --messagebutton \"\(escapeForBash(button1Label))\" \\")
            if !button1Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("    --messagebuttonaction \"\(escapeForBash(button1Action))\" \\")
            }
        }
        if hasButton1 && hasButton2 && !button2Label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --messagebutton2 \"\(escapeForBash(button2Label))\" \\")
            if !button2Action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("    --messagebutton2action \"\(escapeForBash(button2Action))\" \\")
            }
        }
        if hasMessageAction && !messageAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --messageaction \"\(escapeForBash(messageAction))\" \\")
        }
        if hasDismissAction && !dismissAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("    --messagedismissaction \"\(escapeForBash(dismissAction))\" \\")
        }
        let soundStr = effectiveSoundString
        if !soundStr.isEmpty {
            lines.append("    --sound \"\(escapeForBash(soundStr))\" \\")
        }
        if removeMode == .prior {
            lines.append("    --remove prior \\")
        }
        if verbose {
            lines.append("    --verbose \\")
        }
        
        // Remove trailing backslash on last item
        if var last = lines.popLast() {
            if last.hasSuffix(" \\") {
                last = String(last.dropLast(2))
            }
            lines.append(last)
        }
        return lines.joined(separator: "\n")
    }
    
    /// Generates a complete Jamf Pro / MDM Policy Shell Script template
    func generateJamfScript() -> String {
        return """
        #!/bin/zsh
        # ==============================================================================
        # Jamf Pro Notification Deployment Script
        # Generated by Notifier Builder Previewer
        # ==============================================================================

        NOTIFIER="/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier"

        if [[ ! -x "$NOTIFIER" ]]; then
            echo "Error: Notifier binary not found at $NOTIFIER"
            exit 1
        fi

        \(jamfRebrandStep)echo "Posting \(type.rawValue) notification to current user..."

        \(notificationMultilineScript())

        EXIT_CODE=$?
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "Notification dispatched successfully."
        else
            echo "Failed to dispatch notification. Code: $EXIT_CODE"
        fi
        exit $EXIT_CODE
        """
    }
    
    /// Rebrand block for the Jamf script. Policies run as root, so sudo isn't needed.
    private var jamfRebrandStep: String {
        guard let rebrand = rebrandCommand(useSudo: false) else { return "" }
        let workaround = iconWorkaround(useSudo: false).map { "\n\n\($0.multiline)" } ?? ""
        return """
        echo "Rebranding Notifier..."
        \(rebrand)\(workaround)

        
        """
    }
    
    private func escapeForBash(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
    }
    
    // MARK: - Command Parsing
    
    /// Parses an inputted command or script string back into a NotifierConfiguration
    static func parse(command: String) -> (config: NotifierConfiguration, parseNotes: [String]) {
        var config = NotifierConfiguration()
        var notes: [String] = []
        
        let cleaned = command
            .replacingOccurrences(of: "\\\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else {
            notes.append("Empty command string provided.")
            return (config, notes)
        }
        
        let tokens = tokenize(command: cleaned)
        guard !tokens.isEmpty else {
            notes.append("No arguments found to parse.")
            return (config, notes)
        }
        
        var idx = 0
        
        // Reset defaults before parsing flags
        config.title = ""
        config.subtitle = ""
        config.message = ""
        config.hasButton1 = false
        config.button1Label = ""
        config.button1Action = ""
        config.hasButton2 = false
        config.button2Label = ""
        config.button2Action = ""
        config.hasMessageAction = false
        config.messageAction = ""
        config.hasDismissAction = false
        config.dismissAction = ""
        config.sound = .none
        config.customSoundName = ""
        config.enableRebrand = false
        config.applyIconWorkaround = false
        config.removeMode = .none
        config.verbose = false
        
        // True at the start of each command (start of input, or after ';' / '&&'),
        // where the next non-flag token is sudo or the Notifier binary path.
        var atCommandStart = true
        // True while skipping a non-Notifier command (shell keywords, echo, the icon workaround...)
        var skippingCommand = false
        let separators: Set<String> = [";", "&&", "||", "|"]
        
        while idx < tokens.count {
            var token = tokens[idx]
            
            if separators.contains(token) {
                atCommandStart = true
                skippingCommand = false
                idx += 1
                continue
            }
            
            if token == "CFBundleIconName" || token == "Delete :CFBundleIconName" {
                config.applyIconWorkaround = true
            }
            
            // A trailing ';' ends the current command, e.g. `--message "hi";`
            var endsCommand = false
            if token.hasSuffix(";") && token.count > 1 {
                token = String(token.dropLast())
                endsCommand = true
            }
            
            if skippingCommand {
                idx += 1
                if endsCommand {
                    atCommandStart = true
                    skippingCommand = false
                }
                continue
            }
            
            if atCommandStart && !token.hasPrefix("-") {
                let name = (token as NSString).lastPathComponent.lowercased()
                if name != "sudo" {
                    if name.contains("notifier") {
                        config.binaryPath = token
                    } else {
                        // Some other command; ignore its arguments
                        skippingCommand = true
                    }
                    atCommandStart = false
                }
                idx += 1
                if endsCommand {
                    atCommandStart = true
                    skippingCommand = false
                }
                continue
            }
            atCommandStart = false
            
            let nextVal: () -> String? = {
                if !endsCommand && idx + 1 < tokens.count && !tokens[idx + 1].hasPrefix("-") && tokens[idx + 1] != ";" && tokens[idx + 1] != "&&" {
                    idx += 1
                    let value = tokens[idx]
                    if value.hasSuffix(";") {
                        endsCommand = true
                        return String(value.dropLast())
                    }
                    return value
                }
                return nil
            }
            
            switch token.lowercased() {
            case "--type":
                if let val = nextVal()?.lowercased() {
                    config.type = (val == "banner") ? .banner : .alert
                }
            case "--title":
                if let val = nextVal() {
                    config.title = val
                }
            case "--subtitle":
                if let val = nextVal() {
                    config.subtitle = val
                }
            case "--message":
                if let val = nextVal() {
                    config.message = val
                }
            case "--messagebutton":
                if let val = nextVal() {
                    config.hasButton1 = true
                    config.button1Label = val
                }
            case "--messagebuttonaction":
                if let val = nextVal() {
                    config.button1Action = val
                }
            case "--messagebutton2":
                if let val = nextVal() {
                    config.hasButton2 = true
                    config.button2Label = val
                }
            case "--messagebutton2action":
                if let val = nextVal() {
                    config.button2Action = val
                }
            case "--messageaction":
                if let val = nextVal() {
                    config.hasMessageAction = true
                    config.messageAction = val
                }
            case "--dismissaction", "--messagedismissaction":
                if let val = nextVal() {
                    config.hasDismissAction = true
                    config.dismissAction = val
                }
            case "--sound":
                if let val = nextVal() {
                    if val.lowercased() == "default" {
                        config.sound = .defaultSound
                    } else if let matched = SoundOption.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(val) == .orderedSame && $0 != .custom }) {
                        config.sound = matched
                    } else {
                        config.sound = .custom
                        config.customSoundName = val
                    }
                }
            case "--rebrand":
                if let val = nextVal() {
                    config.enableRebrand = true
                    config.selectedIcon = .custom
                    config.customRebrandPath = val
                }
            case "--remove":
                if let val = nextVal()?.lowercased() {
                    if val == "all" {
                        config.removeMode = .all
                    } else if val == "prior" {
                        config.removeMode = .prior
                    }
                }
            case "--verbose":
                config.verbose = true
            default:
                if token.hasPrefix("--") {
                    notes.append("Unrecognized option: \(token)")
                }
            }
            if endsCommand || tokens[idx].hasSuffix(";") { atCommandStart = true }
            idx += 1
        }
        
        notes.append("Parsed successfully: Type=\(config.type.rawValue), Title=\"\(config.title)\", Buttons=\(config.hasButton1 ? "Yes" : "No")")
        return (config, notes)
    }
    
    /// Tokenizes shell command string taking into account quotes and escapes
    private static func tokenize(command: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var inDoubleQuotes = false
        var inSingleQuotes = false
        var isEscaped = false
        
        for char in command {
            if isEscaped {
                currentToken.append(char)
                isEscaped = false
                continue
            }
            
            if char == "\\" && !inSingleQuotes {
                isEscaped = true
                continue
            }
            
            if char == "\"" && !inSingleQuotes {
                inDoubleQuotes.toggle()
                continue
            }
            
            if char == "'" && !inDoubleQuotes {
                inSingleQuotes.toggle()
                continue
            }
            
            if char.isWhitespace && !inDoubleQuotes && !inSingleQuotes {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
                // An unquoted newline ends a shell command
                if char.isNewline {
                    tokens.append(";")
                }
                continue
            }
            
            currentToken.append(char)
        }
        
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        
        return tokens
    }
}

// MARK: - Preset Examples from Documentation

struct NotifierPreset: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let category: String
    let config: NotifierConfiguration
}

struct PresetLibrary {
    static let examples: [NotifierPreset] = [
        NotifierPreset(
            title: "Example 1: Basic Banner",
            subtitle: "Temporary banner with standard body text",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .banner
                c.title = "Notifier"
                c.subtitle = ""
                c.message = "Hello, your backup has completed successfully."
                c.hasButton1 = false
                c.hasButton2 = false
                c.sound = .defaultSound
                return c
            }()
        ),
        NotifierPreset(
            title: "Example 2: Alert with Logout",
            subtitle: "Persistent alert with Logout button & action",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "Notifier"
                c.subtitle = ""
                c.message = "Please log out to apply critical security updates."
                c.hasButton1 = true
                c.button1Label = "Logout"
                c.button1Action = "logout"
                c.hasButton2 = false
                c.sound = .defaultSound
                return c
            }()
        ),
        NotifierPreset(
            title: "Example 3: Interactive Alert + Web Link",
            subtitle: "Alert with Primary action URL and secondary cancel",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "Action Required"
                c.subtitle = "Enrollment Portal"
                c.message = "Your device requires compliance re-verification within 24 hours."
                c.hasButton1 = true
                c.button1Label = "Verify Device"
                c.button1Action = "https://support.apple.com"
                c.hasButton2 = true
                c.button2Label = "Later"
                c.button2Action = "/usr/bin/logger 'Postponed'"
                c.sound = .glass
                return c
            }()
        ),
        NotifierPreset(
            title: "Example 4: Rebranded Icon Alert",
            subtitle: "Notification using custom ICNS rebranding",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "Jamf Pro Agent"
                c.subtitle = "Self Service"
                c.message = "New software catalog items are available for your device."
                c.hasButton1 = true
                c.button1Label = "Open Catalog"
                c.button1Action = "/usr/bin/open -a 'App Store'"
                c.hasButton2 = false
                c.enableRebrand = true
                c.selectedIcon = .update
                c.sound = .hero
                return c
            }()
        ),
        NotifierPreset(
            title: "Example 5: Selective Remove Prior",
            subtitle: "Clears matching earlier notification",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "Look at me!!"
                c.subtitle = ""
                c.message = "Look at me!!"
                c.removeMode = .prior
                c.hasButton1 = false
                c.hasButton2 = false
                return c
            }()
        ),
        NotifierPreset(
            title: "Example 6: Remove All Delivered",
            subtitle: "Dismisses all alert notifications from Notification Center",
            category: "Docs Examples",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.removeMode = .all
                return c
            }()
        ),
        NotifierPreset(
            title: "IT Alert: macOS Software Update",
            subtitle: "Enterprise MDM OS update deadline banner",
            category: "Enterprise IT",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "macOS Software Update"
                c.subtitle = "Security Enforcement"
                c.message = "A critical security update must be installed. Please restart your Mac today."
                c.hasButton1 = true
                c.button1Label = "Install & Restart"
                c.button1Action = "/usr/bin/open 'x-apple.systempreferences:com.apple.Software-Update-Settings.extension'"
                c.hasButton2 = true
                c.button2Label = "Remind in 1h"
                c.button2Action = "/usr/bin/logger 'User snoozed macOS update'"
                c.hasMessageAction = true
                c.messageAction = "https://support.apple.com/en-us/HT201222"
                c.sound = .ping
                c.selectedIcon = .restart
                return c
            }()
        ),
        NotifierPreset(
            title: "IT Alert: Password Expiration",
            subtitle: "Corporate directory credential expiry",
            category: "Enterprise IT",
            config: {
                var c = NotifierConfiguration()
                c.type = .alert
                c.title = "Enterprise Directory"
                c.subtitle = "Password Expiring"
                c.message = "Your password will expire in 3 days. Update now to avoid lockouts."
                c.hasButton1 = true
                c.button1Label = "Change Password"
                c.button1Action = "https://identity.company.com/reset"
                c.hasButton2 = true
                c.button2Label = "Dismiss"
                c.button2Action = "/usr/bin/logger 'Password banner dismissed'"
                c.sound = .sosumi
                c.selectedIcon = .security
                return c
            }()
        )
    ]
}
