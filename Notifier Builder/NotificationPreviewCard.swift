import SwiftUI
import AppKit

// MARK: - Wallpaper Theme

enum WallpaperTheme: String, CaseIterable, Identifiable {
    case sonoma = "Sonoma Gradient"
    case sequoia = "Sequoia Forest"
    case midnight = "Midnight Dark"
    case graphite = "Graphite Minimal"
    case blueprint = "Blueprint Grid"
    
    var id: String { rawValue }
    
    @ViewBuilder
    var backgroundView: some View {
        switch self {
        case .sonoma:
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.55, blue: 0.35), Color(red: 0.85, green: 0.25, blue: 0.45), Color(red: 0.35, green: 0.15, blue: 0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sequoia:
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.25, blue: 0.2), Color(red: 0.15, green: 0.4, blue: 0.3), Color(red: 0.05, green: 0.15, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .midnight:
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.1, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .graphite:
            LinearGradient(
                colors: [Color(white: 0.25), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .blueprint:
            ZStack {
                Color(red: 0.06, green: 0.18, blue: 0.36)
                // Grid overlay
                Canvas { context, size in
                    var path = Path()
                    let step: CGFloat = 20
                    for x in stride(from: 0, through: size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: 0, through: size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Notification Preview Card

struct NotificationPreviewCard: View {
    @Binding var config: NotifierConfiguration
    @Binding var previewColorFilter: ColorScheme?
    @State private var wallpaper: WallpaperTheme = .sonoma
    @State private var isHovering = false
    @State private var isHoveringDismiss = false
    @State private var actionFeedbackMessage: String? = nil
    @State private var feedbackTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview Header Bar
            previewToolbar
            
            // Preview Canvas (simulating macOS Desktop Corner)
            ZStack(alignment: .topTrailing) {
                // Simulated Desktop Wallpaper
                wallpaper.backgroundView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Menubar Simulation Strip
                VStack(spacing: 0) {
                    simulatedMenuBar
                    Spacer()
                }
                
                // The Notification Center Card (positioned top-right as on real macOS)
                VStack(alignment: .trailing, spacing: 12) {
                    notificationCard
                        .padding(.top, 40)
                        .padding(.trailing, 20)
                        .padding(.leading, 20)
                    
                    if let feedback = actionFeedbackMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feedback)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.trailing, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Simulated Menu Bar
    
    private var simulatedMenuBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "applelogo")
                .font(.system(size: 11, weight: .bold))
            Text("Finder")
                .font(.system(size: 11, weight: .bold))
            Text("File")
                .font(.system(size: 11))
            Text("Edit")
                .font(.system(size: 11))
            Text("View")
                .font(.system(size: 11))
            Text("Window")
                .font(.system(size: 11))
            Text("Help")
                .font(.system(size: 11))
            
            Spacer()
            
            Image(systemName: "wifi")
                .font(.system(size: 10))
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
            Image(systemName: "switch.2")
                .font(.system(size: 10))
            Text("9:41 AM")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Preview Toolbar
    
    private var previewToolbar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "macwindow")
                    .foregroundColor(.accentColor)
                Text("macOS Live Notification Preview")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            Spacer()
            
            // Type Pill
            Text(config.type.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(config.type == .alert ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                .foregroundColor(config.type == .alert ? .blue : .orange)
                .clipShape(Capsule())
            
            // Sound preview button
            Button {
                config.sound.play()
                triggerFeedback("Sound '\(config.effectiveSoundString)' played")
            } label: {
                Label("Audition Sound", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Wallpaper Theme Picker
            Menu {
                ForEach(WallpaperTheme.allCases) { theme in
                    Button {
                        wallpaper = theme
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                            if wallpaper == theme {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(wallpaper.rawValue, systemImage: "photo")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Authentic Notification Card
    
    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dismiss (X) button hover layer and Content
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    // Header: Icon + App Name + Timestamp
                    HStack(spacing: 8) {
                        // App / Rebrand Icon
                        appIconView
                        
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(config.title.isEmpty ? "Notifier" : config.title)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("now")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Subtitle (if present)
                    if !config.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(config.subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Body Message
                    if !config.message.isEmpty {
                        Text(config.message)
                            .font(.system(size: 12.5))
                            .foregroundColor(.primary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if config.removeMode == .all {
                        Text("[Clearing all delivered notifications]")
                            .font(.system(size: 12, weight: .regular))
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                
                // Dismiss 'X' Button (simulating macOS close action)
                if isHovering || config.hasDismissAction {
                    Button {
                        handleDismissClicked()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isHoveringDismiss ? Color.primary.opacity(0.18) : Color.primary.opacity(0.08))
                                .frame(width: 18, height: 18)
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(.primary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .onHover { isHoveringDismiss = $0 }
                    .help(config.hasDismissAction ? "Dismiss: \(config.dismissAction)" : "Dismiss notification")
                }
            }
            
            // Action Buttons Row (for Alert style or configured buttons)
            if config.hasButton1 || config.hasButton2 {
                Divider()
                    .opacity(0.4)
                
                HStack(spacing: 8) {
                    Spacer()
                    
                    // Button 2 (Secondary Action)
                    if config.hasButton2 && !config.button2Label.isEmpty {
                        Button {
                            handleButton2Clicked()
                        } label: {
                            Text(config.button2Label)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help("Triggers: \(config.button2Action)")
                    }
                    
                    // Button 1 (Primary Action)
                    if config.hasButton1 && !config.button1Label.isEmpty {
                        Button {
                            handleButton1Clicked()
                        } label: {
                            Text(config.button1Label)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .help("Triggers: \(config.button1Action)")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.02))
            }
        }
        .frame(width: 350)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        .contentShape(Rectangle())
        .onTapGesture {
            handleBodyClicked()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - App Icon View
    
    private var appIconView: some View {
        ZStack {
            if config.enableRebrand && !config.effectiveRebrandPath.isEmpty {
                // If it's a file path that exists on Mac
                if let nsImage = NSImage(contentsOfFile: config.effectiveRebrandPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    // Fallback to preset SF Symbol
                    ZStack {
                        LinearGradient(
                            colors: [Color.accentColor, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: config.selectedIcon.systemSymbol)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                // Default Jamf / Notifier Icon
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.89, green: 0.15, blue: 0.45), Color(red: 0.55, green: 0.05, blue: 0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Interactive Action Handlers
    
    private func handleButton1Clicked() {
        let act = config.button1Action.isEmpty ? "(No action specified)" : config.button1Action
        triggerFeedback("Clicked '\(config.button1Label)' → Action: \(act)")
    }
    
    private func handleButton2Clicked() {
        let act = config.button2Action.isEmpty ? "(No action specified)" : config.button2Action
        triggerFeedback("Clicked '\(config.button2Label)' → Action: \(act)")
    }
    
    private func handleBodyClicked() {
        if config.hasMessageAction && !config.messageAction.isEmpty {
            triggerFeedback("Notification body clicked → Action: \(config.messageAction)")
        } else {
            triggerFeedback("Notification body clicked (no --messageaction)")
        }
    }
    
    private func handleDismissClicked() {
        if config.hasDismissAction && !config.dismissAction.isEmpty {
            triggerFeedback("Dismiss (X) clicked → Action: \(config.dismissAction)")
        } else {
            triggerFeedback("Notification dismissed via (X)")
        }
    }
    
    private func triggerFeedback(_ msg: String) {
        feedbackTimer?.invalidate()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            actionFeedbackMessage = msg
        }
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                actionFeedbackMessage = nil
            }
        }
    }
}
