import SwiftUI
import AppKit

enum CodeOutputFormat: String, CaseIterable, Identifiable {
    case singleLine = "CLI Command"
    case multiline = "Shell Script"
    case jamfPolicy = "Jamf Pro Script"
    
    var id: String { rawValue }
}

enum LiveTestMode: String, CaseIterable, Identifiable {
    case systemNotification = "System Notification"
    case jamfBinary = "Jamf Notifier CLI"
    
    var id: String { rawValue }
}

struct CodeInspectorView: View {
    @Binding var config: NotifierConfiguration
    @State private var inputCode: String = ""
    @State private var selectedTab: CodeOutputFormat = .singleLine
    @State private var testMode: LiveTestMode = .systemNotification
    @State private var hasCopied = false
    @State private var parseStatusMessage: String? = nil
    
    // Live Dispatch Feedback State
    @State private var isExecuting = false
    @State private var executionResult: LiveExecutionResult? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Presets & Live Test Dispatcher
            headerToolbar
            
            // Execution Status Banner (shows instantly when button is clicked)
            if let result = executionResult {
                executionFeedbackBanner(result: result)
            }
            
            Divider()
            
            // Two-Way Code Area: Code Input on top, Generated Output on bottom
            VStack(spacing: 12) {
                // Section A: Paste / Input Code to Preview
                inputCodeSection
                
                Divider()
                
                // Section B: Live Generated Code
                outputCodeSection
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Toolbar
    
    private var headerToolbar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "curlybraces")
                    .foregroundColor(.accentColor)
                Text("Code Inspector & Generator")
                    .font(.system(size: 13, weight: .bold))
            }
            
            Spacer()
            
            // Presets Menu
            Menu {
                Section("Documentation Examples") {
                    ForEach(PresetLibrary.examples.filter { $0.category == "Docs Examples" }) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(preset.title)
                                Text(preset.subtitle)
                            }
                        }
                    }
                }
                
                Section("Enterprise MDM Templates") {
                    ForEach(PresetLibrary.examples.filter { $0.category == "Enterprise IT" }) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(preset.title)
                                Text(preset.subtitle)
                            }
                        }
                    }
                }
            } label: {
                Label("Load Example...", systemImage: "book.pages")
                    .font(.system(size: 11))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)
            
            // Live Dispatch Options
            Picker("Mode:", selection: $testMode) {
                Text("System Notification").tag(LiveTestMode.systemNotification)
                Text("Run Notifier CLI").tag(LiveTestMode.jamfBinary)
            }
            .pickerStyle(.menu)
            .font(.system(size: 11))
            .frame(maxWidth: 160)
            
            // Post Live Test Button
            Button {
                dispatchLiveNotification()
            } label: {
                HStack(spacing: 5) {
                    if isExecuting {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text("Post Live Test")
                }
                .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isExecuting)
            .help("Triggers an actual native macOS notification on this Mac")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Execution Feedback Banner
    
    @ViewBuilder
    private func executionFeedbackBanner(result: LiveExecutionResult) -> some View {
        HStack(alignment: .center, spacing: 10) {
            switch result {
            case .success(let message):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text(message)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                
            case .warning(let message, let showsSettingsButton):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                Text(message)
                    .font(.system(size: 11.5))
                    .foregroundColor(.primary)
                Spacer()
                if showsSettingsButton {
                    Button("Open System Settings") {
                        LiveNotificationRunner.shared.openNotificationSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                Text(message)
                    .font(.system(size: 11.5))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Button {
                withAnimation {
                    executionResult = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ZStack {
                switch result {
                case .success: Color.green.opacity(0.12)
                case .warning: Color.orange.opacity(0.15)
                case .failure: Color.red.opacity(0.12)
                }
            }
        )
        .overlay(
            Rectangle()
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Section A: Code Input (Parse to Preview)
    
    private var inputCodeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Input / Paste Command to Preview", systemImage: "arrow.down.doc.fill")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let msg = parseStatusMessage {
                    Text(msg)
                        .font(.system(size: 10.5))
                        .foregroundColor(.green)
                }
                
                Button {
                    parseEnteredCode()
                } label: {
                    Label("Parse to Preview", systemImage: "sparkles")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(inputCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            TextField("Paste any Notifier command here (e.g. --type alert --message \"Hello\" --messagebutton \"OK\")...", text: $inputCode)
                .font(.system(size: 11, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    parseEnteredCode()
                }
        }
    }
    
    // MARK: - Section B: Generated Code Output
    
    private var outputCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(CodeOutputFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                
                Spacer()
                
                // Copy Button
                Button {
                    copyActiveCode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(hasCopied ? .green : .primary)
                        Text(hasCopied ? "Copied!" : "Copy")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Code Display Box
            ScrollView([.horizontal, .vertical]) {
                Text(activeCodeString)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 85, maxHeight: 120)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helpers & Actions
    
    private var activeCodeString: String {
        switch selectedTab {
        case .singleLine:
            return config.generateCommandLine()
        case .multiline:
            return config.generateMultilineScript()
        case .jamfPolicy:
            return config.generateJamfScript()
        }
    }
    
    private func copyActiveCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(activeCodeString, forType: .string)
        withAnimation {
            hasCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                hasCopied = false
            }
        }
    }
    
    private func parseEnteredCode() {
        let (parsedConfig, notes) = NotifierConfiguration.parse(command: inputCode)
        config = parsedConfig
        parseStatusMessage = "Updated from command!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            parseStatusMessage = nil
        }
    }
    
    private func applyPreset(_ preset: NotifierPreset) {
        config = preset.config
        inputCode = config.generateCommandLine()
        parseStatusMessage = "Loaded \(preset.title)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            parseStatusMessage = nil
        }
    }
    
    private func dispatchLiveNotification() {
        isExecuting = true
        executionResult = nil
        
        switch testMode {
        case .systemNotification:
            LiveNotificationRunner.shared.postSystemNotification(config: config) { result in
                withAnimation {
                    self.isExecuting = false
                    self.executionResult = result
                }
            }
        case .jamfBinary:
            LiveNotificationRunner.shared.runJamfNotifierBinary(config: config) { result in
                withAnimation {
                    self.isExecuting = false
                    self.executionResult = result
                }
            }
        }
    }
}
