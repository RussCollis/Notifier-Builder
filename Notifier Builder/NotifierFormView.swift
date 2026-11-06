import SwiftUI

struct NotifierFormView: View {
    @Binding var config: NotifierConfiguration
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Validation Warnings banner if any
                if !config.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(config.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 13))
                                Text(warning)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Section 1: Notification Style (Alert vs Banner)
                notificationStyleSection
                
                // Section 2: Text Content
                textContentSection
                
                // Section 3: Interactive Buttons (Checkboxes & Radios)
                buttonsSection
                
                // Section 4: Interaction Actions (Click & Dismiss)
                interactionsSection
                
                // Section 5: Audio & Sound
                soundSection
                
                // Section 6: Icon & Rebranding
                rebrandSection
                
                // Section 7: Advanced / Removal & Debug
                advancedSection
            }
            .padding(18)
        }
    }
    
    // MARK: - Section 1: Notification Style
    
    private var notificationStyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notification Type", systemImage: "bell.badge")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            HStack(spacing: 12) {
                // Radio button 1: Alert
                Button {
                    config.type = .alert
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: config.type == .alert ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 15))
                            .foregroundColor(config.type == .alert ? .accentColor : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Alert (--type alert)")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Persistent. Stays visible until user clicks an action or dismisses.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(config.type == .alert ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(config.type == .alert ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Radio button 2: Banner
                Button {
                    config.type = .banner
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: config.type == .banner ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 15))
                            .foregroundColor(config.type == .banner ? .accentColor : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Banner (--type banner)")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Temporary. Slides in top-right and auto-dismisses after a few seconds.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(config.type == .banner ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(config.type == .banner ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 2: Text Content
    
    private var textContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notification Text Content", systemImage: "text.alignleft")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            // Title
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Title (--title):")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("Defaults to App Name if empty")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
                TextField("e.g. Jamf Notifier or IT Support", text: $config.title)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("Subtitle (--subtitle):")
                    .font(.system(size: 12, weight: .medium))
                TextField("e.g. Action Required or Scheduled Restart", text: $config.subtitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Message Body
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Message Body (--message):")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(config.message.count) characters")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }
                TextEditor(text: $config.message)
                    .font(.system(size: 12))
                    .frame(height: 65)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 3: Interactive Buttons (Checkboxes & Radios)
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Interactive Notification Buttons", systemImage: "hand.tap.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            // Button 1 Checkbox
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $config.hasButton1) {
                    HStack(spacing: 6) {
                        Text("Enable Primary Action Button")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("(--messagebutton)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                
                if config.hasButton1 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Button Label:")
                                    .font(.system(size: 11, weight: .medium))
                                TextField("e.g. Install Now, Logout, Open", text: $config.button1Label)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .frame(maxWidth: 160)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Action (--messagebuttonaction):")
                                    .font(.system(size: 11, weight: .medium))
                                TextField("e.g. 'logout', https://... or /usr/bin/open", text: $config.button1Action)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        // Quick Action Presets
                        HStack(spacing: 6) {
                            Text("Presets:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Button("Logout") {
                                config.button1Label = "Logout"
                                config.button1Action = "logout"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            
                            Button("Web Portal") {
                                config.button1Action = "https://company.jamfcloud.com"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            
                            Button("Software Update") {
                                config.button1Action = "/usr/bin/open 'x-apple.systempreferences:com.apple.Software-Update-Settings.extension'"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                    }
                    .padding(.leading, 22)
                }
            }
            .padding(10)
            .background(config.hasButton1 ? Color.accentColor.opacity(0.04) : Color.clear)
            .cornerRadius(8)
            
            Divider()
            
            // Button 2 Checkbox
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $config.hasButton2) {
                    HStack(spacing: 6) {
                        Text("Enable Secondary Action Button")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text("(--messagebutton2)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                .disabled(!config.hasButton1)
                
                if !config.hasButton1 {
                    Text("Requires Primary Button to be enabled first.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .padding(.leading, 22)
                } else if config.hasButton2 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Button 2 Label:")
                                    .font(.system(size: 11, weight: .medium))
                                TextField("e.g. Later, Remind Me", text: $config.button2Label)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .frame(maxWidth: 160)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Action (--messagebutton2action):")
                                    .font(.system(size: 11, weight: .medium))
                                TextField("e.g. /usr/bin/logger 'Postponed'", text: $config.button2Action)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding(.leading, 22)
                }
            }
            .padding(10)
            .background(config.hasButton2 ? Color.accentColor.opacity(0.04) : Color.clear)
            .cornerRadius(8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 4: Interaction Actions
    
    private var interactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Click & Dismiss Triggers", systemImage: "cursorarrow.click.2")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            // Message Body Click Action
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $config.hasMessageAction) {
                    Text("Trigger Action on Notification Body Click (--messageaction)")
                        .font(.system(size: 12, weight: .medium))
                }
                .toggleStyle(.checkbox)
                
                if config.hasMessageAction {
                    TextField("Action URL, logout, or binary (e.g. https://support.apple.com)", text: $config.messageAction)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading, 20)
                }
            }
            
            // Dismiss Action (X button)
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $config.hasDismissAction) {
                    Text("Trigger Action on Explicit Dismiss (X) (--messagedismissaction)")
                        .font(.system(size: 12, weight: .medium))
                }
                .toggleStyle(.checkbox)
                
                if config.hasDismissAction {
                    TextField("Action executed when user closes with (X)", text: $config.dismissAction)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading, 20)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 5: Sound
    
    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notification Sound (--sound)", systemImage: "speaker.wave.3.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            HStack(spacing: 12) {
                Picker("Sound:", selection: $config.sound) {
                    ForEach(SoundOption.allCases) { sound in
                        Text(sound.displayName).tag(sound)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)
                
                Button {
                    config.sound.play()
                } label: {
                    Label("Test Audio", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if config.sound == .custom {
                TextField("Custom Sound Name (in /System/Library/Sounds/)", text: $config.customSoundName)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 6: Icon & Rebranding
    
    private var rebrandSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Icon & Branding (--rebrand)", systemImage: "paintpalette.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.accentColor)
            
            Toggle(isOn: $config.enableRebrand) {
                Text("Enable Custom App Icon Rebranding")
                    .font(.system(size: 12, weight: .medium))
            }
            .toggleStyle(.checkbox)
            
            if config.enableRebrand {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Preset Icon:", selection: $config.selectedIcon) {
                        ForEach(PresetIcon.allCases) { icon in
                            Label(icon.rawValue, systemImage: icon.systemSymbol).tag(icon)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if config.selectedIcon == .custom {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom Image / ICNS Path:")
                                .font(.system(size: 11))
                            TextField("/path/to/icon.icns or .png", text: $config.customRebrandPath)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        Text("Default Path: \(config.selectedIcon.defaultRebrandPath)")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Note: On production macOS clients, --rebrand modifies the app icon cache and requires root/MDM PPPC privilege.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 20)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
    
    // MARK: - Section 7: Advanced / Removal & Debug
    
    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showingAdvancedSettings) {
            VStack(alignment: .leading, spacing: 12) {
                // Removal Flag
                VStack(alignment: .leading, spacing: 6) {
                    Text("Removal Mode (--remove):")
                        .font(.system(size: 11.5, weight: .medium))
                    
                    Picker("", selection: $config.removeMode) {
                        ForEach(RemoveMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                
                // Verbose Logging Flag
                Toggle(isOn: $config.verbose) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Verbose Logging (--verbose)")
                            .font(.system(size: 12, weight: .medium))
                        Text("Outputs detailed diagnostic logs to NSLog / Console.app")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                
                // Binary Path
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifier Binary Path:")
                        .font(.system(size: 11, weight: .medium))
                    TextField("/Applications/Utilities/Notifier.app/Contents/MacOS/Notifier", text: $config.binaryPath)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Advanced Options (Removal, Verbose, Binary)", systemImage: "gearshape")
                .font(.system(size: 12.5, weight: .medium))
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
    }
}
