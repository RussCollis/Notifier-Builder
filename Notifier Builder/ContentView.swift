import SwiftUI

struct ContentView: View {
    @State private var configuration = NotifierConfiguration()
    @State private var colorSchemeOverride: ColorScheme? = nil
    @State private var selectedPresetCategory: String = "All"
    
    var body: some View {
        HSplitView {
            // Left Pane: Controls & Variable Options
            VStack(spacing: 0) {
                sidebarHeader
                Divider()
                NotifierFormView(config: $configuration)
            }
            .frame(minWidth: 380, idealWidth: 440, maxWidth: 520)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Right Pane: Live Preview & Code Generator
            VSplitView {
                // Top: Notification Center Preview Canvas
                NotificationPreviewCard(config: $configuration, previewColorFilter: $colorSchemeOverride)
                    .frame(minHeight: 340, idealHeight: 420)
                
                // Bottom: Code Inspector & CLI Parser
                CodeInspectorView(config: $configuration)
                    .frame(minHeight: 220, idealHeight: 260)
            }
        }
        .frame(minWidth: 880, minHeight: 650)
        .navigationTitle("Notifier Builder")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.waveform.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Notifier Builder")
                            .font(.system(size: 13, weight: .bold))
                        Text("Jamf Notifier Preview & Script Builder")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Presets Quick Menu
                Menu {
                    Text("Select a Template to Preview:")
                    Divider()
                    
                    ForEach(PresetLibrary.examples) { preset in
                        Button {
                            configuration = preset.config
                        } label: {
                            HStack {
                                Text(preset.title)
                                Text("(\(preset.category))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } label: {
                    Label("Templates", systemImage: "sparkles.rectangle.stack")
                }
                
                // Reset to Default button
                Button {
                    configuration = NotifierConfiguration()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .help("Reset all options to default")
            }
        }
    }
    
    private var sidebarHeader: some View {
        HStack {
            Label("Options & Variables", systemImage: "slider.horizontal.3")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("v4.0 Spec")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    ContentView()
}
