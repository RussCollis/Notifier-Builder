import SwiftUI
import AppKit

// MARK: - Blueprint Background

/// Blueprint grid wallpaper used behind the simulated notification.
struct BlueprintBackground: View {
    var body: some View {
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

// MARK: - Notification Preview Card

struct NotificationPreviewCard: View {
    @Binding var config: NotifierConfiguration
    @Binding var previewColorFilter: ColorScheme?
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
                BlueprintBackground()
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Authentic Notification Card
    
    /// macOS keeps action buttons hidden until the pointer hovers over the notification.
    private var showsActionButtons: Bool {
        (hasVisibleButton1 || hasVisibleButton2) && isHovering
    }
    
    private var hasVisibleButton1: Bool {
        config.hasButton1 && !config.button1Label.isEmpty
    }
    
    private var hasVisibleButton2: Bool {
        config.hasButton2 && !config.button2Label.isEmpty
    }
    
    /// Mirrors the macOS banner layout: app icon on the left, title and message beside it,
    /// and action buttons stacked on the trailing edge.
    private var notificationCard: some View {
        HStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                appIconView
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(config.title.isEmpty ? "Notifier" : config.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Subtitle (if present)
                    if !config.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(config.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    // Body Message
                    if !config.message.isEmpty {
                        Text(config.message)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                    } else if config.removeMode == .all {
                        Text("[Clearing all delivered notifications]")
                            .font(.system(size: 12))
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                handleBodyClicked()
            }
            
            // Hover action: a single button shows its label, two buttons collapse into an "Options" menu
            if showsActionButtons {
                Group {
                    if hasVisibleButton1 && hasVisibleButton2 {
                        Menu {
                            Button(config.button1Label, action: handleButton1Clicked)
                            Button(config.button2Label, action: handleButton2Clicked)
                        } label: {
                            hoverPill(title: "Options", showsChevron: true)
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .help("\(config.button1Label): \(config.button1Action)\n\(config.button2Label): \(config.button2Action)")
                    } else if hasVisibleButton1 {
                        Button(action: handleButton1Clicked) {
                            hoverPill(title: config.button1Label, showsChevron: false)
                        }
                        .buttonStyle(.plain)
                        .help("Triggers: \(config.button1Action)")
                    } else {
                        Button(action: handleButton2Clicked) {
                            hoverPill(title: config.button2Label, showsChevron: false)
                        }
                        .buttonStyle(.plain)
                        .help("Triggers: \(config.button2Action)")
                    }
                }
                .padding(.trailing, 12)
                .transition(.opacity)
            }
        }
        .frame(width: 350)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        // Dismiss 'X' Button sits on the top-left corner on hover, as on macOS
        .overlay(alignment: .topLeading) {
            if isHovering {
                Button {
                    handleDismissClicked()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 20, height: 20)
                        Circle()
                            .fill(isHoveringDismiss ? Color.primary.opacity(0.15) : Color.clear)
                            .frame(width: 20, height: 20)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .offset(x: -7, y: -7)
                .onHover { isHoveringDismiss = $0 }
                .help(config.hasDismissAction ? "Dismiss: \(config.dismissAction)" : "Dismiss notification")
            }
        }
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    private func hoverPill(title: String, showsChevron: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.primary.opacity(0.1)))
        .contentShape(Capsule())
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
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Fallback to preset SF Symbol
                    ZStack {
                        LinearGradient(
                            colors: [Color.accentColor, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: config.selectedIcon.systemSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
